// lib/presentation/viewmodels/login_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:domain/entities/auth_session.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/use_cases/auth_use_case.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:msal_auth/msal_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

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

  User? _signedInUser;
  User? get signedInUser => _signedInUser;

  String? _githubUserCode;
  String? get githubUserCode => _githubUserCode;

  String? _githubVerificationUri;
  String? get githubVerificationUri => _githubVerificationUri;

  bool _cancelGithubSignIn = false;
  void cancelGithubSignIn() {
    _cancelGithubSignIn = true;
  }

  void togglePasswordVisibility() {
    obscureText = !obscureText;
    notifyListeners();
  }

  void updateButtonState(String email, String password) {
    final isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    _isButtonEnabled =
        isEmailValid && password.isNotEmpty && password.length >= 6;
    notifyListeners();
  }

  Future<User?> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _signedInUser = null;
    notifyListeners();

    try {
      final user = await authUseCase.login(email, password);
      _signedInUser = user;
      return user; // Successful login returns the access token
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String? _env(String key) {
    // flutter_dotenv throws NotInitializedError if dotenv.load() wasn't called.
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  // Web client id (used on web sign-in, and commonly reused as serverClientId on Android).
  static String get GOOGLE_SIGNIN_CLIENT_ID_WEB =>
      _env('GOOGLE_SIGNIN_CLIENT_ID_WEB') ?? "";

  // On Android, providing serverClientId is commonly required to receive a non-null idToken.
  // Using the Web client ID here is the typical setup when backend verifies Google ID tokens.
  static String get GOOGLE_SIGNIN_SERVER_CLIENT_ID =>
      _env('GOOGLE_SIGNIN_SERVER_CLIENT_ID') ??
      _env('GOOGLE_SIGNIN_CLIENT_ID_WEB') ??
      "";

  static String get GITHUB_CLIENT_ID => _env('GITHUB_CLIENT_ID') ?? "";
  static String get GITHUB_SCOPE =>
      _env('GITHUB_CLIENT_SCOPE') ?? 'read:user user:email';
  static const String _githubDeviceCodeUrl = 'https://github.com/login/device/code';
  static const String _githubAccessTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String _githubDeviceGrantType =
      'urn:ietf:params:oauth:grant-type:device_code';

  static String get MICROSOFT_CLIENT_ID => _env('MICROSOFT_CLIENT_ID') ?? "";
  static String get MICROSOFT_SCOPES => _env('MICROSOFT_SCOPES') ?? 'User.Read';
  static List<String> get MICROSOFT_SCOPE_LIST => MICROSOFT_SCOPES
      .split(RegExp(r'[ ,]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  static String get MICROSOFT_ANDROID_REDIRECT_URI =>
      _env('MICROSOFT_ANDROID_REDIRECT_URI') ??
      'msauth://com.banghuazhao.swiftcomp/dA9fci2wzppcQYLy4VOxftNW8Hk=';
  static String get MICROSOFT_MSAL_CONFIG_PATH =>
      _env('MICROSOFT_MSAL_CONFIG_PATH') ?? 'msal_config.json';
  static String get MICROSOFT_AUTHORITY => _env('MICROSOFT_AUTHORITY') ?? "";

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    // Initialize as not signing in
    _isSigningIn = false;
    _signedInUser = null;
    notifyListeners();

    try {
      // Initialize GoogleSignIn instance
      final GoogleSignInUser? user = kIsWeb
          ? await googleSignInService.signIn(
              clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
              scopes: <String>['email', 'openid', 'profile'],
            )
          : await googleSignInService.signIn(
              serverClientId: GOOGLE_SIGNIN_SERVER_CLIENT_ID.isEmpty
                  ? null
                  : GOOGLE_SIGNIN_SERVER_CLIENT_ID,
              scopes: <String>['email', 'openid', 'profile'],
            );

      print(user);

      if (user == null) {
        // User canceled the sign-in
        throw Exception('Sign-in was canceled by the user.');
      }

      // For non-web platforms, retrieve authentication details
      final idToken = user.idToken;

      // Ensure ID token is present
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Unable to retrieve ID token. Please try again.');
      }

      // Validate the ID token with your backend
      final AuthSession session = await authUseCase.validateGoogleToken(idToken);
      _signedInUser = session.user ??
          User(
            email: user.email,
            name: user.displayName,
          );

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

  Future<void> signInWithGithub() async {
    _isSigningIn = false;
    _errorMessage = null;
    _signedInUser = null;
    _githubUserCode = null;
    _githubVerificationUri = null;
    _cancelGithubSignIn = false;
    notifyListeners();

    if (GITHUB_CLIENT_ID.isEmpty) {
      _errorMessage = 'Missing GITHUB_CLIENT_ID in .env';
      notifyListeners();
      return;
    }

    try {
      // Device Flow:
      // 1) Request device_code + user_code
      final deviceResp = await _githubRequestDeviceCode();
      final verificationUri = (deviceResp['verification_uri_complete'] ??
              deviceResp['verification_uri'])
          ?.toString();
      final userCode = deviceResp['user_code']?.toString();
      final deviceCode = deviceResp['device_code']?.toString();
      final int expiresIn =
          (deviceResp['expires_in'] is int) ? deviceResp['expires_in'] as int : 900;
      int interval =
          (deviceResp['interval'] is int) ? deviceResp['interval'] as int : 5;

      if (verificationUri == null ||
          userCode == null ||
          deviceCode == null ||
          verificationUri.isEmpty ||
          userCode.isEmpty ||
          deviceCode.isEmpty) {
        throw Exception('Invalid GitHub device flow response');
      }

      _githubUserCode = userCode;
      _githubVerificationUri = verificationUri;
      notifyListeners();

      // Open verification page in external browser; user enters userCode (or URL may be prefilled).
      await launchUrl(
        Uri.parse(verificationUri),
        mode: LaunchMode.externalApplication,
      );

      // 2) Poll until we get access_token or errors.
      final accessToken = await _githubPollAccessToken(
        deviceCode: deviceCode,
        expiresInSeconds: expiresIn,
        intervalSeconds: interval,
      );

      // 3) Exchange access token with backend to get our session token.
      final AuthSession session =
          await authUseCase.validateGithubAccessToken(accessToken);
      _signedInUser = session.user;

      _isSigningIn = true;
    } catch (error) {
      print('Error during GitHub OAuth: $error');
      _errorMessage = error.toString();
    } finally {
      _githubUserCode = null;
      _githubVerificationUri = null;
      notifyListeners();
    }
  }

  Future<void> signInWithMicrosoft() async {
    _isSigningIn = false;
    _errorMessage = null;
    _signedInUser = null;
    notifyListeners();

    if (MICROSOFT_CLIENT_ID.isEmpty) {
      _errorMessage = 'Missing MICROSOFT_CLIENT_ID in .env';
      notifyListeners();
      return;
    }

    try {
      final pca = await SingleAccountPca.create(
        clientId: MICROSOFT_CLIENT_ID,
        androidConfig: AndroidConfig(
          configFilePath: MICROSOFT_MSAL_CONFIG_PATH,
          redirectUri: MICROSOFT_ANDROID_REDIRECT_URI,
        ),
        appleConfig: AppleConfig(
          authorityType: AuthorityType.aad,
          broker: Broker.msAuthenticator,
        ),
      );

      final result = await pca.acquireToken(
        scopes: MICROSOFT_SCOPE_LIST.isEmpty
            ? <String>['User.Read']
            : MICROSOFT_SCOPE_LIST,
        prompt: Prompt.whenRequired,
        authority: MICROSOFT_AUTHORITY.isEmpty ? null : MICROSOFT_AUTHORITY,
      );

      final accessToken = result.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Microsoft login did not return an access token');
      }

      final AuthSession session =
          await authUseCase.validateMicrosoftAccessToken(accessToken);
      _signedInUser = session.user;
      _isSigningIn = true;
    } on MsalException catch (e) {
      print('MSAL error during Microsoft Sign-In: $e');
      _errorMessage = e.toString();
    } catch (e) {
      print('Error during Microsoft Sign-In: $e');
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _githubRequestDeviceCode() async {
    // GitHub expects application/x-www-form-urlencoded and Accept: application/json.
    final uri = Uri.parse(_githubDeviceCodeUrl);
    final response = await httpPostForm(uri, {
      'client_id': GITHUB_CLIENT_ID,
      'scope': GITHUB_SCOPE,
    });
    return response;
  }

  Future<String> _githubPollAccessToken({
    required String deviceCode,
    required int expiresInSeconds,
    required int intervalSeconds,
  }) async {
    final deadline =
        DateTime.now().add(Duration(seconds: expiresInSeconds));
    var interval = intervalSeconds;

    while (DateTime.now().isBefore(deadline)) {
      if (_cancelGithubSignIn) {
        throw Exception('GitHub sign-in cancelled');
      }
      final uri = Uri.parse(_githubAccessTokenUrl);
      final resp = await httpPostForm(uri, {
        'client_id': GITHUB_CLIENT_ID,
        'device_code': deviceCode,
        'grant_type': _githubDeviceGrantType,
      });

      final error = resp['error']?.toString();
      if (error == null || error.isEmpty) {
        final token = resp['access_token']?.toString();
        if (token != null && token.isNotEmpty) return token;
        throw Exception('Missing access_token from GitHub');
      }

      switch (error) {
        case 'authorization_pending':
          break;
        case 'slow_down':
          interval += 5;
          break;
        case 'access_denied':
          throw Exception('GitHub authorization denied');
        case 'expired_token':
          throw Exception('GitHub device code expired');
        case 'device_flow_disabled':
          throw Exception('GitHub device flow is disabled for this OAuth app');
        default:
          throw Exception('GitHub device flow error: $error');
      }

      await Future.delayed(Duration(seconds: interval));
    }

    throw Exception('GitHub device flow timed out');
  }

  // Minimal helper to avoid adding a new dependency in app layer.
  // Uses url_launcher import already present; actual HTTP client lives in data layer,
  // but for GitHub device flow we perform direct calls here.
  Future<Map<String, dynamic>> httpPostForm(
    Uri uri,
    Map<String, String> body,
  ) async {
    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'GitHub request failed: ${response.statusCode} ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected GitHub response: ${response.body}');
  }

  // Function to handle Google Sign-Out

  Future<void> syncUser(
      String? displayName, String email, String? photoUrl) async {
    final accessToken =
        await authUseCase.syncUser(displayName, email, photoUrl);
  }

  Future<void> signInWithApple() async {
    _isSigningIn = false;
    _errorMessage = null;
    _signedInUser = null;
    notifyListeners();

    try {
      final credential = await appleSignInService.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Web options are required on web; safe to provide here for parity.
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: kIsWeb ? 'com.example.swiftcompsignin' : 'com.cdmHUB.SwiftComp',
          redirectUri: kIsWeb
              ? Uri.parse('https://compositesai.com')
              : Uri.parse(
                  'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
                ),
        ),
      );

      print('Apple credential: $credential');

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Identity token not available in Apple credentials');
      }

      final email = credential.email;
      final displayName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s!.trim().isNotEmpty).map((s) => s!.trim()).join(' ');

      final AuthSession session = await authUseCase.validateAppleToken(
        identityToken,
        email: email,
        displayName: displayName.isEmpty ? null : displayName,
      );

      _signedInUser = session.user ??
          User(
            email: email ?? '',
            name: displayName.isEmpty ? null : displayName,
          );
      _isSigningIn = true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _errorMessage = 'Sign-in was canceled by the user.';
      } else {
        _errorMessage = 'Sign in with Apple failed: $e';
      }
      _isSigningIn = false;
    } catch (e) {
      _errorMessage = 'Sign in with Apple failed: $e';
      _isSigningIn = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithLinkedin() async {
    _isSigningIn = false;
    _errorMessage = null;
    try {
      final Uri authUri = await authUseCase.getAuthUrl();
      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.inAppWebView);
      } else {
        throw Exception("Could not launch LinkedIn login page");
      }
    } catch (error) {
      throw Exception("LinkedIn Sign-In Failed: $error");
    }
  }
}
