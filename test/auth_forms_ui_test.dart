import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/forget_password_page.dart';
import 'package:swiftcomp/presentation/auth/forget_password_view_model.dart';
import 'package:swiftcomp/presentation/auth/signup_view_model.dart';
import 'package:swiftcomp/presentation/auth/sigup_page.dart';
import 'package:swiftcomp/presentation/auth/update_password.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';

Future<void> _showForm(
  WidgetTester tester,
  Widget page, {
  bool keyboardVisible = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: EdgeInsets.only(bottom: keyboardVisible ? 300 : 0),
      ),
      child: child!,
    ),
    home: page,
  ));
  await tester.pumpAndSettle();
}

Future<void> _enterField(
  WidgetTester tester,
  int index,
  String value,
) async {
  final field = find.byType(TextFormField).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await sl.reset();
    final authUseCase = MockAuthUseCase();
    sl.registerFactory<SignupViewModel>(
      () => SignupViewModel(authUseCase: authUseCase),
    );
    sl.registerFactory<ForgetPasswordViewModel>(
      () => ForgetPasswordViewModel(authUseCase: authUseCase)
        ..isPasswordResetting = true,
    );
    sl.registerFactory<UpdatePasswordViewModel>(
      () => UpdatePasswordViewModel(authUseCase: authUseCase),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Reset password action stays reachable above the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _showForm(tester, const ForgetPasswordPage(), keyboardVisible: true);
    await _enterField(tester, 0, 'person@example.com');
    await _enterField(tester, 1, 'password123');
    await _enterField(tester, 2, 'password123');
    await _enterField(tester, 3, '123456');
    final reset = find.widgetWithText(MaterialButton, 'Reset');
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(reset.hitTestable(), findsOneWidget);
    expect(tester.widget<MaterialButton>(reset).onPressed, isNotNull);
    expect(tester.getRect(reset).bottom, lessThanOrEqualTo(340));
  });

  testWidgets('Update password action stays reachable above the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _showForm(tester, const UpdatePasswordPage(), keyboardVisible: true);
    await _enterField(tester, 0, 'current123');
    await _enterField(tester, 1, 'password123');
    await _enterField(tester, 2, 'password123');
    final update = find.widgetWithText(ElevatedButton, 'Update Password');
    await tester.ensureVisible(update);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(update.hitTestable(), findsOneWidget);
    expect(tester.widget<ElevatedButton>(update).onPressed, isNotNull);
    expect(tester.getRect(update).bottom, lessThanOrEqualTo(340));
  });

  testWidgets('Signup confirmation compares passwords including spaces',
      (tester) async {
    await _showForm(tester, const SignupPage());
    await _enterField(tester, 0, 'person@example.com');
    await _enterField(tester, 1, 'Test Person');
    await _enterField(tester, 2, ' password123 ');
    await _enterField(tester, 3, ' password123 ');

    final create = find.widgetWithText(MaterialButton, 'Create account');
    expect(tester.widget<MaterialButton>(create).onPressed, isNotNull);
    expect(find.text('Passwords do not match'), findsNothing);

    await _enterField(tester, 2, 'password123');
    await _enterField(tester, 3, 'password123 ');

    expect(tester.widget<MaterialButton>(create).onPressed, isNull);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
