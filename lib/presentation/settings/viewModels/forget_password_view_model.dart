import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
  bool isLoading = false;
  String errorMessage = '';
  AuthUseCase authUseCase;

  ForgetPasswordViewModel({required this.authUseCase});

  Future<void> forgetPassword(String email) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      await authUseCase.forgetPassword(email);
      isLoading = false;
    } catch (error) {
      errorMessage = error.toString();
      isLoading = false;
    }
    notifyListeners();
  }
}
