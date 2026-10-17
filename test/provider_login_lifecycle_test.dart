import 'dart:async';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

void main() {
  late MockAuthUseCase auth;
  late MockGoogleSignInService google;
  late MockAppleSignInService apple;
  late LoginViewModel model;

  final googleUser = GoogleSignInUser(
    email: 'google@example.com',
    idToken: 'test-google-token',
  );
  final appleCredential = AuthorizationCredentialAppleID(
    userIdentifier: 'test-apple-user',
    givenName: null,
    familyName: null,
    email: null,
    authorizationCode: 'test-code',
    identityToken: 'test-apple-token',
    state: null,
  );

  setUp(() {
    dotenv.loadFromString(envString: 'TEST_ENV=true');
    auth = MockAuthUseCase();
    google = MockGoogleSignInService();
    apple = MockAppleSignInService();
    model = LoginViewModel(
      authUseCase: auth,
      appleSignInService: apple,
      googleSignInService: google,
    );
  });

  tearDown(() => dotenv.clean());

  Future<GoogleSignInUser?> startGoogle() =>
      model.signInWithGoogle().then((_) => null);

  void mockGoogle(Future<GoogleSignInUser?> Function() response) {
    when(google.signIn(
      clientId: anyNamed('clientId'),
      serverClientId: anyNamed('serverClientId'),
      scopes: const ['email', 'openid', 'profile'],
      hostedDomain: anyNamed('hostedDomain'),
    )).thenAnswer((_) => response());
  }

  void mockApple(Future<AuthorizationCredentialAppleID> Function() response) {
    when(apple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
      webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
    )).thenAnswer((_) => response());
  }

  test('Google attempt blocks duplicate and other provider/password attempts',
      () async {
    final pending = Completer<GoogleSignInUser?>();
    var attempts = 0;
    mockGoogle(() {
      attempts++;
      return pending.future;
    });

    final first = startGoogle();
    expect(model.isLoading, isTrue);
    await Future.wait([
      model.signInWithGoogle(),
      model.signInWithApple(),
      model.signInWithMicrosoft(),
      model.signInWithGithub(),
      model.login('person@example.com', 'test-password'),
    ]);

    expect(attempts, 1);
    verifyNever(apple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
      webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
    ));
    verifyNever(auth.login('person@example.com', 'test-password'));
    pending.complete(null);
    await first;
    expect(model.isLoading, isFalse);
    expect(model.errorMessage, isNull);
    model.dispose();
  });

  test(
      'password login ignores direct duplicate requests while awaiting response',
      () async {
    final pending = Completer<User>();
    final user = User(email: 'person@example.com');
    when(auth.login('person@example.com', 'test-password'))
        .thenAnswer((_) => pending.future);
    final first = model.login('person@example.com', 'test-password');

    expect(await model.login('person@example.com', 'test-password'), isNull);
    pending.complete(user);

    expect(await first, same(user));
    verify(auth.login('person@example.com', 'test-password')).called(1);
    model.dispose();
  });

  test('Google SDK response after disposal cannot begin backend login',
      () async {
    final pending = Completer<GoogleSignInUser?>();
    mockGoogle(() => pending.future);
    final request = model.signInWithGoogle();
    model.dispose();
    pending.complete(googleUser);

    await request;

    verifyNever(auth.validateGoogleToken('test-google-token'));
    expect(model.signedInUser, isNull);
    expect(model.isSigningIn, isFalse);
    await model.signInWithGoogle();
  });

  test('Apple SDK response after disposal cannot begin backend login',
      () async {
    final pending = Completer<AuthorizationCredentialAppleID>();
    mockApple(() => pending.future);
    final request = model.signInWithApple();
    model.dispose();
    pending.complete(appleCredential);

    await request;

    verifyNever(auth.validateAppleToken('test-apple-token',
        email: anyNamed('email'), displayName: anyNamed('displayName')));
    expect(model.signedInUser, isNull);
    expect(model.isSigningIn, isFalse);
  });

  test('late Google backend result does not publish a disposed session',
      () async {
    final pending = Completer<AuthSession>();
    final exchangeStarted = Completer<void>();
    mockGoogle(() async => googleUser);
    when(auth.validateGoogleToken('test-google-token')).thenAnswer((_) {
      exchangeStarted.complete();
      return pending.future;
    });
    final request = model.signInWithGoogle();
    await exchangeStarted.future;
    model.dispose();
    pending.complete(AuthSession(
        token: 'test-session', user: User(email: 'google@example.com')));

    await request;

    expect(model.signedInUser, isNull);
    expect(model.isSigningIn, isFalse);
  });

  for (final exception in [
    const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    PlatformException(
        code: 'sign_in_canceled', message: 'Private native diagnostic'),
  ]) {
    test('Google cancellation is silent for ${exception.runtimeType}',
        () async {
      mockGoogle(() async => throw exception);

      await model.signInWithGoogle();

      expect(model.errorMessage, isNull);
      expect(model.isLoading, isFalse);
      expect(model.isSigningIn, isFalse);
      verifyZeroInteractions(auth);
      model.dispose();
    });
  }

  test('Google native failure hides private native details and permits retry',
      () async {
    mockGoogle(() async => throw PlatformException(
        code: 'sign_in_failed', message: 'Private native diagnostic'));

    await model.signInWithGoogle();

    expect(model.errorMessage,
        'Google sign-in could not be completed. Please try again.');
    expect(model.isLoading, isFalse);
    mockGoogle(() async => null);
    await model.signInWithGoogle();
    expect(model.errorMessage, isNull);
    model.dispose();
  });

  test('Apple backend rejection does not blame an unused password form',
      () async {
    mockApple(() async => appleCredential);
    when(auth.validateAppleToken('test-apple-token',
            email: anyNamed('email'), displayName: anyNamed('displayName')))
        .thenThrow(Exception('The email or password provided is incorrect.'));

    await model.signInWithApple();

    expect(model.errorMessage,
        'Apple sign-in could not be completed. Please try again.');
    expect(model.isSigningIn, isFalse);
    expect(model.isLoading, isFalse);
    model.dispose();
  });

  test('Apple cancellation is silent and native failure hides details',
      () async {
    mockApple(() async => throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'Private native diagnostic'));
    await model.signInWithApple();
    expect(model.errorMessage, isNull);
    expect(model.isLoading, isFalse);

    mockApple(() async => throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'Private native diagnostic'));
    await model.signInWithApple();
    expect(model.errorMessage,
        'Apple sign-in could not be completed. Please try again.');
    expect(model.isLoading, isFalse);
    model.dispose();
  });
}
