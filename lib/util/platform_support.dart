import 'package:flutter/foundation.dart';

/// Capabilities supplied by this app's current platform integrations.
abstract final class PlatformSupport {
  static bool get cameraCapture =>
      kIsWeb ||
      const [TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform);
}
