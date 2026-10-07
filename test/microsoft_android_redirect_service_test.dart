import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.compositesai/auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('uses installed certificate and encodes Base64 URI characters',
      () async {
    final hash = base64.encode(List<int>.filled(20, 255));
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getMicrosoftAndroidSigningInfo');
      expect(call.arguments, isNull);
      return <String, String>{
        'packageName': 'com.example.app',
        'signatureHash': hash,
      };
    });

    final redirect = await MicrosoftAndroidRedirectService().getRedirectUri();

    expect(redirect, 'msauth://com.example.app/${Uri.encodeComponent(hash)}');
    expect(redirect, contains('%2F'));
    expect(redirect, contains('%3D'));
    expect(Uri.parse(redirect).pathSegments, <String>[hash]);
  });

  test('encodes plus characters rather than treating them as spaces', () async {
    final hash = base64.encode(List<int>.filled(20, 251));
    messenger.setMockMethodCallHandler(
        channel,
        (_) async => <String, String>{
              'packageName': 'com.example.app',
              'signatureHash': hash,
            });

    final redirect = await MicrosoftAndroidRedirectService().getRedirectUri();

    expect(redirect, contains('%2B'));
    expect(Uri.parse(redirect).pathSegments, <String>[hash]);
  });

  final invalidSigningInfo = <String, Map<String, String>?>{
    'null response': null,
    'missing fields': <String, String>{},
    'invalid Base64': <String, String>{
      'packageName': 'com.example.app',
      'signatureHash': 'not a certificate',
    },
    'wrong digest length': <String, String>{
      'packageName': 'com.example.app',
      'signatureHash': base64.encode(<int>[1, 2, 3]),
    },
    'invalid package name': <String, String>{
      'packageName': 'com.example.app/path',
      'signatureHash': base64.encode(List<int>.filled(20, 0)),
    },
  };
  for (final invalid in invalidSigningInfo.entries) {
    test('fails safely for ${invalid.key}', () async {
      messenger.setMockMethodCallHandler(channel, (_) async => invalid.value);

      await expectLater(
        MicrosoftAndroidRedirectService().getRedirectUri(),
        throwsA(isA<MicrosoftSignInConfigurationException>()),
      );
    });
  }

  test('hides native error details from users', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'signing_certificate_unavailable',
        message: 'Internal native configuration details',
      );
    });

    await expectLater(
      MicrosoftAndroidRedirectService().getRedirectUri(),
      throwsA(predicate<Object>((error) =>
          error.toString() ==
          MicrosoftSignInConfigurationException.userMessage)),
    );
  });

  test('fails safely when native channel is unavailable', () async {
    await expectLater(
      MicrosoftAndroidRedirectService().getRedirectUri(),
      throwsA(isA<MicrosoftSignInConfigurationException>()),
    );
  });
}
