import 'package:flutter/material.dart';

/// Shared reading and metadata styles for the conversation and its composer.
abstract final class ChatReadingStyle {
  static const double iconSize = 18;
  static const double messageRadius = 16;
  static const double codeRadius = 12;

  static TextStyle body(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: color ?? theme.colorScheme.onSurface,
      fontSize: 16,
      height: 1.55,
      letterSpacing: 0,
    );
  }

  static TextStyle metadata(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: color ?? theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle code(BuildContext context) => body(context).copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.5,
      );

  static Color codeSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color codeHeader(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color codeBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;
}
