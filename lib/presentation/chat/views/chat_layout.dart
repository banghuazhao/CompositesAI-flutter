import 'dart:math' as math;

/// Shared measure for the conversation, welcome screen and composer.
class ChatLayout {
  const ChatLayout._();

  static const double maximumContentWidth = 800;
  static const double gutter = 20;

  static double contentWidthFor(double width) =>
      math.min(maximumContentWidth, math.max(0, width - gutter * 2));

  static double horizontalPaddingFor(double width) =>
      math.max(0, (width - contentWidthFor(width)) / 2);
}
