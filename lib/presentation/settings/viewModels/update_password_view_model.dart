
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/cupertino.dart';

class UpdatePasswordViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  bool isLoading = false;
  String errorMessage = '';

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

  UpdatePasswordViewModel({required this.authUseCase});

  Future<String> updatePassword(String newPassword) async {
    _setLoadingState(true);
    errorMessage = '';
    try {
      // Call the auth use case to update the password
      final message = await authUseCase.updatePassword(newPassword);
      return message;
    } catch (error) {
      errorMessage = 'Failed to update password.';
      return errorMessage;
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    isLoading = value;
    notifyListeners();
  }
}