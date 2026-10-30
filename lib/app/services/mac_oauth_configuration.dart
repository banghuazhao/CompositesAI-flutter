import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Mac providers need an explicit registration for the Mac application's ID.
abstract final class MacOAuthConfiguration {
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static String _value(String key) {
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String? get googleClientId {
    final value = _value('GOOGLE_SIGNIN_CLIENT_ID_MACOS');
    return value.isEmpty ? null : value;
  }

  static bool get googleAvailable => !isMacOS || googleClientId != null;

  static bool get microsoftAvailable =>
      !isMacOS ||
      _value('MICROSOFT_MACOS_AUTH_ENABLED').toLowerCase() == 'true';
}
