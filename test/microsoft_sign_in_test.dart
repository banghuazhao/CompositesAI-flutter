import 'dart:async';
import 'dart:convert';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

Map<String, dynamic> _microsoftResult() => {
      'accessToken': 'test-access-token',
      'authenticationScheme': 'Bearer',
      'expiresOn': DateTime(2030).millisecondsSinceEpoch,
      'idToken': null,
      'authority': 'https://login.microsoftonline.com/common',
      'tenantId': null,
      'scopes': ['User.Read'],
      'correlationId': null,
      'account': {
        'id': 'test-account',
        'username': 'microsoft@example.com',
        'name': 'Test User',
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const signingChannel = MethodChannel('com.compositesai/auth');
  const msalChannel = MethodChannel('msal_auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late LoginViewModel model;
  late MockAuthUseCase auth;
  var modelDisposed = false;

  setUp(() {
    modelDisposed = false;
    dotenv.loadFromString(envString: 'MICROSOFT_CLIENT_ID=example-client');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    auth = MockAuthUseCase();
    model = LoginViewModel(
      authUseCase: auth,
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
    if (!modelDisposed) model.dispose();
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
      'createMultipleAccountPca',
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

  test('explicit Microsoft login selects an account and exchanges its token',
      () async {
    final user = User(email: 'microsoft@example.com');
    when(auth.validateMicrosoftAccessToken('test-access-token')).thenAnswer(
        (_) async => AuthSession(token: 'test-session', user: user));
    final calls = <String>[];
    messenger.setMockMethodCallHandler(msalChannel, (call) async {
      calls.add(call.method);
      if (call.method == 'createMultipleAccountPca') return null;
      if (call.method == 'getAccounts') return <dynamic>[];
      expect(call.method, 'acquireToken');
      final arguments = call.arguments as Map;
      expect(arguments['prompt'], 'selectAccount');
      expect(arguments['scopes'], contains('User.Read'));
      return _microsoftResult();
    });

    await model.signInWithMicrosoft();

    expect(calls, ['createMultipleAccountPca', 'getAccounts', 'acquireToken']);
    expect(model.isSigningIn, isTrue);
    expect(model.isLoading, isFalse);
    expect(model.signedInUser, same(user));
    expect(model.errorMessage, isNull);
    verify(auth.validateMicrosoftAccessToken('test-access-token')).called(1);
  });

  test('disposal during certificate lookup does not open a native login',
      () async {
    final lookup = Completer<Map<String, String>>();
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(signingChannel, (_) => lookup.future);
    messenger.setMockMethodCallHandler(msalChannel, (_) async {
      nativeCalls++;
      return null;
    });
    final request = model.signInWithMicrosoft();
    await Future<void>.delayed(Duration.zero);
    model.dispose();
    modelDisposed = true;
    lookup.complete({
      'packageName': 'com.example.app',
      'signatureHash': base64.encode(List<int>.filled(20, 0)),
    });

    await request;

    expect(nativeCalls, 0);
    expect(model.isSigningIn, isFalse);
  });

  test('Microsoft native result after disposal skips backend exchange',
      () async {
    final pending = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    messenger.setMockMethodCallHandler(msalChannel, (call) async {
      if (call.method == 'createMultipleAccountPca') return null;
      if (call.method == 'getAccounts') return <dynamic>[];
      started.complete();
      return pending.future;
    });
    final request = model.signInWithMicrosoft();
    await started.future;
    model.dispose();
    modelDisposed = true;
    pending.complete(_microsoftResult());

    await request;

    verifyNever(auth.validateMicrosoftAccessToken('test-access-token'));
    expect(model.isSigningIn, isFalse);
    expect(model.signedInUser, isNull);
  });

  test('Microsoft backend failure does not complete login and permits retry',
      () async {
    messenger.setMockMethodCallHandler(
        msalChannel,
        (call) async => call.method == 'createMultipleAccountPca'
            ? null
            : call.method == 'getAccounts'
                ? <dynamic>[]
                : _microsoftResult());
    when(auth.validateMicrosoftAccessToken('test-access-token'))
        .thenThrow(Exception('Private backend diagnostic'));

    await model.signInWithMicrosoft();

    expect(model.isSigningIn, isFalse);
    expect(model.isLoading, isFalse);
    expect(model.signedInUser, isNull);
    expect(model.errorMessage,
        'Microsoft sign-in failed. Please try again or use email and password.');

    final user = User(email: 'microsoft@example.com');
    when(auth.validateMicrosoftAccessToken('test-access-token')).thenAnswer(
        (_) async => AuthSession(token: 'test-session', user: user));
    await model.signInWithMicrosoft();

    expect(model.isSigningIn, isTrue);
    expect(model.errorMessage, isNull);
    expect(model.signedInUser, same(user));
  });
}
