import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

/// Shows only draft presence; no private draft text is rendered in history.
class ChatDraftBadge extends StatefulWidget {
  const ChatDraftBadge({
    super.key,
    required this.viewModel,
    required this.chatId,
  });

  final ChatViewModel viewModel;
  final String chatId;

  @override
  State<ChatDraftBadge> createState() => _ChatDraftBadgeState();
}

class _ChatDraftBadgeState extends State<ChatDraftBadge> {
  bool _refreshPending = false;

  void _listen(ChatViewModel model) {
    if (model.isDisposed) return;
    model.draftChanges.addListener(_refresh);
    model.disposalListenable.addListener(_refresh);
  }

  void _unlisten(ChatViewModel model) {
    model.draftChanges.removeListener(_refresh);
    model.disposalListenable.removeListener(_refresh);
  }

  void _refresh() {
    if (_refreshPending) return;
    _refreshPending = true;
    scheduleMicrotask(() {
      _refreshPending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _listen(widget.viewModel);
  }

  @override
  void didUpdateWidget(covariant ChatDraftBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _unlisten(oldWidget.viewModel);
      _listen(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _unlisten(widget.viewModel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.viewModel.hasDraft(widget.chatId)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: ValueKey('chat-draft-badge-${widget.chatId}'),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          S.maybeOf(context)?.Chat_draft ?? 'Draft',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
