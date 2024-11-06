import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
  bool isLoading = false;
  String errorMessage = '';
  bool isPasswordResetting = false;

  final AuthUseCase authUseCase;

  ForgetPasswordViewModel({required this.authUseCase});

  Future<void> forgetPassword(String email) async {
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

  Future<void> confirmResetPassword(email, newPassword, confirmCode) async {
    _setLoadingState(true);
    errorMessage = '';

    try {
      // Call the auth use case to send the confirmation code to the email
      await authUseCase.resetPassword(email, newPassword, confirmCode);

    } catch (error) {
      errorMessage = 'Failed to send confirmation code.';
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
