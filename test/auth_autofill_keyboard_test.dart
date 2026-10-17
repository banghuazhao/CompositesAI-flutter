import 'dart:async';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/forget_password_page.dart';
import 'package:swiftcomp/presentation/auth/forget_password_view_model.dart';
import 'package:swiftcomp/presentation/auth/login_page.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';
import 'package:swiftcomp/presentation/auth/signup_view_model.dart';
import 'package:swiftcomp/presentation/auth/sigup_page.dart';
import 'package:swiftcomp/util/app_theme.dart';

Finder _field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );

// Inspect only the save/cancel decision, never TextInput editing payloads.
List<bool> _autofillFinishes(WidgetTester tester) => tester.testTextInput.log
    .where((call) => call.method == 'TextInput.finishAutofillContext')
    .map((call) => call.arguments as bool)
    .toList();

Future<void> _openPage(
  WidgetTester tester,
  Widget page,
  Completer<Object?> result,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result.complete(await Navigator.of(context).push<Object>(
              MaterialPageRoute(builder: (_) => page),
            ));
          },
          child: const Text('Open auth form'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open auth form'));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = _field(key);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester, String expectedKey) async {
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
  expect(tester.widget<TextField>(_field(expectedKey)).focusNode!.hasFocus,
      isTrue);
}

void _expectPasswordField(
  WidgetTester tester,
  String key,
  String hint,
  TextInputAction action,
) {
  final field = tester.widget<TextField>(_field(key));
  expect(field.autofillHints, orderedEquals([hint]));
  expect(field.textInputAction, action);
  expect(field.keyboardType, TextInputType.visiblePassword);
  expect(field.obscureText, isTrue);
  expect(field.autocorrect, isFalse);
  expect(field.enableSuggestions, isFalse);
}

Future<void> _fillLogin(WidgetTester tester) async {
  await _enter(tester, 'login_email', 'person@example.test');
  await _enter(tester, 'login_password', 'example-password');
}

Future<void> _fillSignup(WidgetTester tester) async {
  await _enter(tester, 'signup_email', 'person@example.test');
  await _enter(tester, 'signup_name', 'Test Person');
  await _enter(tester, 'signup_password', 'example-password');
  await _enter(tester, 'signup_password_confirmation', 'example-password');
}

Future<void> _fillReset(WidgetTester tester) async {
  await _enter(tester, 'reset_email', 'person@example.test');
  await _enter(tester, 'reset_new_password', 'example-password');
  await _enter(tester, 'reset_password_confirmation', 'example-password');
  await _enter(tester, 'reset_code', '123456');
}

void main() {
  late MockAuthUseCase auth;
  var resetReady = false;

  setUp(() async {
    await sl.reset();
    auth = MockAuthUseCase();
    resetReady = false;
    sl.registerFactory<LoginViewModel>(() => LoginViewModel(
          authUseCase: auth,
          appleSignInService: MockAppleSignInService(),
          googleSignInService: MockGoogleSignInService(),
        ));
    sl.registerFactory<SignupViewModel>(
        () => SignupViewModel(authUseCase: auth));
    sl.registerFactory<ForgetPasswordViewModel>(() =>
        ForgetPasswordViewModel(authUseCase: auth)
          ..isPasswordResetting = resetReady);
  });

  tearDown(() async => sl.reset());

  testWidgets(
      'Login hints and keyboard Next work; incomplete Done does not save',
      (tester) async {
    await _openPage(tester, const LoginPage(), Completer<Object?>());
    final email = tester.widget<TextField>(_field('login_email'));
    expect(email.autofillHints,
        orderedEquals([AutofillHints.username, AutofillHints.email]));
    expect(email.textInputAction, TextInputAction.next);
    _expectPasswordField(
        tester, 'login_password', AutofillHints.password, TextInputAction.done);

    await _enter(tester, 'login_email', 'person@example.test');
    await _next(tester, 'login_password');
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verifyZeroInteractions(auth);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login Done submits once and saves only after backend success',
      (tester) async {
    final response = Completer<User>();
    final result = Completer<Object?>();
    final user = User(email: 'person@example.test');
    when(auth.login('person@example.test', 'example-password'))
        .thenAnswer((_) => response.future);
    await _openPage(tester, const LoginPage(), result);
    await _fillLogin(tester);
    final keyboardSubmit =
        tester.widget<TextField>(_field('login_password')).onSubmitted!;
    final buttonSubmit = tester
        .widget<ElevatedButton>(find.byKey(const ValueKey('login_submit')))
        .onPressed!;
    tester.testTextInput.log.clear();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    keyboardSubmit('');
    buttonSubmit();
    await tester.pump();

    for (final key in ['login_email', 'login_password']) {
      expect(tester.widget<TextField>(_field(key)).readOnly, isTrue);
    }
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(result.isCompleted, isFalse);
    verify(auth.login('person@example.test', 'example-password')).called(1);
    response.complete(user);
    await tester.pumpAndSettle();

    expect(await result.future, same(user));
    expect(_autofillFinishes(tester).where((save) => save), hasLength(1));
    expect(find.byType(LoginPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rejected login and Back cancel autofill without saving',
      (tester) async {
    final result = Completer<Object?>();
    when(auth.login('person@example.test', 'example-password'))
        .thenThrow(UnauthorizedException('Invalid credentials'));
    await _openPage(tester, const LoginPage(), result);
    await _fillLogin(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signup hints and Next focus order reject incomplete Done',
      (tester) async {
    await _openPage(tester, const SignupPage(), Completer<Object?>());
    expect(tester.widget<TextField>(_field('signup_email')).autofillHints,
        orderedEquals([AutofillHints.username, AutofillHints.email]));
    expect(tester.widget<TextField>(_field('signup_name')).autofillHints,
        orderedEquals([AutofillHints.name]));
    _expectPasswordField(tester, 'signup_password', AutofillHints.newPassword,
        TextInputAction.next);
    _expectPasswordField(tester, 'signup_password_confirmation',
        AutofillHints.newPassword, TextInputAction.done);

    await _enter(tester, 'signup_email', 'person@example.test');
    await _next(tester, 'signup_name');
    await _enter(tester, 'signup_name', 'Test Person');
    await _next(tester, 'signup_password');
    await _enter(tester, 'signup_password', 'example-password');
    await _next(tester, 'signup_password_confirmation');
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verifyZeroInteractions(auth);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.byType(SignupPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signup Done blocks repeated callbacks and saves after success',
      (tester) async {
    final response = Completer<AuthSession>();
    final result = Completer<Object?>();
    final user = User(email: 'person@example.test');
    when(auth.signUp('Test Person', 'person@example.test', 'example-password',
            profileImageUrl: anyNamed('profileImageUrl')))
        .thenAnswer((_) => response.future);
    await _openPage(tester, const SignupPage(), result);
    await _fillSignup(tester);
    final keyboardSubmit = tester
        .widget<TextField>(_field('signup_password_confirmation'))
        .onSubmitted!;
    tester.testTextInput.log.clear();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    keyboardSubmit('');
    await tester.pump();
    for (final key in [
      'signup_email',
      'signup_name',
      'signup_password',
      'signup_password_confirmation',
    ]) {
      expect(tester.widget<TextField>(_field(key)).readOnly, isTrue);
    }
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(result.isCompleted, isFalse);
    verify(auth.signUp('Test Person', 'person@example.test', 'example-password',
            profileImageUrl: anyNamed('profileImageUrl')))
        .called(1);
    response.complete(AuthSession(token: 'mock-session', user: user));
    await tester.pumpAndSettle();

    expect(await result.future, same(user));
    expect(_autofillFinishes(tester).where((save) => save), hasLength(1));
    expect(find.byType(SignupPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rejected signup and Back never save generated credentials',
      (tester) async {
    final result = Completer<Object?>();
    when(auth.signUp('Test Person', 'person@example.test', 'example-password',
            profileImageUrl: anyNamed('profileImageUrl')))
        .thenThrow(ResourceAlreadyExistsException());
    await _openPage(tester, const SignupPage(), result);
    await _fillSignup(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(SignupPage), findsOneWidget);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Code-send Done is guarded and never saves; reset Next focuses code',
      (tester) async {
    final codeRequest = Completer<void>();
    when(auth.forgetPassword('person@example.test'))
        .thenAnswer((_) => codeRequest.future);
    await _openPage(tester, const ForgetPasswordPage(), Completer<Object?>());
    final email = tester.widget<TextField>(_field('reset_email'));
    expect(email.autofillHints,
        orderedEquals([AutofillHints.username, AutofillHints.email]));
    expect(email.textInputAction, TextInputAction.done);
    await _enter(tester, 'reset_email', 'person@example.test');
    final repeatDone =
        tester.widget<TextField>(_field('reset_email')).onSubmitted!;
    tester.testTextInput.log.clear();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    repeatDone('');
    await tester.pump();
    expect(tester.widget<TextField>(_field('reset_email')).readOnly, isTrue);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    verify(auth.forgetPassword('person@example.test')).called(1);
    codeRequest.complete();
    await tester.pumpAndSettle();

    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(
        tester
            .widget<TextField>(_field('reset_new_password'))
            .focusNode!
            .hasFocus,
        isTrue);
    _expectPasswordField(tester, 'reset_new_password',
        AutofillHints.newPassword, TextInputAction.next);
    _expectPasswordField(tester, 'reset_password_confirmation',
        AutofillHints.newPassword, TextInputAction.next);
    final code = tester.widget<TextField>(_field('reset_code'));
    expect(code.autofillHints, orderedEquals([AutofillHints.oneTimeCode]));
    expect(code.textInputAction, TextInputAction.done);
    await _enter(tester, 'reset_email', 'person@example.test');
    await _next(tester, 'reset_new_password');
    await _enter(tester, 'reset_new_password', 'example-password');
    await _next(tester, 'reset_password_confirmation');
    await _enter(tester, 'reset_password_confirmation', 'example-password');
    await _next(tester, 'reset_code');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verifyNever(
        auth.resetPassword('person@example.test', 'example-password', ''));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.byType(ForgetPasswordPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset Done stays busy and saves only after reset succeeds',
      (tester) async {
    resetReady = true;
    final response = Completer<String>();
    final result = Completer<Object?>();
    when(auth.resetPassword(
            'person@example.test', 'example-password', '123456'))
        .thenAnswer((_) => response.future);
    await _openPage(tester, const ForgetPasswordPage(), result);
    await _fillReset(tester);
    final keyboardSubmit =
        tester.widget<TextField>(_field('reset_code')).onSubmitted!;
    final buttonSubmit = tester
        .widget<MaterialButton>(find.widgetWithText(MaterialButton, 'Reset'))
        .onPressed!;
    tester.testTextInput.log.clear();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    keyboardSubmit('');
    buttonSubmit();
    await tester.pump();
    for (final key in [
      'reset_email',
      'reset_new_password',
      'reset_password_confirmation',
      'reset_code',
    ]) {
      expect(tester.widget<TextField>(_field(key)).readOnly, isTrue);
    }
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(result.isCompleted, isFalse);
    verify(auth.resetPassword(
            'person@example.test', 'example-password', '123456'))
        .called(1);
    response.complete('Password reset successfully');
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(_autofillFinishes(tester).where((save) => save), hasLength(1));
    expect(find.byType(ForgetPasswordPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rejected reset and Back never save the replacement password',
      (tester) async {
    resetReady = true;
    final result = Completer<Object?>();
    when(auth.resetPassword(
            'person@example.test', 'example-password', '123456'))
        .thenThrow(BadRequestException('Invalid confirmation code'));
    await _openPage(tester, const ForgetPasswordPage(), result);
    await _fillReset(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(ForgetPasswordPage), findsOneWidget);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset success after Back starts never commits autofill',
      (tester) async {
    resetReady = true;
    final response = Completer<String>();
    final result = Completer<Object?>();
    when(auth.resetPassword(
            'person@example.test', 'example-password', '123456'))
        .thenAnswer((_) => response.future);
    await _openPage(tester, const ForgetPasswordPage(), result);
    await _fillReset(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.binding.handlePopRoute();
    // The outgoing route remains mounted during its transition. A late result
    // must not save credentials merely because that State has not disposed yet.
    await tester.pump(const Duration(milliseconds: 16));
    response.complete('Password reset successfully');
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.byType(ForgetPasswordPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (page, emailKey) in [
    (const LoginPage(), 'login_email'),
    (const SignupPage(), 'signup_email'),
    (const ForgetPasswordPage(), 'reset_email'),
  ]) {
    testWidgets('Leaving ${page.runtimeType} without submitting never saves',
        (tester) async {
      final result = Completer<Object?>();
      await _openPage(tester, page, result);
      await _enter(tester, emailKey, 'person@example.test');
      tester.testTextInput.log.clear();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await result.future, isNull);
      expect(_autofillFinishes(tester), contains(false));
      expect(_autofillFinishes(tester).where((save) => save), isEmpty);
      verifyZeroInteractions(auth);
      expect(tester.takeException(), isNull);
    });
  }
}
