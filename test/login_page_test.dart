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
import 'package:swiftcomp/util/app_interactions.dart';
import 'package:swiftcomp/util/app_theme.dart';

class _GoogleCallbackLoginViewModel extends LoginViewModel {
  _GoogleCallbackLoginViewModel(this.callback)
      : super(
          authUseCase: MockAuthUseCase(),
          appleSignInService: MockAppleSignInService(),
          googleSignInService: MockGoogleSignInService(),
        );

  final Future<void> callback;

  @override
  Future<void> signInWithGoogle() => callback;
}

class _GithubCallbackLoginViewModel extends LoginViewModel {
  _GithubCallbackLoginViewModel(this.callback)
      : super(
          authUseCase: MockAuthUseCase(),
          appleSignInService: MockAppleSignInService(),
          googleSignInService: MockGoogleSignInService(),
        );

  final Future<void> callback;
  int cancellations = 0;
  bool finalizing = false;

  @override
  bool get isGithubFinalizing => finalizing;

  @override
  Future<void> signInWithGithub() => callback;

  @override
  void cancelGithubSignIn() {
    cancellations++;
    super.cancelGithubSignIn();
  }
}

Future<void> _openLogin(
  WidgetTester tester,
  Completer<User?> result, {
  bool dark = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
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

  for (final dark in [false, true]) {
    testWidgets('Social sign-in error has readable contrast, dark=$dark',
        (tester) async {
      final exchange = Completer<AuthSession>();
      final result = Completer<User?>();
      when(authUseCase.validateGoogleToken('google-id-token'))
          .thenAnswer((_) => exchange.future);

      await _openLogin(tester, result, dark: dark);
      await _startGoogleSignIn(tester);
      exchange.completeError(BadRequestException('INVALID_CRED'));
      await tester.pumpAndSettle();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      final message = snackbar.content as Text;
      final foreground = message.style!.color!.computeLuminance();
      final background = snackbar.backgroundColor!.computeLuminance();
      final lighter = foreground > background ? foreground : background;
      final darker = foreground < background ? foreground : background;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
    });
  }

  for (final systemBack in [false, true]) {
    testWidgets(
        'Closing GitHub cancels and ignores a late callback, '
        'systemBack=$systemBack', (tester) async {
      final callback = Completer<void>();
      final result = Completer<User?>();
      final viewModel = _GithubCallbackLoginViewModel(callback.future);
      await sl.unregister<LoginViewModel>();
      sl.registerFactory<LoginViewModel>(() => viewModel);
      await _openLogin(tester, result);
      await tester.ensureVisible(find.text('Continue with GitHub'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with GitHub'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('GitHub Sign-In'), findsOneWidget);

      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('Cancel'));
      }
      await tester.pumpAndSettle();
      expect(viewModel.cancellations, greaterThan(0));
      expect(find.text('GitHub Sign-In'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);

      callback.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(result.isCompleted, isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('GitHub cannot be cancelled while finishing sign-in',
      (tester) async {
    final callback = Completer<void>();
    final result = Completer<User?>();
    final viewModel = _GithubCallbackLoginViewModel(callback.future);
    await sl.unregister<LoginViewModel>();
    sl.registerFactory<LoginViewModel>(() => viewModel);
    await _openLogin(tester, result);
    await tester.ensureVisible(find.text('Continue with GitHub'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with GitHub'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    viewModel.finalizing = true;
    viewModel.notifyListeners();
    await tester.pump();
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    expect(tester.widget<TextButton>(cancel).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('GitHub Sign-In'), findsOneWidget);
    expect(viewModel.cancellations, 0);

    viewModel.finalizing = false;
    callback.complete();
    await tester.pumpAndSettle();
    expect(find.text('GitHub Sign-In'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login links have accessible tap targets', (tester) async {
    final result = Completer<User?>();
    await _openLogin(tester, result);
    for (final label in ['Forgot password?', 'Sign up']) {
      final button = find.widgetWithText(TextButton, label);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getRect(button).height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('A pending password login blocks other auth actions and repeats',
      (tester) async {
    final request = Completer<User>();
    final result = Completer<User?>();
    when(authUseCase.login('person@example.com', 'password123'))
        .thenAnswer((_) => request.future);
    await _openLogin(tester, result);
    for (final (index, text) in [
      (0, 'person@example.com'),
      (1, 'password123'),
    ]) {
      final field = find.byType(TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
    }
    await tester.pump();
    final googleButton = find.ancestor(
      of: find.text('Continue with Google'),
      matching: find.byType(Pressable),
    );
    final startGoogle = tester.widget<Pressable>(googleButton).onTap!;
    final signup = find.widgetWithText(TextButton, 'Sign up');
    final forgot = find.widgetWithText(TextButton, 'Forgot password?');
    final startSignup = tester.widget<TextButton>(signup).onPressed!;
    final startReset = tester.widget<TextButton>(forgot).onPressed!;
    final submit = tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sign in'))
        .onPressed!;
    submit();
    submit();
    startGoogle();
    startSignup();
    startReset();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextButton>(signup).onPressed, isNull);
    expect(tester.widget<TextButton>(forgot).onPressed, isNull);
    for (final button in tester.widgetList<Pressable>(find.byType(Pressable))) {
      expect(button.onTap, isNull);
    }
    verify(authUseCase.login('person@example.com', 'password123')).called(1);
    verifyNever(googleSignInService.signIn(
      scopes: ['email', 'openid', 'profile'],
      clientId: anyNamed('clientId'),
      hostedDomain: anyNamed('hostedDomain'),
      serverClientId: anyNamed('serverClientId'),
    ));

    request.completeError(UnauthorizedException('Invalid credentials'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<TextButton>(signup).onPressed, isNotNull);
    expect(tester.widget<TextButton>(forgot).onPressed, isNotNull);
    expect(tester.widget<Pressable>(googleButton).onTap, isNotNull);
    expect(result.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
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

  testWidgets('Google INVALID_CRED is a social error on an empty password form',
      (tester) async {
    final exchange = Completer<AuthSession>();
    final result = Completer<User?>();
    when(authUseCase.validateGoogleToken('google-id-token'))
        .thenAnswer((_) => exchange.future);

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    exchange.completeError(BadRequestException(
      'INVALID_CRED: The email or password provided is incorrect. '
      'Please check for typos and try logging in again.',
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(result.isCompleted, isFalse);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find
            .text('Google sign-in could not be completed. Please try again.'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('email or password'), findsNothing);
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }
  });

  testWidgets('A Google attempt clears a previous password login error',
      (tester) async {
    final exchange = Completer<AuthSession>();
    final result = Completer<User?>();
    when(authUseCase.login('person@example.com', 'wrong-password'))
        .thenThrow(UnauthorizedException('Invalid credentials'));
    when(authUseCase.validateGoogleToken('google-id-token'))
        .thenAnswer((_) => exchange.future);

    await _openLogin(tester, result);
    for (final (index, text) in [
      (0, 'person@example.com'),
      (1, 'wrong-password'),
    ]) {
      final field = find.byType(TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
    }
    final signIn = find.widgetWithText(ElevatedButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await _startGoogleSignIn(tester);
    expect(find.text('Incorrect email or password.'), findsNothing);

    exchange.completeError(BadRequestException('INVALID_CRED'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Incorrect email or password.'), findsNothing);
    expect(
      find.text('Google sign-in could not be completed. Please try again.'),
      findsOneWidget,
    );
    expect(result.isCompleted, isFalse);
  });

  testWidgets('An unexpected Google callback error dismisses the loading route',
      (tester) async {
    final callback = Completer<void>();
    final result = Completer<User?>();
    await sl.unregister<LoginViewModel>();
    sl.registerFactory<LoginViewModel>(
        () => _GoogleCallbackLoginViewModel(callback.future));

    await _openLogin(tester, result);
    await _startGoogleSignIn(tester);
    callback.completeError(StateError('Unexpected sign-in failure'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(result.isCompleted, isFalse);
    expect(
      find.text('Google sign-in could not be completed. Please try again.'),
      findsOneWidget,
    );
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
