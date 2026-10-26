import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../viewModels/chat_view_model.dart';

typedef ChatClearDraftBuilder = Widget Function(
    BuildContext context, VoidCallback? onClear, Widget? undoNotice);

/// Clears only text, with one short-lived inline Undo owned by this route/VM.
class ChatClearDraftButton extends StatefulWidget {
  const ChatClearDraftButton({
    super.key,
    required this.viewModel,
    this.onBeforeClear,
    this.onDraftChanged,
    this.isAvailable,
    this.builder,
  });

  final ChatViewModel viewModel;
  final VoidCallback? onBeforeClear;
  final VoidCallback? onDraftChanged;
  final bool Function()? isAvailable;
  final ChatClearDraftBuilder? builder;

  @override
  State<ChatClearDraftButton> createState() => _ChatClearDraftButtonState();
}

class _ChatClearDraftButtonState extends State<ChatClearDraftButton> {
  TextEditingController? _composer;
  _UndoNotice? _notice;
  Timer? _expiry;
  bool _refreshPending = false;
  bool _persistent = false;

  Object _scope(ChatViewModel model) =>
      (model, model.chatSessionKey, model.chatSelectionRevision);

  bool get _available => widget.isAvailable?.call() ?? true;

  @override
  void initState() {
    super.initState();
    _observe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final persistent =
        MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
    if (_persistent != persistent) {
      _persistent = persistent;
      _startExpiry();
    }
  }

  void _observe() {
    final model = widget.viewModel;
    if (model.isDisposed) return;
    _composer = model.composerTextController;
    _composer!.addListener(_changed);
    model.addListener(_changed);
    model.disposalListenable.addListener(_changed);
  }

  void _detach(ChatViewModel model) {
    _composer?.removeListener(_changed);
    _composer = null;
    model.removeListener(_changed);
    model.disposalListenable.removeListener(_changed);
  }

  @override
  void didUpdateWidget(covariant ChatClearDraftButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _retire();
      _detach(oldWidget.viewModel);
      _observe();
    }
  }

  void _refresh() {
    if (_refreshPending) return;
    _refreshPending = true;
    // Changes can originate in an owner's build or in VM disposal.
    scheduleMicrotask(() {
      _refreshPending = false;
      if (mounted) setState(() {});
    });
  }

  void _changed() {
    final notice = _notice;
    if (notice != null &&
        (!_available || !notice.model.isDraftClearUndoCurrent(notice.undo))) {
      _retire();
    }
    _refresh();
  }

  void _retire() {
    _expiry?.cancel();
    _expiry = null;
    final notice = _notice;
    if (notice == null) return;
    _notice = null;
    notice.model.discardDraftClearUndo(notice.undo);
    _refresh();
  }

  void _startExpiry() {
    _expiry?.cancel();
    _expiry = null;
    if (_notice != null && !_persistent) {
      _expiry = Timer(const Duration(seconds: 6), _retire);
    }
  }

  bool _current(_UndoNotice notice) =>
      mounted &&
      identical(_notice, notice) &&
      _available &&
      _scope(widget.viewModel) == notice.scope &&
      ModalRoute.of(context)?.isCurrent == true &&
      notice.model.isDraftClearUndoCurrent(notice.undo);

  void _checkRouteAfterFrame(_UndoNotice notice) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_notice, notice)) return;
      if (!_current(notice)) {
        _retire();
      } else {
        // Observe existing frames without creating idle frames or animation.
        _checkRouteAfterFrame(notice);
      }
    });
  }

  void _clear(Object scope) {
    final model = widget.viewModel;
    if (!mounted ||
        !_available ||
        _scope(model) != scope ||
        ModalRoute.of(context)?.isCurrent != true ||
        !model.canClearComposerDraft) {
      return;
    }
    widget.onBeforeClear?.call();
    if (!mounted ||
        !_available ||
        _scope(widget.viewModel) != scope ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final undo = model.clearComposerDraft();
    if (undo == null) return;
    _retire();
    final notice = _UndoNotice(model, undo, scope);
    _notice = notice;
    _startExpiry();
    _checkRouteAfterFrame(notice);
    _refresh();
    if (mounted) widget.onDraftChanged?.call();
  }

  void _undo(_UndoNotice notice) {
    if (!_current(notice)) return;
    if (notice.model.undoClearComposerDraft(notice.undo)) {
      _retire();
      if (mounted) widget.onDraftChanged?.call();
    }
  }

  Widget _noticeWidget(_UndoNotice notice) {
    final strings = S.maybeOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: const Key('chat-draft-clear-notice'),
      container: true,
      liveRegion: true,
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(strings?.Chat_draft_cleared ?? 'Draft cleared.',
                  style: TextStyle(color: scheme.onSecondaryContainer)),
              TextButton(
                key: const Key('chat-undo-clear-draft'),
                onPressed: () => _undo(notice),
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: scheme.onSecondaryContainer),
                child: Text(strings?.Chat_undo ?? 'Undo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _retire();
    _detach(widget.viewModel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The disposal notifier can rebuild this wrapper before its parent rebuilds.
    // Never invoke a composer builder with a controller the VM already disposed.
    if (widget.viewModel.isDisposed) return const SizedBox.shrink();
    final scope = _scope(widget.viewModel);
    final onClear = _available && widget.viewModel.canClearComposerDraft
        ? () => _clear(scope)
        : null;
    final notice = _notice;
    final undoNotice =
        notice != null && _current(notice) ? _noticeWidget(notice) : null;
    if (widget.builder != null) {
      return widget.builder!(context, onClear, undoNotice);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const Key('chat-clear-draft'),
          tooltip: S.maybeOf(context)?.Chat_clear_draft ?? 'Clear draft',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: onClear,
          icon: const Icon(Icons.clear_rounded),
        ),
        if (undoNotice != null) undoNotice,
      ],
    );
  }
}

class _UndoNotice {
  _UndoNotice(this.model, this.undo, this.scope);

  final ChatViewModel model;
  final ChatDraftClearUndo undo;
  final Object scope;
}
