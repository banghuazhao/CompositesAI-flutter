// lib/presentation/viewmodels/signup_view_model.dart

import 'package:domain/entities/user.dart';
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:flutter/material.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;

  bool obscureTextNewPassword = true;
  bool obscureTextConfirmPassword = true;
  bool isSignUp = false;

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
  String? _loginErrorMessage;
  String? get loginErrorMessage => _loginErrorMessage;

  Future<User?> signup(String email, String password, String verificationCode,
      {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User user = await authUseCase.signup(email, password, verificationCode,
          name: name);
      return user;
    } catch (e) {
      _errorMessage = 'Signup failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpFor(String email) async {
    _setLoadingState(true);
    _errorMessage = '';

    try {
      // Call the auth use case to send the confirmation code to the email
      await authUseCase.sendSignupVerificationCode(email);
      isSignUp = true;
    } catch (error) {
      final errorMessage = error.toString();
      print("Error Message: $errorMessage");
      _errorMessage = errorMessage;
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> login(String email,String password) async {
    _isLoading = true;
    _loginErrorMessage = null;
    notifyListeners();

    try {
      final accessToken = await authUseCase.login(email, password);
      return accessToken; // Successful login returns the access token
    } catch (e) {
      _loginErrorMessage = 'Login failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
