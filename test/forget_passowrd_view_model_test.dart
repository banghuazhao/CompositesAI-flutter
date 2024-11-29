import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_usecase_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/settings/viewModels/forget_password_view_model.dart';

void main() {
  group('ForgetPasswordViewModel Tests', ()
  {
    group('toggleNewPasswordVisibility', () {
      test('should toggle obscureTextNewPassword and notify listeners', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        // Initially true
        expect(forgetPasswordViewModel.obscureTextNewPassword, true);

        // Toggle
        forgetPasswordViewModel.toggleNewPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextNewPassword, false);

        // Toggle back
        forgetPasswordViewModel.toggleNewPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextNewPassword, true);
      });
    });

    group('toggleConfirmPasswordVisibility', () {
      test('should toggle obscureTextConfirmPassword and notify listeners', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        expect(forgetPasswordViewModel.obscureTextConfirmPassword, true);

        // Toggle
        forgetPasswordViewModel.toggleConfirmPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextConfirmPassword, false);

        // Toggle back
        forgetPasswordViewModel.toggleConfirmPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextConfirmPassword, true);
      });
    });

    group('forgetPassword', () {
      test('should set isLoading to true and back to false during the process', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        const email = 'test@example.com';

        when(mockAuthUseCase.forgetPassword(email)).thenAnswer((_) async {});

        final future = forgetPasswordViewModel.forgetPassword(email);

        // Verify isLoading is true during the process
        expect(forgetPasswordViewModel.isLoading, true);

        await future;

        // Verify isLoading is false after the process
        expect(forgetPasswordViewModel.isLoading, false);
      });

      test('should call forgetPassword with the correct email', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        const email = 'test@example.com';

        when(mockAuthUseCase.forgetPassword(email)).thenAnswer((_) async {});

        await forgetPasswordViewModel.forgetPassword(email);

        verify(mockAuthUseCase.forgetPassword(email)).called(1);
      });

      test('should set isPasswordResetting to true on successful process', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        const email = 'test@example.com';

        when(mockAuthUseCase.forgetPassword(email)).thenAnswer((_) async {});

        await forgetPasswordViewModel.forgetPassword(email);

        expect(forgetPasswordViewModel.isPasswordResetting, true);
        expect(forgetPasswordViewModel.errorMessage, '');
      });

      test('should set errorMessage on failure and not set isPasswordResetting', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        const email = 'test@example.com';

        when(mockAuthUseCase.forgetPassword(email)).thenThrow(Exception('Error'));

        await forgetPasswordViewModel.forgetPassword(email);

        expect(forgetPasswordViewModel.isPasswordResetting, false);
        expect(forgetPasswordViewModel.errorMessage, 'Failed to send confirmation code.');
      });

      test('should reset isLoading after failure', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final ForgetPasswordViewModel forgetPasswordViewModel = ForgetPasswordViewModel(authUseCase: mockAuthUseCase);

        const email = 'test@example.com';

        when(mockAuthUseCase.forgetPassword(email)).thenThrow(Exception('Error'));

        await forgetPasswordViewModel.forgetPassword(email);

        expect(forgetPasswordViewModel.isLoading, false);
      });
    });
    group('resetPassword', () {
      test('should call repository with correct parameters', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();

        const email = 'test@example.com';
        const newPassword = 'newPassword123';
        const confirmationCode = '123456';
        const expectedResult = 'Password reset successfully';

        // Mock repository behavior
        when(mockAuthUseCase.resetPassword(email, newPassword, confirmationCode))
            .thenAnswer((_) async => expectedResult);

        final result = await mockAuthUseCase.resetPassword(email, newPassword, confirmationCode);

        // Verify the method was called with correct parameters
        verify(mockAuthUseCase.resetPassword(email, newPassword, confirmationCode)).called(1);

        // Verify the result matches the expected value
        expect(result, expectedResult);
      });

      test('should throw an exception if repository throws an error', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();

        const email = 'test@example.com';
        const newPassword = 'newPassword123';
        const confirmationCode = '123456';

        // Mock repository to throw an exception
        when(mockAuthUseCase.resetPassword(email, newPassword, confirmationCode))
            .thenThrow(Exception('Error resetting password'));

        // Verify that the method throws the exception
        expect(
              () async => await mockAuthUseCase.resetPassword(email, newPassword, confirmationCode),
          throwsA(isA<Exception>()),
        );

        // Verify the method was called with correct parameters
        verify(mockAuthUseCase.resetPassword(email, newPassword, confirmationCode)).called(1);
      });
    });
  });
  }