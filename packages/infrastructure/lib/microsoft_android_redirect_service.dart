import 'dart:convert';

import 'package:flutter/services.dart';

class MicrosoftSignInConfigurationException implements Exception {
  static const userMessage =
      'Microsoft sign-in is temporarily unavailable. Please use email or another sign-in option.';

  const MicrosoftSignInConfigurationException();

  @override
  String toString() => userMessage;
}

/// Uses the installed Android certificate, including Google Play app signing.
class MicrosoftAndroidRedirectService {
  static const _channel = MethodChannel('com.compositesai/auth');

  Future<String> getRedirectUri() async {
    try {
      final info = await _channel.invokeMapMethod<String, String>(
        'getMicrosoftAndroidSigningInfo',
      );
      final packageName = info?['packageName'];
      final signatureHash = info?['signatureHash'];
      if (packageName == null ||
          !RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$')
              .hasMatch(packageName) ||
          signatureHash == null ||
          base64.decode(signatureHash).length != 20) {
        throw const MicrosoftSignInConfigurationException();
      }

      // MSAL expects the Base64 hash encoded as one URI path segment.
      return 'msauth://$packageName/${Uri.encodeComponent(signatureHash)}';
    } on PlatformException {
      throw const MicrosoftSignInConfigurationException();
    } on MissingPluginException {
      throw const MicrosoftSignInConfigurationException();
    } on FormatException {
      throw const MicrosoftSignInConfigurationException();
    } on TypeError {
      throw const MicrosoftSignInConfigurationException();
    }
  }
}
