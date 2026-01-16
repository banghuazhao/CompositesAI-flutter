

import 'package:domain/mocks/auth_use_case_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';

void main() {
  group('UpdatePasswordViewModel Tests', ()
  {
    group('toggleNewPasswordVisibility', () {
      test('should toggle obscureTextNewPassword and notify listeners', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel updatePasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        // Initially true
        expect(updatePasswordViewModel.obscureTextNewPassword, true);

        // Toggle
        updatePasswordViewModel.toggleNewPasswordVisibility();
        expect(updatePasswordViewModel.obscureTextNewPassword, false);

        // Toggle back
        updatePasswordViewModel.toggleNewPasswordVisibility();
        expect(updatePasswordViewModel.obscureTextNewPassword, true);
      });
    });

    group('toggleConfirmPasswordVisibility', () {
      test('should toggle obscureTextConfirmPassword and notify listeners', () {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        expect(forgetPasswordViewModel.obscureTextConfirmPassword, true);

        // Toggle
        forgetPasswordViewModel.toggleConfirmPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextConfirmPassword, false);

        // Toggle back
        forgetPasswordViewModel.toggleConfirmPasswordVisibility();
        expect(forgetPasswordViewModel.obscureTextConfirmPassword, true);
      });
    });

    group('updatePassword', () {
      test('should set isLoading to true and back to false during the process', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        const newPassword = 'newSecurePassword123';
        const successMessage = 'Password updated successfully';

        when(mockAuthUseCase.updatePassword(newPassword)).thenAnswer((_) async => successMessage);

        final future = forgetPasswordViewModel.updatePassword(newPassword);

        // Verify isLoading is true during the process
        expect(forgetPasswordViewModel.isLoading, true);

        await future;

        // Verify isLoading is false after the process
        expect(forgetPasswordViewModel.isLoading, false);
      });

      test('should call updatePassword with the correct new password', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        const newPassword = 'newSecurePassword123';
        const successMessage = 'Password updated successfully';

        when(mockAuthUseCase.updatePassword(newPassword)).thenAnswer((_) async => successMessage);

        await forgetPasswordViewModel.updatePassword(newPassword);

        verify(mockAuthUseCase.updatePassword(newPassword)).called(1);
      });

      test('should return success message on successful process', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        const newPassword = 'newSecurePassword123';
        const successMessage = 'Password updated successfully';

        when(mockAuthUseCase.updatePassword(newPassword)).thenAnswer((_) async => successMessage);

        final result = await forgetPasswordViewModel.updatePassword(newPassword);

        expect(result, successMessage);
        expect(forgetPasswordViewModel.errorMessage, '');
      });

      test('should set and return errorMessage on failure', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        const newPassword = 'newSecurePassword123';

        when(mockAuthUseCase.updatePassword(newPassword)).thenThrow(Exception('Error'));

        final result = await forgetPasswordViewModel.updatePassword(newPassword);

        expect(result, 'Failed to update password.');
        expect(forgetPasswordViewModel.errorMessage, 'Failed to update password.');
      });

      test('should reset isLoading after failure', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        final UpdatePasswordViewModel forgetPasswordViewModel = UpdatePasswordViewModel(authUseCase: mockAuthUseCase);

        const newPassword = 'newSecurePassword123';

        when(mockAuthUseCase.updatePassword(newPassword)).thenThrow(Exception('Error'));

        await forgetPasswordViewModel.updatePassword(newPassword);

        expect(forgetPasswordViewModel.isLoading, false);
      });
    });
  });
}
