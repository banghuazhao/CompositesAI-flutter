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
      await authUseCase.forgetPassword(email);
      isPasswordResetting = true; // Move to the confirm reset stage
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> confirmPasswordReset(String email, String newPassword, String confirmationCode) async {
    _setLoadingState(true);
    errorMessage = '';

    try {
      await authUseCase.confirmPasswordReset(email, newPassword, confirmationCode);
      isPasswordResetting = false; // Reset process completed
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
