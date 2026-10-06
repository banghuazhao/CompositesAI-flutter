import 'dart:async';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/login_page.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

Future<void> _openLogin(
  WidgetTester tester,
  Completer<User?> result,
) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result.complete(await Navigator.of(context).push<User>(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ));
          },
          child: const Text('Open login'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open login'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Continue with Google'));
  await tester.pumpAndSettle();
}

Future<void> _startGoogleSignIn(WidgetTester tester) async {
  await tester.tap(find.text('Continue with Google'));
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

void main() {
  late MockAuthUseCase authUseCase;
  late MockGoogleSignInService googleSignInService;
  late GoogleSignInUser googleUser;

  setUp(() async {
    await sl.reset();
    authUseCase = MockAuthUseCase();
    googleSignInService = MockGoogleSignInService();
    googleUser = GoogleSignInUser(
      email: 'google@example.com',
      displayName: 'Google User',
      idToken: 'google-id-token',
    );
    when(googleSignInService.signIn(
      scopes: ['email', 'openid', 'profile'],
      clientId: anyNamed('clientId'),
      hostedDomain: anyNamed('hostedDomain'),
      serverClientId: anyNamed('serverClientId'),
    )).thenAnswer((_) async => googleUser);
    sl.registerFactory<LoginViewModel>(() => LoginViewModel(
          authUseCase: authUseCase,
          appleSignInService: MockAppleSignInService(),
          googleSignInService: googleSignInService,
        ));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Google login dismisses loading and returns the backend user',
      (tester) async {
    final exchange = Completer<AuthSession>();
    final result = Completer<User?>();
    final backendUser = User(
      id: 'backend-user-id',
      email: 'account@example.com',
      name: 'Account User',
    );
    when(authUseCase.validateGoogleToken('google-id-token'))
        .thenAnswer((_) => exchange.future);

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(result.isCompleted, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    exchange.complete(AuthSession(token: 'session-token', user: backendUser));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
    expect(result.isCompleted, isTrue);
    expect(await result.future, same(backendUser));
    verify(authUseCase.validateGoogleToken('google-id-token')).called(1);
  });

  testWidgets('Google signup returns its profile for a token-only session',
      (tester) async {
    final exchange = Completer<AuthSession>();
    final result = Completer<User?>();
    when(authUseCase.validateGoogleToken('google-id-token'))
        .thenAnswer((_) => exchange.future);

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    exchange.complete(const AuthSession(token: 'new-account-token'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
    expect(result.isCompleted, isTrue);
    final returnedUser = await result.future;
    expect(returnedUser, isNotNull);
    expect(returnedUser!.email, googleUser.email);
    expect(returnedUser.name, googleUser.displayName);
  });

  testWidgets('Google cancellation clears loading and keeps login silent',
      (tester) async {
    final signIn = Completer<GoogleSignInUser?>();
    final result = Completer<User?>();
    when(googleSignInService.signIn(
      scopes: ['email', 'openid', 'profile'],
      clientId: anyNamed('clientId'),
      hostedDomain: anyNamed('hostedDomain'),
      serverClientId: anyNamed('serverClientId'),
    )).thenAnswer((_) => signIn.future);

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    signIn.complete(null);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(result.isCompleted, isFalse);
    verifyNever(authUseCase.validateGoogleToken('google-id-token'));
  });

  testWidgets('Google backend failure clears loading and allows a retry',
      (tester) async {
    final firstExchange = Completer<AuthSession>();
    final retryExchange = Completer<AuthSession>();
    final result = Completer<User?>();
    final user = User(email: 'google@example.com');
    var attempts = 0;
    when(authUseCase.validateGoogleToken('google-id-token')).thenAnswer((_) {
      attempts++;
      return attempts == 1 ? firstExchange.future : retryExchange.future;
    });

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    firstExchange.completeError(
      UnauthorizedException('Invalid Google ID token audience'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Invalid Google ID token audience'), findsOneWidget);
    expect(result.isCompleted, isFalse);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await _startGoogleSignIn(tester);
    retryExchange.complete(AuthSession(token: 'retry-token', user: user));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
    expect(result.isCompleted, isTrue);
    expect(await result.future, same(user));
    verify(authUseCase.validateGoogleToken('google-id-token')).called(2);
  });

  testWidgets('System back keeps pending Google login on its loading dialog',
      (tester) async {
    final exchange = Completer<AuthSession>();
    final result = Completer<User?>();
    final user = User(email: 'google@example.com');
    when(authUseCase.validateGoogleToken('google-id-token'))
        .thenAnswer((_) => exchange.future);

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(result.isCompleted, isFalse);

    exchange.complete(AuthSession(token: 'session-token', user: user));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(await result.future, same(user));
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Open login'), findsOneWidget);
  });

  testWidgets('Social login labels fit narrow screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: const LoginPage(),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue with Microsoft'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Continue with Microsoft').hitTestable(), findsOneWidget);
  });
}
