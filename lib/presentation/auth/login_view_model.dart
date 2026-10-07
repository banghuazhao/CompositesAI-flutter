// lib/presentation/viewmodels/login_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';
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
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _githubAttempt?.cancel();
    super.dispose();
  }

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

  _GithubSignInAttempt? _githubAttempt;
  bool get isGithubFinalizing => _githubAttempt?.isFinalizing ?? false;

  void cancelGithubSignIn() {
    // Once the backend exchange starts it commits the session token.
    // The dialog also disables cancellation while this short step finishes.
    if (!isGithubFinalizing) _githubAttempt?.cancel();
  }

  void _checkGithubAttempt(_GithubSignInAttempt attempt) {
    if (_disposed || attempt.isCancelled || _githubAttempt != attempt) {
      throw const _GithubSignInCancelledException();
    }
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
      return user;
    } catch (e) {
      _errorMessage = _friendlyError(e, passwordLogin: true);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Maps raw exceptions to user-readable strings.
  static String _friendlyError(Object error,
      {String fallback = 'Something went wrong. Please try again.',
      bool passwordLogin = false}) {
    // Strip class-name prefixes: "BadRequestException: …", "Exception: …", etc.
    var msg =
        error.toString().replaceFirst(RegExp(r'^\w*Exception:\s*'), '').trim();
    final lower = msg.toLowerCase();
    if (error is MsalException &&
        (lower.contains('redirect_uri') || lower.contains('intent_filter'))) {
      return MicrosoftSignInConfigurationException.userMessage;
    }
    if (passwordLogin &&
        (lower.contains('401') ||
            lower.contains('invalid credentials') ||
            lower.contains('incorrect password') ||
            lower.contains('wrong password'))) {
      return 'Incorrect email or password.';
    }
    if (passwordLogin &&
        (lower.contains('404') ||
            lower.contains('no user') ||
            lower.contains('not found'))) {
      return 'No account found with this email.';
    }
    if (lower.contains('429') || lower.contains('too many')) {
      return 'Too many attempts. Please try again later.';
    }
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('unreachable')) {
      return 'Network error. Please check your connection.';
    }
    if (error is MsalException) return fallback;
    return msg.isEmpty ? fallback : msg;
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
  static const String _githubDeviceCodeUrl =
      'https://github.com/login/device/code';
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
    _errorMessage = null;
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

      if (user == null) {
        // User cancelled — stay silent, no error shown
        return;
      }

      // For non-web platforms, retrieve authentication details
      final idToken = user.idToken;

      // Ensure ID token is present
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Unable to retrieve ID token. Please try again.');
      }

      // Validate the ID token with your backend
      final AuthSession session =
          await authUseCase.validateGoogleToken(idToken);
      _signedInUser = session.user ??
          User(
            email: user.email,
            name: user.displayName,
          );

      // Mark signing-in as successful
      _isSigningIn = true;
    } catch (error) {
      debugPrint('Google sign-in failed.');
      final message = error.toString().toLowerCase();
      _errorMessage = message.contains('invalid credentials') ||
              message.contains('email or password provided is incorrect') ||
              message.contains('invalid_cred')
          ? 'Google sign-in could not be completed. Please try again.'
          : _friendlyError(error);
    } finally {
      // Notify listeners regardless of success or failure
      notifyListeners();
    }
  }

  Future<void> signInWithGithub() async {
    if (_disposed || isGithubFinalizing) return;
    _githubAttempt?.cancel();
    final attempt = _GithubSignInAttempt();
    _githubAttempt = attempt;
    _isSigningIn = false;
    _errorMessage = null;
    _signedInUser = null;
    _githubUserCode = null;
    _githubVerificationUri = null;
    notifyListeners();

    if (GITHUB_CLIENT_ID.isEmpty) {
      _errorMessage =
          'GitHub sign-in is temporarily unavailable. Please use email or another sign-in option.';
      _githubAttempt = null;
      notifyListeners();
      return;
    }

    try {
      // Device Flow:
      // 1) Request device_code + user_code
      final deviceResp = await _githubRequestDeviceCode();
      _checkGithubAttempt(attempt);
      final verificationUri = (deviceResp['verification_uri_complete'] ??
              deviceResp['verification_uri'])
          ?.toString();
      final userCode = deviceResp['user_code']?.toString();
      final deviceCode = deviceResp['device_code']?.toString();
      final int expiresIn = (deviceResp['expires_in'] is int)
          ? deviceResp['expires_in'] as int
          : 900;
      int interval =
          (deviceResp['interval'] is int) ? deviceResp['interval'] as int : 5;

      if (verificationUri == null ||
          userCode == null ||
          deviceCode == null ||
          verificationUri.isEmpty ||
          userCode.isEmpty ||
          deviceCode.isEmpty) {
        throw Exception(
            'GitHub sign-in could not be completed. Please try again.');
      }

      _githubUserCode = userCode;
      _githubVerificationUri = verificationUri;
      notifyListeners();

      // Open verification page in external browser; user enters userCode (or URL may be prefilled).
      await launchUrl(
        Uri.parse(verificationUri),
        mode: LaunchMode.externalApplication,
      );
      _checkGithubAttempt(attempt);

      // 2) Poll until we get access_token or errors.
      final accessToken = await _githubPollAccessToken(
        deviceCode: deviceCode,
        expiresInSeconds: expiresIn,
        intervalSeconds: interval,
        attempt: attempt,
      );
      _checkGithubAttempt(attempt);

      // 3) Exchange access token with backend to get our session token.
      attempt.isFinalizing = true;
      notifyListeners();
      final AuthSession session =
          await authUseCase.validateGithubAccessToken(accessToken);
      _checkGithubAttempt(attempt);
      _signedInUser = session.user;

      _isSigningIn = true;
    } on _GithubSignInCancelledException {
      // Closing a dialog or starting another attempt must not complete this one.
    } catch (error) {
      if (!_disposed && _githubAttempt == attempt && !attempt.isCancelled) {
        debugPrint('GitHub sign-in failed.');
        _errorMessage = _friendlyError(error);
      }
    } finally {
      if (_githubAttempt == attempt) {
        _githubAttempt = null;
        _githubUserCode = null;
        _githubVerificationUri = null;
        notifyListeners();
      }
    }
  }

  Future<void> signInWithMicrosoft() async {
    _isSigningIn = false;
    _errorMessage = null;
    _signedInUser = null;
    notifyListeners();

    if (MICROSOFT_CLIENT_ID.isEmpty) {
      _errorMessage = MicrosoftSignInConfigurationException.userMessage;
      notifyListeners();
      return;
    }

    try {
      final redirectUri =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? await MicrosoftAndroidRedirectService().getRedirectUri()
              : MICROSOFT_ANDROID_REDIRECT_URI;
      final pca = await SingleAccountPca.create(
        clientId: MICROSOFT_CLIENT_ID,
        androidConfig: AndroidConfig(
          configFilePath: MICROSOFT_MSAL_CONFIG_PATH,
          redirectUri: redirectUri,
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
    } on MsalUserCancelException {
      // Closing the Microsoft sign-in window is not an error.
    } on MicrosoftSignInConfigurationException {
      _errorMessage = MicrosoftSignInConfigurationException.userMessage;
    } on MsalException catch (e) {
      debugPrint('Microsoft sign-in failed.');
      _errorMessage = _friendlyError(e,
          fallback:
              'Microsoft sign-in failed. Please try again or use email and password.');
    } catch (_) {
      debugPrint('Microsoft sign-in failed.');
      _errorMessage =
          'Microsoft sign-in failed. Please try again or use email and password.';
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
    required _GithubSignInAttempt attempt,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: expiresInSeconds));
    var interval = intervalSeconds;

    while (DateTime.now().isBefore(deadline)) {
      _checkGithubAttempt(attempt);
      final uri = Uri.parse(_githubAccessTokenUrl);
      final resp = await httpPostForm(uri, {
        'client_id': GITHUB_CLIENT_ID,
        'device_code': deviceCode,
        'grant_type': _githubDeviceGrantType,
      });
      _checkGithubAttempt(attempt);

      final error = resp['error']?.toString();
      if (error == null || error.isEmpty) {
        final token = resp['access_token']?.toString();
        if (token != null && token.isNotEmpty) return token;
        throw Exception(
            'GitHub sign-in could not be completed. Please try again.');
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
          throw Exception(
              'GitHub sign-in is temporarily unavailable. Please use another sign-in option.');
        default:
          throw Exception(
              'GitHub sign-in could not be completed. Please try again.');
      }

      await attempt.wait(Duration(seconds: interval));
      _checkGithubAttempt(attempt);
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
      if (response.statusCode == 429) {
        throw Exception('Too many attempts. Please try again later.');
      }
      throw Exception(
          'GitHub sign-in is temporarily unavailable. Please try again later.');
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // A proxy or upstream error response can contain private diagnostics.
    }
    throw Exception('GitHub sign-in could not be completed. Please try again.');
  }

  // Function to handle Google Sign-Out

  Future<void> syncUser(
      String? displayName, String email, String? photoUrl) async {
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
          clientId:
              kIsWeb ? 'com.example.swiftcompsignin' : 'com.cdmHUB.SwiftComp',
          redirectUri: kIsWeb
              ? Uri.parse('https://compositesai.com')
              : Uri.parse(
                  'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
                ),
        ),
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Identity token not available in Apple credentials');
      }

      final email = credential.email;
      final displayName = [
        credential.givenName,
        credential.familyName,
      ]
          .where((s) => s != null && s.trim().isNotEmpty)
          .map((s) => s!.trim())
          .join(' ');

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
      if (e.code != AuthorizationErrorCode.canceled) {
        _errorMessage = _friendlyError(e);
      }
      // Cancellation stays silent (_errorMessage remains null)
      _isSigningIn = false;
    } catch (e) {
      _errorMessage = _friendlyError(e);
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

class _GithubSignInCancelledException implements Exception {
  const _GithubSignInCancelledException();
}

class _GithubSignInAttempt {
  bool isCancelled = false;
  bool isFinalizing = false;
  Timer? _timer;
  Completer<void>? _waiter;

  Future<void> wait(Duration duration) {
    if (isCancelled) return Future<void>.value();
    final waiter = Completer<void>();
    _waiter = waiter;
    _timer = Timer(duration, () {
      _timer = null;
      _waiter = null;
      waiter.complete();
    });
    return waiter.future;
  }

  void cancel() {
    isCancelled = true;
    _timer?.cancel();
    _timer = null;
    _waiter?.complete();
    _waiter = null;
  }
}
