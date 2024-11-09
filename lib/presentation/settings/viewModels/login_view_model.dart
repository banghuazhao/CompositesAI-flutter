// lib/presentation/viewmodels/login_view_model.dart

import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;

  LoginViewModel({required this.authUseCase});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isButtonEnabled = false;
  bool get isButtonEnabled => _isButtonEnabled;
  bool obscureText = true;

  void togglePasswordVisibility() {
      obscureText = !obscureText;
      notifyListeners();
  }


  void updateButtonState(String email, String password) {
    final isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    _isButtonEnabled = isEmailValid && password.isNotEmpty && password.length >= 6;
    notifyListeners();
  }

  Future<String?> login(String email,String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await authUseCase.login(email, password);
      return accessToken; // Successful login returns the access token
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
