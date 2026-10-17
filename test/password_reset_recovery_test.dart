import 'dart:async';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/forget_password_page.dart';
import 'package:swiftcomp/presentation/auth/forget_password_view_model.dart';

Finder _field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );

Iterable<bool> _savedAutofill(WidgetTester tester) => tester.testTextInput.log
    .where((call) => call.method == 'TextInput.finishAutofillContext')
    .map((call) => call.arguments as bool)
    .where((save) => save);

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.ensureVisible(_field(key));
  await tester.pumpAndSettle();
  await tester.enterText(_field(key), value);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump();
}

void main() {
  const email = 'person@example.test';
  const cooldown = Duration(seconds: 10);
  late MockAuthUseCase auth;
  late ForgetPasswordViewModel model;
  DateTime Function() now = DateTime.now;

  setUp(() async {
    await sl.reset();
    auth = MockAuthUseCase();
    sl.registerFactory<ForgetPasswordViewModel>(() {
      model = ForgetPasswordViewModel(
          authUseCase: auth, resendCooldown: cooldown, now: now);
      return model;
    });
  });

  tearDown(() async => sl.reset());

  Future<Completer<Object?>> open(WidgetTester tester,
      {String initialEmail = email}) async {
    now = tester.binding.clock.now;
    final result = Completer<Object?>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => result.complete(await Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) =>
                        ForgetPasswordPage(initialEmail: initialEmail)))),
            child: const Text('Open reset'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open reset'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> send(WidgetTester tester) async {
    await _tap(tester, find.widgetWithText(MaterialButton, 'Reset Password'));
    await tester.pumpAndSettle();
  }

  Future<void> fillReplacement(WidgetTester tester) async {
    await _enter(tester, 'reset_new_password', 'replacement-password');
    await _enter(tester, 'reset_password_confirmation', 'replacement-password');
    await _enter(tester, 'reset_code', '123456');
  }

  test('Confirmation stays bound to the email that received the code',
      () async {
    final direct = ForgetPasswordViewModel(
        authUseCase: auth, resendCooldown: Duration.zero);
    addTearDown(direct.dispose);
    when(auth.forgetPassword(email)).thenAnswer((_) async {});
    when(auth.resetPassword(email, 'replacement-password', '123456'))
        .thenAnswer((_) async => 'Password reset successfully');

    expect(await direct.forgetPassword(' Person@Example.Test '), isTrue);
    expect(direct.requestedEmail, email);
    expect(
        await direct.confirmResetPassword(
            'different@example.test', 'replacement-password', '123456'),
        isTrue);

    verify(auth.forgetPassword(email)).called(1);
    verify(auth.resetPassword(email, 'replacement-password', '123456'))
        .called(1);
    verifyNever(auth.resetPassword(
        'different@example.test', 'replacement-password', '123456'));
  });

  test('A code response after disposal cannot start recovery or its timer',
      () async {
    final response = Completer<void>();
    when(auth.forgetPassword(email)).thenAnswer((_) => response.future);
    final direct = ForgetPasswordViewModel(authUseCase: auth);
    final request = direct.forgetPassword(email);
    direct.dispose();
    response.complete();

    expect(await request, isFalse);
    expect(direct.requestedEmail, isNull);
    expect(direct.isPasswordResetting, isFalse);
  });

  testWidgets('Prefilled email becomes read-only after sending without saving',
      (tester) async {
    await open(tester, initialEmail: ' Person@Example.Test ');
    expect(tester.widget<TextField>(_field('reset_email')).controller!.text,
        'Person@Example.Test');
    await send(tester);

    final field = tester.widget<TextField>(_field('reset_email'));
    expect(field.controller!.text, email);
    expect(field.readOnly, isTrue);
    expect(model.requestedEmail, email);
    expect(find.textContaining('sent to $email'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('reset_resend_code')))
            .onPressed,
        isNull);
    expect(model.resendSecondsRemaining, greaterThan(0));
    expect(_savedAutofill(tester), isEmpty);
    verify(auth.forgetPassword(email)).called(1);
  });

  testWidgets(
      'Change email clears recovery details and preserves per-email cooldown',
      (tester) async {
    await open(tester);
    await send(tester);
    await fillReplacement(tester);
    tester.testTextInput.log.clear();
    await _tap(tester, find.byKey(const ValueKey('reset_change_email')));
    await tester.pumpAndSettle();

    expect(model.requestedEmail, isNull);
    expect(model.isPasswordResetting, isFalse);
    expect(tester.widget<TextField>(_field('reset_email')).readOnly, isFalse);
    expect(_field('reset_new_password'), findsNothing);
    expect(find.byType(MaterialButton), findsOneWidget);
    expect(tester.widget<MaterialButton>(find.byType(MaterialButton)).onPressed,
        isNull);
    expect(
        tester.testTextInput.log.any((call) =>
            call.method == 'TextInput.finishAutofillContext' &&
            call.arguments == false),
        isTrue);
    expect(_savedAutofill(tester), isEmpty);

    await _enter(tester, 'reset_email', 'other@example.test');
    expect(tester.widget<MaterialButton>(find.byType(MaterialButton)).onPressed,
        isNotNull);
    await send(tester);
    expect(model.requestedEmail, 'other@example.test');
    for (final key in [
      'reset_new_password',
      'reset_password_confirmation',
      'reset_code'
    ]) {
      expect(tester.widget<TextField>(_field(key)).controller!.text, isEmpty);
    }
    verify(auth.forgetPassword(email)).called(1);
    verify(auth.forgetPassword('other@example.test')).called(1);
    expect(_savedAutofill(tester), isEmpty);
  });

  testWidgets('Resend waits for cooldown and clears only the confirmation code',
      (tester) async {
    final response = Completer<void>();
    var sends = 0;
    when(auth.forgetPassword(email)).thenAnswer((_) {
      sends++;
      return sends == 1 ? Future<void>.value() : response.future;
    });
    await open(tester);
    await send(tester);
    await fillReplacement(tester);
    await model.resendCode();
    expect(sends, 1);
    await tester.pump(cooldown);
    await tester.pumpAndSettle();
    final resend = find.byKey(const ValueKey('reset_resend_code'));
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
    await _tap(tester, resend);
    expect(find.text('Sending code…'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('reset_change_email')))
            .onPressed,
        isNull);
    expect(tester.widget<TextField>(_field('reset_new_password')).readOnly,
        isTrue);
    response.complete();
    await tester.pumpAndSettle();

    expect(sends, 2);
    expect(tester.widget<TextField>(_field('reset_code')).controller!.text,
        isEmpty);
    expect(
        tester.widget<TextField>(_field('reset_new_password')).controller!.text,
        'replacement-password');
    expect(
        tester
            .widget<TextField>(_field('reset_password_confirmation'))
            .controller!
            .text,
        'replacement-password');
    expect(tester.widget<TextField>(_field('reset_code')).focusNode!.hasFocus,
        isTrue);
    expect(model.resendSecondsRemaining, greaterThan(0));
    expect(_savedAutofill(tester), isEmpty);
  });

  testWidgets('Failed resend keeps the recipient and entered details retryable',
      (tester) async {
    var sends = 0;
    when(auth.forgetPassword(email)).thenAnswer((_) async {
      sends++;
      if (sends == 2) throw Exception('Request unavailable');
    });
    await open(tester);
    await send(tester);
    await fillReplacement(tester);
    await tester.pump(cooldown);
    await tester.pumpAndSettle();
    final resend = find.byKey(const ValueKey('reset_resend_code'));
    await _tap(tester, resend);
    await tester.pumpAndSettle();

    expect(model.requestedEmail, email);
    expect(model.isLoading, isFalse);
    expect(model.canResendCode, isTrue);
    expect(find.text('Failed to send confirmation code.'), findsOneWidget);
    expect(tester.widget<TextField>(_field('reset_code')).controller!.text,
        '123456');
    expect(
        tester.widget<TextField>(_field('reset_new_password')).controller!.text,
        'replacement-password');
    expect(_savedAutofill(tester), isEmpty);

    await _tap(tester, resend);
    await tester.pumpAndSettle();
    expect(sends, 3);
    expect(tester.widget<TextField>(_field('reset_code')).controller!.text,
        isEmpty);
    expect(_savedAutofill(tester), isEmpty);
  });

  testWidgets(
      'Rate-limited resend starts a cooldown without discarding recovery',
      (tester) async {
    var sends = 0;
    when(auth.forgetPassword(email)).thenAnswer((_) async {
      sends++;
      if (sends == 2) throw TooManyRequestsException('Rate limited');
    });
    await open(tester);
    await send(tester);
    await fillReplacement(tester);
    await tester.pump(cooldown);
    await tester.pumpAndSettle();
    final resend = find.byKey(const ValueKey('reset_resend_code'));
    await _tap(tester, resend);
    await tester.pumpAndSettle();

    expect(model.requestedEmail, email);
    expect(model.resendSecondsRemaining, greaterThan(0));
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    expect(find.textContaining('Too many requests.'), findsOneWidget);
    expect(tester.widget<TextField>(_field('reset_code')).controller!.text,
        '123456');
    expect(_savedAutofill(tester), isEmpty);
    await tester.pump(cooldown);
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
  });

  testWidgets('Back during code delivery never saves or opens another route',
      (tester) async {
    final response = Completer<void>();
    when(auth.forgetPassword(email)).thenAnswer((_) => response.future);
    final result = await open(tester);
    await _tap(tester, find.widgetWithText(MaterialButton, 'Reset Password'));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 16));
    response.complete();
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(await result.future, isNull);
    expect(find.byType(ForgetPasswordPage), findsNothing);
    expect(find.text('Open reset'), findsOneWidget);
    expect(_savedAutofill(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
