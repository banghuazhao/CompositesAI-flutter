import 'dart:math';
import 'package:flutter/material.dart';

extension ContentWidth on BuildContext {
  double get contentWidth {
    final screenWidth = MediaQuery.of(this).size.width;
    final scaledScreenWidth = screenWidth * 0.7;
    const double bigScreenWidth = 800;
    if (scaledScreenWidth > bigScreenWidth) {
      return scaledScreenWidth;
    } else {
      return min(bigScreenWidth, max(scaledScreenWidth, screenWidth - 40));
    }
  }

  double get horizontalSidePaddingForContentWidth {
    final screenWidth = MediaQuery.of(this).size.width;
    final double contentWidth = this.contentWidth;
    final horizontalPadding = screenWidth - contentWidth;
    return horizontalPadding / 2;
  }
}
