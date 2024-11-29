// lib/presentation/viewmodels/login_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  String? email;

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

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    // Initialize as not signing in
    _isSigningIn = false;
    notifyListeners();

    try {
      // Initialize GoogleSignIn instance
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
        clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
        scopes: <String>['email', 'openid', 'profile'],
      )
          : GoogleSignIn(
        scopes: <String>['email', 'openid', 'profile'],
      );

      // Sign in the user
      final GoogleSignInAccount? user = await googleSignIn.signIn();

      if (user == null) {
        // User canceled the sign-in
        throw Exception('Sign-in was canceled by the user.');
      }

      // For web, sync the user immediately since ID token may not always be available
      if (kIsWeb) {
        await syncUser(user.displayName, user.email, user.photoUrl);
      } else {
        // For non-web platforms, retrieve authentication details
        final GoogleSignInAuthentication auth = await user.authentication;

        // Ensure ID token is present
        if (auth.idToken == null) {
          throw Exception('Unable to retrieve ID token. Please try again.');
        }

        // Validate the ID token with your backend
        final bool isValid = await authUseCase.validateGoogleToken(auth.idToken!);
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
    } finally {
      // Notify listeners regardless of success or failure
      notifyListeners();
    }
  }

  // Function to handle Google Sign-Out

  Future<String> syncUser(String? displayName, String email, String? photoUrl) async {
    final accessToken = await authUseCase.syncUser(displayName, email, photoUrl);
    return accessToken;
  }

  Future<void> signInWithApple() async {
    try {
      _isSigningIn = false;
      // Request credentials from Apple
      final credential = await SignInWithApple.getAppleIDCredential(
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
      print('Sign in with Apple failed: $e');
      rethrow; // Optionally rethrow for higher-level error handling
    }
  }


}
