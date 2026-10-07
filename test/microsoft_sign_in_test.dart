import 'dart:convert';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const signingChannel = MethodChannel('com.compositesai/auth');
  const msalChannel = MethodChannel('msal_auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late LoginViewModel model;

  setUp(() {
    dotenv.loadFromString(envString: 'MICROSOFT_CLIENT_ID=example-client');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    model = LoginViewModel(
      authUseCase: MockAuthUseCase(),
      appleSignInService: MockAppleSignInService(),
      googleSignInService: MockGoogleSignInService(),
    );
    messenger.setMockMethodCallHandler(signingChannel, (_) async {
      return <String, String>{
        'packageName': 'com.example.app',
        'signatureHash': base64.encode(List<int>.filled(20, 0)),
      };
    });
  });

  tearDown(() {
    model.dispose();
    dotenv.clean();
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(signingChannel, null);
    messenger.setMockMethodCallHandler(msalChannel, null);
  });

  test(
      'Android reads the installed signing certificate before MSAL initialization',
      () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(signingChannel, (call) async {
      calls.add(call.method);
      return <String, String>{
        'packageName': 'com.example.app',
        'signatureHash': base64.encode(List<int>.filled(20, 255)),
      };
    });
    messenger.setMockMethodCallHandler(msalChannel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: 'USER_CANCEL');
    });

    await model.signInWithMicrosoft();

    expect(calls, <String>[
      'getMicrosoftAndroidSigningInfo',
      'createSingleAccountPca',
    ]);
    expect(model.errorMessage, isNull);
    expect(model.isSigningIn, isFalse);
  });

  test(
      'certificate lookup failure skips MSAL and presents another login option',
      () async {
    var initialized = false;
    messenger.setMockMethodCallHandler(signingChannel, (_) async {
      throw PlatformException(
        code: 'signing_certificate_unavailable',
        message: 'Private native diagnostic',
      );
    });
    messenger.setMockMethodCallHandler(msalChannel, (_) async {
      initialized = true;
      return null;
    });

    await model.signInWithMicrosoft();

    expect(initialized, isFalse);
    expect(
        model.errorMessage, MicrosoftSignInConfigurationException.userMessage);
    expect(model.isSigningIn, isFalse);
  });

  test('MSAL redirect mismatch hides technical configuration details',
      () async {
    messenger.setMockMethodCallHandler(msalChannel, (_) async {
      throw PlatformException(
        code: 'CLIENT_ERROR',
        message:
            'The redirect_uri does not match. Internal URI and certificate.',
        details: <String, String>{'errorCode': 'redirect_uri_validation_error'},
      );
    });

    await model.signInWithMicrosoft();

    expect(
        model.errorMessage, MicrosoftSignInConfigurationException.userMessage);
    expect(model.isSigningIn, isFalse);
  });

  test('other MSAL failures do not expose raw server diagnostics', () async {
    messenger.setMockMethodCallHandler(msalChannel, (_) async {
      throw PlatformException(
        code: 'SERVER_ERROR',
        message: 'Internal tenant configuration and server diagnostic.',
      );
    });

    await model.signInWithMicrosoft();

    expect(model.errorMessage,
        'Microsoft sign-in failed. Please try again or use email and password.');
    expect(model.isSigningIn, isFalse);
  });
}
