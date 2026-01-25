
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:flutter/cupertino.dart';

class UpdatePasswordViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  bool isLoading = false;
  String errorMessage = '';


  bool obscureCurrentPassword = true;
  bool obscureTextNewPassword = true;
  bool obscureTextConfirmPassword = true;

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword = !obscureCurrentPassword;
    notifyListeners();
  }
  void toggleNewPasswordVisibility() {
    obscureTextNewPassword = !obscureTextNewPassword;
    notifyListeners(); // Notify the UI about the change
  }

  void toggleConfirmPasswordVisibility() {
    obscureTextConfirmPassword = !obscureTextConfirmPassword;
    notifyListeners(); // Notify the UI about the change
  }

  UpdatePasswordViewModel({required this.authUseCase});


  Future<void> updatePassword(String currentPassword, String newPassword) async {
    _setLoadingState(true);
    errorMessage = '';
    try {
      await authUseCase.updatePassword(currentPassword, newPassword);
    } catch (error) {
      errorMessage = 'Failed to update password.';
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}