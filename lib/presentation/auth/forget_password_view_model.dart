import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:flutter/material.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool isLoading = false;
  String errorMessage = '';
  bool isPasswordResetting = false;

  final AuthUseCase authUseCase;

  bool obscureTextNewPassword = true;
  bool obscureTextConfirmPassword = true;

  void toggleNewPasswordVisibility() {
    obscureTextNewPassword = !obscureTextNewPassword;
    notifyListeners(); // Notify the UI about the change
  }

  void toggleConfirmPasswordVisibility() {
    obscureTextConfirmPassword = !obscureTextConfirmPassword;
    notifyListeners(); // Notify the UI about the change
  }

  ForgetPasswordViewModel({required this.authUseCase});

  Future<void> forgetPassword(String email) async {
    if (_disposed || isLoading) return;
    _setLoadingState(true);
    errorMessage = '';

    try {
      // Call the auth use case to send the confirmation code to the email
      await authUseCase.forgetPassword(email);
      isPasswordResetting = true;
    } catch (error) {
      errorMessage = 'Failed to send confirmation code.';
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> confirmResetPassword(
      String email, String newPassword, String confirmCode) async {
    if (_disposed || isLoading) return;
    _setLoadingState(true);
    errorMessage = '';

    try {
      // Call the auth use case to send the confirmation code to the email
      await authUseCase.resetPassword(email, newPassword, confirmCode);
    } catch (error) {
      errorMessage =
          'Failed to reset password. Please check your confirmation code and try again.';
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
