// lib/presentation/viewmodels/signup_view_model.dart

import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';


class SignupViewModel extends ChangeNotifier {
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


  SignupViewModel({required this.authUseCase});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<User?> signup(String email, String password, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User user = await authUseCase.signup(email, password, name: name);
      return user;
    } catch (e) {
      _errorMessage = 'Signup failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
