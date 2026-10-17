import 'dart:async';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/update_password.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';

Finder _field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

List<bool> _autofillFinishes(WidgetTester tester) => tester.testTextInput.log
    .where((call) => call.method == 'TextInput.finishAutofillContext')
    .map((call) => call.arguments as bool)
    .toList();

Future<void> _openUpdate(
  WidgetTester tester,
  Completer<String?> result, {
  String? email,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.complete(
                await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => UpdatePasswordPage(email: email),
                  ),
                ),
              );
            },
            child: const Text('Open password settings'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open password settings'));
  await tester.pumpAndSettle();
}

Future<void> _enter(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = _field(label);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> _fillValidPasswords(WidgetTester tester) async {
  await _enter(tester, 'Current Password', 'current-password');
  await _enter(tester, 'New Password', 'replacement-password');
  await _enter(tester, 'Confirm New Password', 'replacement-password');
}

void main() {
  late MockAuthUseCase auth;

  setUp(() async {
    await sl.reset();
    auth = MockAuthUseCase();
    sl.registerFactory<UpdatePasswordViewModel>(
      () => UpdatePasswordViewModel(authUseCase: auth),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
      'Password settings expose the signed-in account and correct hints',
      (tester) async {
    final result = Completer<String?>();
    await _openUpdate(tester, result, email: ' person@example.com ');

    final email = tester.widget<TextField>(_field('Email'));
    expect(email.controller!.text, 'person@example.com');
    expect(email.readOnly, isTrue);
    expect(email.autofillHints,
        orderedEquals([AutofillHints.username, AutofillHints.email]));
    expect(
        tester
            .widget<AutofillGroup>(find.byType(AutofillGroup))
            .onDisposeAction,
        AutofillContextAction.cancel);

    for (final (label, hint, action) in [
      ('Current Password', AutofillHints.password, TextInputAction.next),
      ('New Password', AutofillHints.newPassword, TextInputAction.next),
      ('Confirm New Password', AutofillHints.newPassword, TextInputAction.done),
    ]) {
      final password = tester.widget<TextField>(_field(label));
      expect(password.autofillHints, orderedEquals([hint]));
      expect(password.textInputAction, action);
      expect(password.keyboardType, TextInputType.visiblePassword);
      expect(password.autocorrect, isFalse);
      expect(password.enableSuggestions, isFalse);
      expect(password.obscureText, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Default password settings keep the existing three-field layout',
      (tester) async {
    await _openUpdate(tester, Completer<String?>());

    expect(_field('Email'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Keyboard Next advances between password fields and invalid Done waits',
      (tester) async {
    await _openUpdate(tester, Completer<String?>(),
        email: 'person@example.com');
    await _enter(tester, 'Current Password', 'current-password');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_field('New Password')).focusNode!.hasFocus,
        isTrue);

    await _enter(tester, 'New Password', 'replacement-password');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(_field('Confirm New Password'))
            .focusNode!
            .hasFocus,
        isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verifyZeroInteractions(auth);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.byType(UpdatePasswordPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Keyboard Done saves only after a confirmed update and ignores duplicates',
      (tester) async {
    final response = Completer<String>();
    final result = Completer<String?>();
    when(auth.updatePassword('current-password', 'replacement-password'))
        .thenAnswer((_) => response.future);
    await _openUpdate(tester, result, email: 'person@example.com');
    await _fillValidPasswords(tester);
    final submit =
        tester.widget<TextField>(_field('Confirm New Password')).onSubmitted!;
    tester.testTextInput.log.clear();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    submit('replacement-password');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final label in [
      'Current Password',
      'New Password',
      'Confirm New Password',
    ]) {
      expect(tester.widget<TextField>(_field(label)).readOnly, isTrue);
    }
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    verify(auth.updatePassword('current-password', 'replacement-password'))
        .called(1);

    response.complete('Password updated');
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(await result.future, 'password_updated');
    expect(_autofillFinishes(tester).where((save) => save), hasLength(1));
    expect(find.byType(UpdatePasswordPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed password updates and leaving the page never save',
      (tester) async {
    final response = Completer<String>();
    final result = Completer<String?>();
    when(auth.updatePassword('current-password', 'replacement-password'))
        .thenAnswer((_) => response.future);
    await _openUpdate(tester, result, email: 'person@example.com');
    await _fillValidPasswords(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    response.completeError(Exception('Update unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to update password.'), findsOneWidget);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Leaving edited password settings cancels autofill without saving',
      (tester) async {
    final result = Completer<String?>();
    await _openUpdate(tester, result, email: 'person@example.com');
    await _fillValidPasswords(tester);
    tester.testTextInput.log.clear();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(await result.future, isNull);
    expect(_autofillFinishes(tester), contains(false));
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Leaving a pending update does not save a late successful response',
      (tester) async {
    final response = Completer<String>();
    final result = Completer<String?>();
    when(auth.updatePassword('current-password', 'replacement-password'))
        .thenAnswer((_) => response.future);
    await _openUpdate(tester, result, email: 'person@example.com');
    await _fillValidPasswords(tester);
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    response.complete('Password updated');
    await tester.pumpAndSettle();

    expect(result.isCompleted, isTrue);
    expect(await result.future, isNull);
    expect(_autofillFinishes(tester).where((save) => save), isEmpty);
    expect(find.text('Open password settings'), findsOneWidget);
    expect(find.byType(UpdatePasswordPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
