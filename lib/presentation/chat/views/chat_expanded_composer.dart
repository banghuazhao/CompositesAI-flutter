import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';
import 'chat_clear_draft_button.dart';
import 'chat_composer_more_menu.dart';
import 'chat_reading_style.dart';

final _expandedComposers = Expando<_ExpandedComposerLifetime>();

/// Edits the current in-memory draft directly, without sending or copying it.
///
/// The caller manages the inline editor's focus and voice-input availability.
Future<void> showExpandedChatComposer(
  BuildContext context,
  ChatViewModel viewModel,
) async {
  final existing = _expandedComposers[viewModel];
  if (existing != null) {
    await existing.closed.future;
    return;
  }
  if (!context.mounted ||
      viewModel.isDisposed ||
      !viewModel.isLoggedIn ||
      ModalRoute.of(context)?.isCurrent != true) {
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final lifetime = _ExpandedComposerLifetime(
    context,
    viewModel,
    navigator,
    viewModel.composerTextController,
  );
  // Reserve synchronously so direct, rapid calls cannot create two editors.
  _expandedComposers[viewModel] = lifetime;
  final route = DialogRoute<void>(
    context: context,
    builder: (_) => _ExpandedComposer(lifetime: lifetime),
  );
  lifetime.start(route);
  try {
    await navigator.push(route);
    lifetime.retire();
    // Keep duplicate-open ownership until the route has unmounted its editor.
    await route.completed;
  } finally {
    lifetime.dispose();
    if (identical(_expandedComposers[viewModel], lifetime)) {
      _expandedComposers[viewModel] = null;
    }
    lifetime.closed.complete();
  }
}

class _ExpandedComposerLifetime extends ChangeNotifier {
  _ExpandedComposerLifetime(
    this.ownerContext,
    this.viewModel,
    this.navigator,
    this.controller,
  )   : _session = viewModel.chatSessionKey,
        _chatId = viewModel.selectedChat?.id,
        _selection = viewModel.chatSelectionRevision,
        _ownerRoute = ModalRoute.of(ownerContext);

  final BuildContext ownerContext;
  final ChatViewModel viewModel;
  final NavigatorState navigator;
  final TextEditingController controller;
  final Object _session;
  final String? _chatId;
  final int _selection;
  final ModalRoute<dynamic>? _ownerRoute;
  final closed = Completer<void>();
  late final DialogRoute<void> route;
  bool _active = true;
  bool _closing = false;
  bool _observing = false;

  bool get available =>
      _active &&
      !_closing &&
      ownerContext.mounted &&
      _ownerRoute?.isActive == true &&
      !viewModel.isDisposed &&
      viewModel.isLoggedIn &&
      viewModel.chatSessionKey == _session &&
      viewModel.selectedChat?.id == _chatId &&
      viewModel.chatSelectionRevision == _selection;

  void start(DialogRoute<void> value) {
    route = value;
    _observing = true;
    viewModel.addListener(_checkCurrent);
    viewModel.disposalListenable.addListener(_checkCurrent);
    // Selection may restore another draft before the general VM notification.
    controller.addListener(_checkCurrent);
    _checkOwnerAfterFrame();
  }

  void _stopObserving() {
    if (!_observing) return;
    _observing = false;
    viewModel.removeListener(_checkCurrent);
    viewModel.disposalListenable.removeListener(_checkCurrent);
    controller.removeListener(_checkCurrent);
  }

  void _checkCurrent() {
    if (!available) close();
  }

  void _checkOwnerAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active || _closing) return;
      if (!available) {
        close();
      } else {
        // Observe existing frames without creating idle animation or timers.
        _checkOwnerAfterFrame();
      }
    });
  }

  void retire() {
    if (!_active || _closing) return;
    _closing = true;
    _stopObserving();
    notifyListeners();
  }

  void close() {
    if (!_active || _closing) return;
    retire();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void done() {
    if (!available) {
      close();
      return;
    }
    if (!route.isCurrent) return;
    retire();
    navigator.pop();
  }

  @override
  void dispose() {
    _active = false;
    _stopObserving();
    super.dispose();
  }
}

class _ExpandedComposer extends StatefulWidget {
  const _ExpandedComposer({required this.lifetime});

  final _ExpandedComposerLifetime lifetime;

  @override
  State<_ExpandedComposer> createState() => _ExpandedComposerState();
}

class _ExpandedComposerState extends State<_ExpandedComposer> {
  final _focus = FocusNode();
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    widget.lifetime.addListener(_onScopeChanged);
  }

  void _onScopeChanged() {
    if (!widget.lifetime.available) _focus.unfocus();
    if (_refreshPending) return;
    _refreshPending = true;
    // Session changes may originate in the owner's build or disposal.
    scheduleMicrotask(() {
      _refreshPending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.lifetime.removeListener(_onScopeChanged);
    _focus.dispose();
    // The VM owns the shared text controller, including after this route closes.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifetime = widget.lifetime;
    if (!lifetime.available) return const SizedBox.shrink();
    final strings = S.maybeOf(context);
    return Dialog.fullscreen(
      key: const Key('chat-expanded-composer-dialog'),
      child: ScaffoldMessenger(
        child: ChatClearDraftButton(
          viewModel: lifetime.viewModel,
          isAvailable: () => lifetime.available && lifetime.route.isCurrent,
          onDraftChanged: () {
            if (mounted && lifetime.available && lifetime.route.isCurrent) {
              _focus.requestFocus();
            }
          },
          builder: (context, onClear, undoNotice) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                strings?.Chat_expanded_composer ?? 'Edit question',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                ChatComposerMoreMenu(onClear: onClear),
                TextButton(
                  key: const Key('chat-expanded-composer-done'),
                  onPressed: lifetime.done,
                  child: Text(strings?.Chat_composer_done ?? 'Done'),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (undoNotice != null) ...[
                      undoNotice,
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: TextField(
                        key: const Key('chat-expanded-composer'),
                        style: ChatReadingStyle.body(context),
                        controller: lifetime.controller,
                        focusNode: _focus,
                        autofocus: true,
                        selectAllOnFocus: false,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) =>
                                lifetime.available ? newValue : oldValue,
                          ),
                        ],
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: strings?.Chat_composer_hint ??
                              'Ask about composites engineering…',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
