import 'dart:async';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/forget_password_view_model.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';

void main() {
  test('reset ignores another submit while its request is pending', () async {
    final auth = MockAuthUseCase();
    final response = Completer<String>();
    when(auth.resetPassword('person@example.com', 'new-password', '123456'))
        .thenAnswer((_) => response.future);
    final model = ForgetPasswordViewModel(authUseCase: auth);

    final request = model.confirmResetPassword(
        'person@example.com', 'new-password', '123456');
    await model.confirmResetPassword(
        'person@example.com', 'new-password', '123456');
    expect(model.isLoading, isTrue);
    response.complete('Password reset successfully');
    await request;

    verify(auth.resetPassword('person@example.com', 'new-password', '123456'))
        .called(1);
    expect(model.isLoading, isFalse);
    model.dispose();
  });

  test('reset response is safe after leaving the page', () async {
    final auth = MockAuthUseCase();
    final response = Completer<String>();
    when(auth.resetPassword('person@example.com', 'new-password', '123456'))
        .thenAnswer((_) => response.future);
    final model = ForgetPasswordViewModel(authUseCase: auth);

    final request = model.confirmResetPassword(
        'person@example.com', 'new-password', '123456');
    model.dispose();
    response.complete('Password reset successfully');

    await expectLater(request, completes);
  });

  test('update ignores another submit while its request is pending', () async {
    final auth = MockAuthUseCase();
    final response = Completer<String>();
    when(auth.updatePassword('old-password', 'new-password'))
        .thenAnswer((_) => response.future);
    final model = UpdatePasswordViewModel(authUseCase: auth);

    final request = model.updatePassword('old-password', 'new-password');
    await model.updatePassword('old-password', 'new-password');
    expect(model.isLoading, isTrue);
    response.complete('Password updated successfully');
    await request;

    verify(auth.updatePassword('old-password', 'new-password')).called(1);
    expect(model.isLoading, isFalse);
    model.dispose();
  });

  test('update response is safe after leaving the page', () async {
    final auth = MockAuthUseCase();
    final response = Completer<String>();
    when(auth.updatePassword('old-password', 'new-password'))
        .thenAnswer((_) => response.future);
    final model = UpdatePasswordViewModel(authUseCase: auth);

    final request = model.updatePassword('old-password', 'new-password');
    model.dispose();
    response.complete('Password updated successfully');

    await expectLater(request, completes);
  });

  test('confirmation email response is safe after leaving the page', () async {
    final auth = MockAuthUseCase();
    final response = Completer<void>();
    when(auth.forgetPassword('person@example.com'))
        .thenAnswer((_) => response.future);
    final model = ForgetPasswordViewModel(authUseCase: auth);

    final request = model.forgetPassword('person@example.com');
    model.dispose();
    response.complete();

    await expectLater(request, completes);
  });
}
