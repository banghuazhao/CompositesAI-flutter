import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:flutter/material.dart';

/// Presents service-provided activity without exposing model chain-of-thought.
///
/// The compact header keeps the conversation calm while the expandable history
/// gives users enough detail to understand long-running searches and tools.
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
    final semanticLabel = '$heading. ${latest.description}';

    return Semantics(
      container: true,
      liveRegion: widget.isStreaming,
      label: semanticLabel,
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

class ChatThinkingIndicator extends StatelessWidget {
  const ChatThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Analyzing your request',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Analyzing your request…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
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
  if (status.action == 'knowledge_search' && status.query.isNotEmpty) {
    return 'Searching knowledge for “${status.query}”';
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
