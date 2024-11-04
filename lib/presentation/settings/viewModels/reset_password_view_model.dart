import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  bool isTokenValid = false;
  bool isLoading = false;
  String errorMessage = '';

  ResetPasswordViewModel({required this.authUseCase});

  Future<void> verifyToken(String token) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await authUseCase.resetPasswordVerify(token);
      isTokenValid = true;
    } catch (error) {
      isTokenValid = false;
      errorMessage = 'Invalid or expired token';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword(String token, String newPassword) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await authUseCase.resetPassword(token, newPassword);
      return 'Password reset successful!';
    } catch (error) {
      errorMessage = 'Failed to reset password. Please try again.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
