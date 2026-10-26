import 'dart:async';

import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

/// Reuses only a question's text; the existing history and attachments stay put.
class ChatUseAsDraftButton extends StatefulWidget {
  const ChatUseAsDraftButton({
    super.key,
    required this.viewModel,
    required this.message,
    this.onBeforeUse,
    this.onApplied,
    this.menuItem = false,
  });

  final ChatViewModel viewModel;
  final Message message;
  final VoidCallback? onBeforeUse;
  final VoidCallback? onApplied;
  final bool menuItem;

  @override
  State<ChatUseAsDraftButton> createState() => _ChatUseAsDraftButtonState();
}

class _ChatUseAsDraftButtonState extends State<ChatUseAsDraftButton> {
  DialogRoute<bool>? _route;
  NavigatorState? _navigator;
  ChatDraftReuseRequest? _request;
  TextEditingController? _composer;
  ChatViewModel? _observedModel;
  bool _closing = false;

  @override
  void didUpdateWidget(covariant ChatUseAsDraftButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel ||
        !identical(oldWidget.message, widget.message)) {
      _dismiss();
    }
  }

  void _stopObserving() {
    _composer?.removeListener(_checkCurrent);
    _composer = null;
    _observedModel?.removeListener(_checkCurrent);
    _observedModel?.disposalListenable.removeListener(_checkCurrent);
    _observedModel = null;
  }

  bool get _current {
    final request = _request;
    return mounted &&
        !_closing &&
        request != null &&
        widget.viewModel.isDraftReuseCurrent(request);
  }

  void _checkCurrent() {
    if (!_current) _dismiss();
  }

  void _dismiss() {
    final route = _route;
    if (route == null || _closing) return;
    _closing = true;
    _stopObserving();
    final navigator = _navigator;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator != null && navigator.mounted && route.isActive) {
        navigator.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _use() async {
    if (!mounted ||
        _route != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    widget.onBeforeUse?.call();
    if (!mounted) return;
    final model = widget.viewModel;
    final request = model.prepareMessageAsDraft(widget.message);
    if (request == null) return;
    if (!request.replacesDraft) {
      if (model.applyMessageAsDraft(request) && mounted) {
        widget.onApplied?.call();
      }
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    late final DialogRoute<bool> route;
    route = DialogRoute<bool>(
      context: context,
      builder: (dialogContext) {
        final strings = S.maybeOf(dialogContext);
        return AlertDialog(
          key: const ValueKey('chat-replace-draft-dialog'),
          scrollable: true,
          title: Text(strings?.Chat_replace_draft_title ?? 'Replace draft?'),
          content: Text(strings?.Chat_replace_draft_message ??
              'Replace your unsent text with this question?'),
          actions: [
            TextButton(
              key: const ValueKey('chat-replace-draft-cancel'),
              onPressed: () {
                if (_route == route && route.isCurrent) navigator.pop(false);
              },
              child: Text(strings?.Chat_cancel ?? 'Cancel'),
            ),
            FilledButton(
              key: const ValueKey('chat-replace-draft-confirm'),
              onPressed: () {
                if (_route == route && route.isCurrent && _current) {
                  navigator.pop(true);
                }
              },
              child: Text(strings?.Chat_replace_draft ?? 'Replace draft'),
            ),
          ],
        );
      },
    );
    _request = request;
    _route = route;
    _navigator = navigator;
    _observedModel = model;
    _composer = model.composerTextController;
    model.addListener(_checkCurrent);
    model.disposalListenable.addListener(_checkCurrent);
    _composer!.addListener(_checkCurrent);
    try {
      final confirmed = await navigator.push(route);
      if (confirmed == true &&
          mounted &&
          _current &&
          ModalRoute.of(context)?.isCurrent == true) {
        // Detach first: applying the new text intentionally invalidates its ticket.
        _stopObserving();
        if (model.applyMessageAsDraft(request) && mounted) {
          widget.onApplied?.call();
        }
      }
    } finally {
      _stopObserving();
      if (_route == route) {
        _route = null;
        _navigator = null;
        _request = null;
        _closing = false;
      }
    }
  }

  @override
  void dispose() {
    _dismiss();
    _stopObserving();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = S.maybeOf(context)?.Chat_use_as_draft ?? 'Use as draft';
    final onPressed = widget.viewModel.canUseMessageAsDraft(widget.message)
        ? () => unawaited(_use())
        : null;
    if (widget.menuItem) {
      return MenuItemButton(
        key: ValueKey('chat-use-as-draft-${widget.message.id}'),
        closeOnActivate: false,
        onPressed: onPressed,
        leadingIcon: const Icon(Icons.edit_note_rounded, size: 18),
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        ),
        child: Text(label),
      );
    }
    return IconButton(
      key: ValueKey('chat-use-as-draft-${widget.message.id}'),
      tooltip: label,
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      onPressed: onPressed,
    );
  }
}
