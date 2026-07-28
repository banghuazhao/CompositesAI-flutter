import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:flutter/material.dart';

/// Web-style response activity: "Thinking…" + latest tool/knowledge status.
class ChatResponseActivity extends StatelessWidget {
  const ChatResponseActivity({
    super.key,
    required this.message,
    required this.isStreaming,
  });

  final Message message;
  final bool isStreaming;

  bool get _thinkingDone =>
      message.isDone || message.content.trim().isNotEmpty;

  ToolStatus? get _latestVisibleStatus {
    for (var i = message.statusHistory.length - 1; i >= 0; i--) {
      final status = message.statusHistory[i];
      if (!status.hidden && chatToolStatusDescription(status).isNotEmpty) {
        return status;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latestVisibleStatus;
    final interrupted = latest?.action == 'response_interrupted';
    final statusActive = latest != null && latest.done == false;
    final showThinking =
        isStreaming && !_thinkingDone && !interrupted && !statusActive;
    // Keep the latest tool/knowledge line while it's active or just finished
    // before tokens arrive; hide stale status once the answer is on screen.
    final showStatus = latest != null &&
        (interrupted ||
            (isStreaming && !_thinkingDone) ||
            (latest.done == false));

    if (!showThinking && !showStatus) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      liveRegion: isStreaming,
      label: [
        if (showThinking) 'Thinking',
        if (showStatus) chatToolStatusDescription(latest!),
      ].join('. '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showThinking)
            const _StatusLine(
              text: 'Thinking…',
              isActive: true,
              isError: false,
            ),
          if (showStatus)
            _StatusLine(
              text: chatToolStatusDescription(latest!),
              isActive: isStreaming && latest.done == false,
              isError: interrupted,
            ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.isActive,
    required this.isError,
  });

  final String text;
  final bool isActive;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isActive) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: isActive
                ? _ShimmerText(
                    text: text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          height: 1.35,
                        ),
                  )
                : Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          height: 1.35,
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerText extends StatefulWidget {
  const _ShimmerText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style?.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final highlight = Color.lerp(base, Colors.white, 0.55) ?? base;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 - t * 2, 0),
              end: Alignment(1.0 + t * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: widget.style?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Legacy expandable activity card kept for tests and interrupted responses.
class ChatProgressIndicator extends StatefulWidget {
  const ChatProgressIndicator({
    super.key,
    required this.statuses,
    required this.isStreaming,
  });

  final List<ToolStatus> statuses;
  final bool isStreaming;

  @override
  State<ChatProgressIndicator> createState() => _ChatProgressIndicatorState();
}

class _ChatProgressIndicatorState extends State<ChatProgressIndicator> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activities = widget.statuses
        .where((status) => !status.hidden)
        .map(
          (status) => _ChatActivity(
            status: status,
            description: chatToolStatusDescription(status),
          ),
        )
        .where((activity) => activity.description.isNotEmpty)
        .toList(growable: false);
    if (activities.isEmpty) return const SizedBox.shrink();

    final latest = activities.last;
    final interrupted = latest.status.action == 'response_interrupted';
    final canExpand = activities.length > 1;
    final scheme = Theme.of(context).colorScheme;
    final heading = interrupted
        ? 'Response interrupted'
        : widget.isStreaming
            ? 'Working'
            : 'Activity complete';

    return Semantics(
      container: true,
      liveRegion: widget.isStreaming,
      label: '$heading. ${latest.description}',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: canExpand
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                child: Row(
                  children: [
                    _StatusIcon(
                      isRunning: widget.isStreaming && !interrupted,
                      isInterrupted: interrupted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: interrupted
                                      ? scheme.error
                                      : scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            latest.description,
                            maxLines: _expanded ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: interrupted
                                          ? scheme.error
                                          : scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (canExpand)
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _ActivityHistory(activities: activities),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHistory extends StatelessWidget {
  const _ActivityHistory({required this.activities});

  final List<_ChatActivity> activities;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < activities.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == activities.length - 1 ? 0 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      activities[index].status.done == true
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_checked_rounded,
                      size: 14,
                      color: activities[index].status.done == true
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activities[index].description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.isRunning,
    required this.isInterrupted,
  });

  final bool isRunning;
  final bool isInterrupted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isRunning) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      isInterrupted
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded,
      size: 18,
      color: isInterrupted ? scheme.error : scheme.primary,
    );
  }
}

class _ChatActivity {
  const _ChatActivity({
    required this.status,
    required this.description,
  });

  final ToolStatus status;
  final String description;
}

String chatToolStatusDescription(ToolStatus status) {
  if (status.action == 'knowledge_search') {
    if (status.query.isNotEmpty) {
      return 'Searching Knowledge for “${status.query}”';
    }
    return 'Searching Knowledge…';
  }

  if (status.action == 'web_search') {
    var description = status.description.trim();
    if (description.contains('{{count}}')) {
      return description.replaceAll('{{count}}', '${status.urls.length}');
    }
    if (description == 'Generating search query') {
      return 'Generating search query';
    }
    if (description == 'No search query generated') {
      return 'No search query generated';
    }
    if (description.isNotEmpty) return description;
    if (status.query.isNotEmpty) return 'Searching “${status.query}”';
    return 'Searching the web…';
  }

  if (status.action == 'response_interrupted') {
    return 'Response interrupted';
  }

  var description = status.description.trim();
  if (description.contains('{{searchQuery}}')) {
    description = description.replaceAll('{{searchQuery}}', status.query);
  }
  if (description.contains('{{count}}')) {
    description = description.replaceAll('{{count}}', '${status.urls.length}');
  }
  if (description.isNotEmpty) return description;
  if (status.query.isNotEmpty) return 'Searching for “${status.query}”';
  if (status.action.isNotEmpty) {
    final words = status.action.replaceAll('_', ' ').trim();
    if (words.isEmpty) return '';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
  return '';
}
