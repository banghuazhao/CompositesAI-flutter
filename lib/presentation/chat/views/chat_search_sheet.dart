import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../model/chat_message_search.dart';
import '../viewModels/chat_view_model.dart';

/// Finds text in the loaded conversation. This never fetches or sends messages.
Future<void> showChatSearchSheet(
  BuildContext context,
  ChatViewModel viewModel,
) async {
  if (!context.mounted ||
      viewModel.isDisposed ||
      !viewModel.isLoggedIn ||
      viewModel.isLoadingMessages ||
      viewModel.selectedChat == null ||
      ModalRoute.of(context)?.isCurrent != true) {
    return;
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final lifetime = _SearchLifetime(context, viewModel, navigator);
  final route = ModalBottomSheetRoute<void>(
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    builder: (_) => _ChatSearchSheet(lifetime: lifetime),
  );
  lifetime.start(route);
  try {
    await navigator.push(route);
  } finally {
    lifetime.dispose();
  }
}

class _SearchLifetime extends ChangeNotifier {
  _SearchLifetime(this.ownerContext, this.viewModel, this.navigator)
      : _session = viewModel.chatSessionKey,
        _chatId = viewModel.selectedChat?.id;

  final BuildContext ownerContext;
  final ChatViewModel viewModel;
  final NavigatorState navigator;
  final Object _session;
  final String? _chatId;
  late final ModalBottomSheetRoute<void> route;
  bool _active = true;
  bool _closing = false;

  bool get available =>
      _active &&
      !_closing &&
      ownerContext.mounted &&
      !viewModel.isDisposed &&
      viewModel.isLoggedIn &&
      !viewModel.isLoadingMessages &&
      viewModel.chatSessionKey == _session &&
      viewModel.selectedChat?.id == _chatId;

  bool get canCopy => available && route.isCurrent;

  void start(ModalBottomSheetRoute<void> value) {
    route = value;
    viewModel.addListener(_onChange);
    viewModel.disposalListenable.addListener(_onChange);
    _checkOwnerAfterFrame();
  }

  void _onChange() {
    if (!available) {
      close();
    } else {
      notifyListeners();
    }
  }

  void _checkOwnerAfterFrame() {
    // Observe rendered frames without requesting idle frames or a timer. This
    // also catches removal of the caller while another route covers the sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active || _closing) return;
      if (!available) {
        close();
      } else {
        _checkOwnerAfterFrame();
      }
    });
  }

  void close() {
    if (!_active || _closing) return;
    _closing = true;
    notifyListeners();
    // Session notifications and owner disposal may happen during a build.
    // Remove only this sheet, including when another route is above it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _active = false;
    viewModel.removeListener(_onChange);
    viewModel.disposalListenable.removeListener(_onChange);
    super.dispose();
  }
}

class _ChatSearchSheet extends StatefulWidget {
  const _ChatSearchSheet({required this.lifetime});

  final _SearchLifetime lifetime;

  @override
  State<_ChatSearchSheet> createState() => _ChatSearchSheetState();
}

class _ChatSearchSheetState extends State<_ChatSearchSheet> {
  final _query = TextEditingController();
  List<ChatMessageSearchMatch> _matches = const [];
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(_refresh);
    widget.lifetime.addListener(_onConversationChanged);
  }

  void _onConversationChanged() {
    if (!widget.lifetime.available) _matches = const [];
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_refreshScheduled) return;
      _refreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshScheduled = false;
        if (mounted) _refresh();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _matches = widget.lifetime.available
          ? ChatMessageSearch.find(
              widget.lifetime.viewModel.messages, _query.text)
          : const [];
    });
  }

  Future<void> _copy(ChatMessageSearchMatch match) async {
    final lifetime = widget.lifetime;
    if (!mounted || !lifetime.canCopy || !_matches.contains(match)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = S.maybeOf(context);
    try {
      await Clipboard.setData(ClipboardData(text: match.excerpt));
      if (!mounted || !lifetime.canCopy) return;
      messenger?.showSnackBar(SnackBar(
        content: Text(strings?.Chat_search_excerpt_copied ?? 'Excerpt copied'),
      ));
    } catch (_) {
      if (!mounted || !lifetime.canCopy) return;
      messenger?.showSnackBar(SnackBar(
        content: Text(
            strings?.Chat_search_copy_failed ?? 'Could not copy this excerpt.'),
      ));
    }
  }

  @override
  void dispose() {
    widget.lifetime.removeListener(_onConversationChanged);
    _matches = const [];
    _query.removeListener(_refresh);
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.lifetime.available) return const SizedBox.shrink();
    final strings = S.maybeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = _query.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: CustomScrollView(
          key: const Key('chat-search-results'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings?.Chat_find_in_chat ?? 'Find in chat',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          key: const Key('chat-search-close'),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: widget.lifetime.close,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('chat-search-field'),
                      controller: _query,
                      decoration: InputDecoration(
                        labelText: strings?.Chat_search_loaded_messages ??
                            'Search loaded messages',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: strings?.Chat_search_clear ??
                                    'Clear search',
                                onPressed: _query.clear,
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                    if (hasQuery) ...[
                      const SizedBox(height: 12),
                      Text(strings?.Chat_search_match_count(_matches.length) ??
                          '${_matches.length} matching messages'),
                    ],
                  ],
                ),
              ),
            ),
            if (_matches.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    hasQuery
                        ? strings?.Chat_search_no_matches ??
                            'No matching messages.'
                        : strings?.Chat_search_empty ??
                            'Enter text to search this conversation.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                sliver: SliverList.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    if (!widget.lifetime.available) {
                      return const SizedBox.shrink();
                    }
                    final match = _matches[index];
                    return Card(
                      key: ValueKey('chat-search-result-${match.messageIndex}'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    match.role == 'user'
                                        ? strings?.Chat_search_you ?? 'You'
                                        : strings?.Chat_search_assistant ??
                                            'Assistant',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey(
                                      'chat-search-copy-${match.messageIndex}'),
                                  tooltip: strings?.Chat_search_copy_excerpt ??
                                      'Copy excerpt',
                                  onPressed: () => _copy(match),
                                  icon: const Icon(Icons.copy, size: 20),
                                ),
                              ],
                            ),
                            Text(match.excerpt,
                                maxLines: 8, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
