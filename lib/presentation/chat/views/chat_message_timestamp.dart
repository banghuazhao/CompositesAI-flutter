import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

/// Displays the message model's epoch milliseconds in the device's local time.
///
/// It never infers another timestamp unit or substitutes the current time.
class ChatMessageTimestamp extends StatelessWidget {
  const ChatMessageTimestamp({super.key, required this.timestamp});

  final int? timestamp;

  static DateTime? _localDate(int? milliseconds) {
    // Match JavaScript Date's range even when running on the Dart VM.
    const maximumMilliseconds = 8640000000000000;
    if (milliseconds == null ||
        milliseconds <= 0 ||
        milliseconds > maximumMilliseconds) {
      return null;
    }
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
      // Keep dates within the ordinary, unsigned calendar-year display range.
      if (date.year < 1 || date.year > 9999) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _localDate(timestamp);
    final material = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    if (date == null || material == null) return const SizedBox.shrink();

    final String time;
    final String detail;
    try {
      time = material.formatTimeOfDay(
        TimeOfDay.fromDateTime(date),
        alwaysUse24HourFormat:
            MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
      );
      final dateTime = '${material.formatFullDate(date)}, $time';
      detail = S.maybeOf(context)?.Chat_message_time(dateTime) ??
          'Message time: $dateTime';
    } catch (_) {
      // A malformed history value or unsupported localized date must not
      // prevent the message itself from rendering.
      return const SizedBox.shrink();
    }

    return Semantics(
      label: detail,
      excludeSemantics: true,
      child: Tooltip(
        message: detail,
        excludeFromSemantics: true,
        triggerMode: TooltipTriggerMode.tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}
