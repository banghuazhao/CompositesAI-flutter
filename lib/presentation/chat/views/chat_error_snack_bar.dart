import 'package:flutter/material.dart';

import '../model/chat_error.dart';

SnackBar buildChatErrorSnackBar({
  required BuildContext context,
  required ChatErrorNotice notice,
  VoidCallback? onRetry,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isWarning = notice.severity == ChatErrorSeverity.warning;
  final backgroundColor =
      isWarning ? scheme.tertiaryContainer : scheme.errorContainer;
  final foregroundColor =
      isWarning ? scheme.onTertiaryContainer : scheme.onErrorContainer;

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: notice.canRetry ? 8 : 6),
    backgroundColor: backgroundColor,
    showCloseIcon: !notice.canRetry,
    closeIconColor: foregroundColor,
    content: Semantics(
      container: true,
      liveRegion: true,
      label: '${notice.title}. ${notice.message}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.info_outline_rounded
                : Icons.error_outline_rounded,
            color: foregroundColor,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  notice.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    action: notice.canRetry && onRetry != null
        ? SnackBarAction(
            label: 'Retry',
            textColor: foregroundColor,
            onPressed: onRetry,
          )
        : null,
  );
}
