import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:swiftcomp/generated/l10n.dart';

/// Overlays a jump-to-latest action on the selected conversation's message list.
///
/// [child] must contain the vertical scrollable using [scrollController]. The
/// wrapper observes its metrics notifications, including changes from streaming
/// content and viewport resizing. It never scrolls automatically. The parent
/// positions the action above its composer using [bottomOffset], and marks the
/// conversation unavailable while loading, logged out, or starting a new chat.
class ChatLatestOverlay extends StatefulWidget {
  const ChatLatestOverlay({
    super.key,
    required this.child,
    required this.scrollController,
    required this.conversationId,
    required this.sessionToken,
    required this.isConversationLoaded,
    this.bottomOffset = 12,
  });

  final Widget child;
  final ScrollController scrollController;
  final String? conversationId;

  /// A stable token that changes on logout or account/session replacement.
  final Object sessionToken;
  final bool isConversationLoaded;
  final double bottomOffset;

  @override
  State<ChatLatestOverlay> createState() => _ChatLatestOverlayState();
}

class _ChatLatestOverlayState extends State<ChatLatestOverlay> {
  static const _minimumExtentAfter = 180.0;
  static const _maximumSettleFrames = 4;
  bool _visible = false;
  bool _refreshQueued = false;
  bool _routeCurrent = true;
  int _identityRevision = 0;
  int _jumpSequence = 0;
  ScrollPosition? _jumpPosition;
  double? _lastJumpPixels;
  bool _applyingJump = false;

  bool get _available =>
      widget.isConversationLoaded &&
      (widget.conversationId?.trim().isNotEmpty ?? false) &&
      _routeCurrent;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollChanged);
    _scheduleRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_routeCurrent) _cancelJump();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant ChatLatestOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScrollChanged);
      widget.scrollController.addListener(_onScrollChanged);
    }
    if (oldWidget.scrollController != widget.scrollController ||
        oldWidget.conversationId != widget.conversationId ||
        oldWidget.sessionToken != widget.sessionToken ||
        oldWidget.isConversationLoaded != widget.isConversationLoaded) {
      _identityRevision++;
      _refreshQueued = false;
      _visible = false;
      _cancelJump();
    }
    _scheduleRefresh();
  }

  @override
  void dispose() {
    _cancelJump();
    widget.scrollController.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _cancelJump() {
    _jumpSequence++;
    _jumpPosition = null;
    _lastJumpPixels = null;
  }

  void _onScrollChanged() {
    if (!_applyingJump && _jumpPosition != null) {
      final position = _position();
      // An intervening drag, wheel/scrollbar action or external scroll takes
      // precedence over a pending correction of the lazy list's end estimate.
      if (!identical(position, _jumpPosition) ||
          position!.pixels != _lastJumpPixels) {
        _cancelJump();
      }
    }
    _scheduleRefresh();
  }

  ScrollPosition? _position() {
    // Reading controller.position asserts when there are zero or multiple
    // positions. A controller in transition must not expose a usable action.
    final positions = widget.scrollController.positions;
    if (positions.length != 1) return null;
    final position = positions.single;
    if (!position.hasPixels ||
        !position.hasContentDimensions ||
        position.axis != Axis.vertical ||
        !position.pixels.isFinite ||
        !position.maxScrollExtent.isFinite ||
        !position.minScrollExtent.isFinite ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return null;
    }
    return position;
  }

  void _scheduleRefresh() {
    if (!mounted || _refreshQueued) return;
    _refreshQueued = true;
    final revision = _identityRevision;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || revision != _identityRevision) return;
      _refreshQueued = false;
      final position = _available ? _position() : null;
      final visible = position != null &&
          position.extentAfter.isFinite &&
          position.extentAfter >= _minimumExtentAfter;
      if (visible != _visible) setState(() => _visible = visible);
    });
    // Scroll and metrics listeners may fire during layout. Refresh after the
    // frame rather than calling setState from either listener directly.
    binding.ensureVisualUpdate();
  }

  void _jumpToLatest(int revision) {
    if (!mounted ||
        revision != _identityRevision ||
        !_available ||
        ModalRoute.isCurrentOf(context) == false) {
      return;
    }
    final position = _position();
    if (position == null) {
      _scheduleRefresh();
      return;
    }
    _cancelJump();
    final sequence = _jumpSequence;
    _jumpPosition = position;
    _applyJump(position);
    _settleJump(revision, sequence, position, _maximumSettleFrames);
    _scheduleRefresh();
  }

  void _applyJump(ScrollPosition position) {
    _lastJumpPixels = position.maxScrollExtent;
    _applyingJump = true;
    try {
      // Synchronous jumps also respect reduced motion. Lazy lists may refine
      // their estimated maximum after reaching the previous estimated end.
      position.jumpTo(_lastJumpPixels!);
    } finally {
      _applyingJump = false;
    }
  }

  void _settleJump(int revision, int sequence, ScrollPosition position,
      int remainingFrames) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _identityRevision ||
          sequence != _jumpSequence) {
        return;
      }
      if (!_available ||
          ModalRoute.isCurrentOf(context) == false ||
          !identical(_position(), position) ||
          position.pixels != _lastJumpPixels) {
        _cancelJump();
        return;
      }
      if (position.extentAfter <= 0.5 || remainingFrames == 0) {
        _cancelJump();
        return;
      }
      _applyJump(position);
      _scheduleRefresh();
      _settleJump(revision, sequence, position, remainingFrames - 1);
    });
    binding.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final revision = _identityRevision;
    final label = S.maybeOf(context)?.Chat_jump_to_latest ?? 'Jump to latest';
    final bottom = widget.bottomOffset.isFinite && widget.bottomOffset >= 0
        ? widget.bottomOffset
        : 12.0;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification.metrics.axis == Axis.vertical) {
          _scheduleRefresh();
        }
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical &&
              ((notification is ScrollStartNotification &&
                      notification.dragDetails != null) ||
                  (notification is UserScrollNotification &&
                      notification.direction != ScrollDirection.idle))) {
            _cancelJump();
          }
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_available && _visible)
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom,
                child: Align(
                  alignment: Alignment.center,
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('chat-jump-to-latest'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _jumpToLatest(revision),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                    label: Text(label, textAlign: TextAlign.center),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
