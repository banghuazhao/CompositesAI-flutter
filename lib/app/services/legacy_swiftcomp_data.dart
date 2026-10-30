import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the old Mac store available as a lossless, user-selected backup.
/// No records are imported with guessed units or written into the old store.
class LegacySwiftCompData {
  const LegacySwiftCompData();

  static const _channel = MethodChannel('compositesai/legacy-swiftcomp');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<bool> isAvailable() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasLegacyData') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// True means saved; false means the user cancelled the native save panel.
  Future<bool> export() async {
    if (!_supported) return false;
    return await _channel.invokeMethod<bool>('exportLegacyData') ?? false;
  }
}
