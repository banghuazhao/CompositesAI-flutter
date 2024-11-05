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

  void updateButtonState(String username, String password) {
    _isButtonEnabled = username.isNotEmpty && password.isNotEmpty;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await authUseCase.login(username, password);
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
