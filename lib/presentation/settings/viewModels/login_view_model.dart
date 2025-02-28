// lib/presentation/viewmodels/login_view_model.dart

import 'dart:async';
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class LoginViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final AppleSignInService appleSignInService;
  final GoogleSignInService googleSignInService;

  LoginViewModel(
      {required this.authUseCase,
      required this.appleSignInService,
      required this.googleSignInService});

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool _isButtonEnabled = false;

  bool get isButtonEnabled => _isButtonEnabled;
  bool obscureText = true;

  String? email;
  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

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

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    // Initialize as not signing in
    _isSigningIn = false;
    notifyListeners();

    try {
      // Initialize GoogleSignIn instance
      final GoogleSignInUser? user = kIsWeb
          ? await googleSignInService.signIn(
              clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
              scopes: <String>['email', 'openid', 'profile'],
            )
          : await googleSignInService.signIn(
              scopes: <String>['email', 'openid', 'profile'],
            );

      print(user);

      if (user == null) {
        // User canceled the sign-in
        throw Exception('Sign-in was canceled by the user.');
      }

      // For web, sync the user immediately since ID token may not always be available
      if (kIsWeb) {
        await syncUser(user.displayName, user.email, user.photoUrl);
      } else {
        // For non-web platforms, retrieve authentication details
        final idToken = user.idToken;

        // Ensure ID token is present
        if (idToken == null) {
          throw Exception('Unable to retrieve ID token. Please try again.');
        }

        // Validate the ID token with your backend
        final bool isValid = await authUseCase.validateGoogleToken(idToken);
        if (!isValid) {
          throw Exception('Google token validation failed.');
        }
        // Sync the user data
        await syncUser(user.displayName, user.email, user.photoUrl);
      }
      // Mark signing-in as successful
      _isSigningIn = true;
    } catch (error) {
      // Handle any errors during the process
      print('Error during Google Sign-In: $error');
      _errorMessage = error.toString();
    } finally {
      // Notify listeners regardless of success or failure
      notifyListeners();
    }
  }

  // Function to handle Google Sign-Out

  Future<void> syncUser(String? displayName, String email, String? photoUrl) async {
    final accessToken = await authUseCase.syncUser(displayName, email, photoUrl);
  }

  Future<void> signInWithApple() async {
    try {
      _isSigningIn = false;
      _errorMessage = null;
      // Request credentials from Apple
      final credential = await appleSignInService.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: kIsWeb ? 'com.example.swiftcompsignin' : 'com.cdmHUB.SwiftComp',
          redirectUri: kIsWeb //This is where Apple sends the user back after they sign in.
              ? Uri.parse('https://compositesai.com')
              : Uri.parse(
                  'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
                ),
        ),
      );

      print('Apple credential: $credential');
      // Get the identity token
      final identityToken = credential.identityToken;
      final String? name = credential.givenName;

      if (identityToken == null) {
        throw Exception('Identity token not available in Apple credentials');
      }
      // Validate the token with backend and retrieve email if valid
      final email = await authUseCase.validateAppleToken(identityToken);

      await syncUser(name, email, null);

      _isSigningIn = true;
      // Notify listeners for UI update
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign in with Apple failed: $e';
      _isSigningIn = false; // Reset signing in state
      notifyListeners(); // Optionally rethrow for higher-level error handling
    }
  }

  Future<void> signInWithLinkedin() async {
    _isSigningIn = false;
    _errorMessage = null;
    try {
      final Uri authUri = await authUseCase.getAuthUrl();
      if (kIsWeb) {
        web.window.location.href = authUri.toString();
      } else {
        if (await canLaunchUrl(authUri)) {
          await launchUrl(authUri, mode: LaunchMode.inAppWebView);
        } else {
          throw Exception("Could not launch LinkedIn login page");
        }
      }
    } catch (error) {
      throw Exception("LinkedIn Sign-In Failed: $error");
    }
  }

}
