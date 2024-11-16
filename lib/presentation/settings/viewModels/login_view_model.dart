// lib/presentation/viewmodels/login_view_model.dart

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<String?> login(String email, String password) async {
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

  static String GOOGLE_SIGNIN_CLIENT_ID_WEB = dotenv.env['GOOGLE_SIGNIN_CLIENT_ID_WEB'] ?? "";
  static String GOOGLE_SIGNIN_CLIENT_ID_IOS = dotenv.env['GOOGLE_SIGNIN_CLIENT_ID_IOS'] ?? "";
  static String GOOGLE_SIGNIN_CLIENT_ID_AND = dotenv.env['GOOGLE_SIGNIN_CLIENT_ID_AND'] ?? "";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? GOOGLE_SIGNIN_CLIENT_ID_WEB
        : Platform.isIOS
            ? GOOGLE_SIGNIN_CLIENT_ID_IOS
            : GOOGLE_SIGNIN_CLIENT_ID_AND,
    scopes: <String>[
      'email',
    ],
  );

  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

  GoogleSignInAccount? _user;

  GoogleSignInAccount? get user => _user;

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    _isSigningIn = true;
    notifyListeners();

    try {
      _user = await _googleSignIn.signIn();
      if (_user != null) {
        print('Logged in with Google: ${_user!.email}');
        await syncUser(_user!.displayName, _user!.email, _user!.photoUrl);
        notifyListeners();
        // You could also notify listeners here if you want to update the UI
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
      _user = null;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  // Function to handle Google Sign-Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String> syncUser(String? displayName, String email, String? photoUrl) async {
    final accessToken = await authUseCase.syncUser(displayName, email, photoUrl);
    return accessToken;
  }
}
