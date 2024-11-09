// lib/presentation/viewmodels/signup_view_model.dart

import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';


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

  Future<User?> signup(String email, String password,String verificationCode, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User user = await authUseCase.signup(email, password, verificationCode, name: name);
      return user;
    } catch (e) {
      _errorMessage = 'Signup failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueSignUp(String email) async {
    _setLoadingState(true);
    _errorMessage = '';

    try {
      // Call the auth use case to send the confirmation code to the email
      await authUseCase.sendSignupVerificationCode(email);
      isSignUp = true;
    } catch (error) {
      final errorMessage = error.toString();
      print("Error Message: $errorMessage");

      if (errorMessage.contains("already registered")) {
        _errorMessage = 'Email is already registered';
      } else if (errorMessage.contains("Invalid email")) {
        _errorMessage = 'Invalid email address';
      } else {
        _errorMessage = 'Failed to send verification code.';
      }
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
