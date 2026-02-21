// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:data/mappers/domain_exception_mapper.dart';
import 'package:domain/entities/domain_exceptions.dart';
import 'package:domain/entities/linkedin_user_profile.dart';
import 'package:domain/entities/auth_session.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infrastructure/token_provider.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;
  final TokenProvider tokenProvider;

  AuthRepositoryImpl(
      {required this.client,
      required this.authClient,
      required this.apiEnvironment,
      required this.tokenProvider});

  @override
  Future<User> signup(String email, String password, String verificationCode,
      {String? name}) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/users/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          'email': email,
          'password': password,
          'verificationCode': verificationCode,
          if (name != null) 'name': name,
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return User(
        email: responseData['user']['email'],
        name: responseData['user']['name'],
      );
    } else {
      throw Exception('Failed to sign up. Status code: ${response.statusCode}');
    }
  }

  @override
  Future<User> login(String email, String password) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/signin');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['token']; // Return access token on success
      await tokenProvider.saveToken(accessToken);
      final user = User.fromJson(data);
      if (kDebugMode) {
        print(user);
      }
      return user;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> logout() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/signout');

    final response = await authClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      await tokenProvider.deleteToken();
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await tokenProvider.getToken();
    return token != null;
  }

  @override
  Future<void> forgetPassword(String email) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/forget-password');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw mapServerErrorToDomainException(response);
      }
      // If statusCode is 200, assume the request was successful
    } catch (error) {
      // Re-throw network or parsing errors as custom exceptions
      throw Exception('An error occurred. Please try again.');
    }
  }

  @override
  Future<String> resetPassword(
      String email, String newPassword, String confirmationCode) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/reset-password');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        'password': newPassword,
        "confirmationCode": confirmationCode
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> sendSignupVerificationCode(String email) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/send-verification');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      // Request was successful, exit the function
      return;
    } else if (response.statusCode == 400) {
      throw BadRequestException('Invalid email address');
    } else if (response.statusCode == 409) {
      throw ResourceAlreadyExistsException('Email is already registered');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/update/password');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': currentPassword,
        'new_password': newPassword}),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> syncUser(
      String? displayName, String email, String? photoUrl) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/sync-user');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (displayName != null) 'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // User already exists, backend returns an access token
      final accessToken = data['accessToken'];
      if (accessToken != null) {
        await tokenProvider.saveToken(accessToken);
        return;
      } else {
        throw Exception('Access token missing in response');
      }
    } else if (response.statusCode == 201) {
      // New user created, backend returns a success message
      final accessToken = data['accessToken'];
      if (accessToken != null) {
        return accessToken; // Return the access token
      } else {
        throw Exception('Access token missing in response');
      }
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<AuthSession> validateAppleToken(
    String identityToken, {
    String? email,
    String? displayName,
  }) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/oauth/apple');

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identityToken': identityToken,
          if (email != null) 'email': email,
          if (displayName != null) 'displayName': displayName,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Apple OAuth login failed: ${response.body}');
        throw Exception('Apple OAuth login failed');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final session = AuthSession.fromJson(data);
      if (session.token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await tokenProvider.saveToken(session.token);
      print('Apple OAuth login succeeded');
      return session;
    } catch (e) {
      print('Error during Apple OAuth login: $e');
      throw Exception('Failed to login with Apple');
    }
  }

  @override
  Future<AuthSession> validateGoogleToken(String idToken) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    // Backend expects: POST /api/v1/auths/oauth/google with { idToken }
    final url = Uri.parse('$baseURL/auths/oauth/google');

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Token validation failed: ${response.body}');
        throw Exception('Google token validation failed');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final session = AuthSession.fromJson(data);
      if (session.token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await tokenProvider.saveToken(session.token);
      print('Google OAuth login succeeded');
      return session;
    } catch (e) {
      print('Error during token validation: $e');
      throw Exception('Failed to validate token');
    }
  }

  @override
  Future<AuthSession> validateGithubAccessToken(String accessToken) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/oauth/github');

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('GitHub OAuth login failed: ${response.body}');
        throw Exception('GitHub OAuth login failed');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final session = AuthSession.fromJson(data);
      if (session.token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await tokenProvider.saveToken(session.token);
      print('GitHub OAuth login succeeded');
      return session;
    } catch (e) {
      print('Error during GitHub OAuth login: $e');
      throw Exception('Failed to login with GitHub');
    }
  }

  @override
  Future<AuthSession> validateMicrosoftAccessToken(String accessToken) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/auths/oauth/microsoft');

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Microsoft OAuth login failed: ${response.body}');
        throw Exception('Microsoft OAuth login failed');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final session = AuthSession.fromJson(data);
      if (session.token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await tokenProvider.saveToken(session.token);
      print('Microsoft OAuth login succeeded');
      return session;
    } catch (e) {
      print('Error during Microsoft OAuth login: $e');
      throw Exception('Failed to login with Microsoft');
    }
  }

  @override
  Future<String> handleAuthorizationCodeFromLinked(
      String? authorizationCode) async {
    //Sends the authorizationCode to your backend API. then backend process it and Sends the access token back to the frontend.
    if (authorizationCode == null) {
      throw Exception("Failed to get authorization code from LinkedIn.");
    }

    final baseURL = await apiEnvironment.getBaseUrl();
    print(baseURL);
    // **Step 3: Send the authorizationCode to the backend handler
    final response = await client.post(
      Uri.parse('$baseURL/auth/handle_authorization'), // Send to backend
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authorizationCode': authorizationCode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data["accessToken"];
      return accessToken;
    } else {
      throw Exception("Failed to get access token: ${response.body}");
    }
  }

  @override
  Future<LinkedinUserProfile> fetchLinkedInUserProfile(
      String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Access token is required to fetch LinkedIn profile.");
    }

    final baseURL = await apiEnvironment.getBaseUrl();
    print("fetchLinkedInUserProfile URL: $baseURL");

    final response = await http.post(
      Uri.parse('$baseURL/auth/linkedin-profile'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"accessToken": accessToken}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (!data.containsKey('user') || data['user'] == null) {
        throw Exception("Invalid response: Missing 'user' data.");
      }
      return LinkedinUserProfile.fromJson(data['user']);
    } else {
      throw Exception(response.statusCode);
    }
  }

  @override
  Future<Uri> getAuthUrl() async {
    final String clientId = dotenv.env['LINKEDIN_CLIENT_ID'] ?? '';
    print("LinkedIn Client ID: " + clientId);
    const String redirectUrlWeb =
        'https://compositesai.com/auth/linkedin/callback';
    const String redirectUrlMobile = 'https://compositesai.com/linkedin-auth';
    const String redirectUrlDevelopment =
        'http://localhost:5000/auth/linkedin/callback';

    final String currentEnv = await apiEnvironment.getCurrentEnvironment();
    final String redirectUrl;
    if (currentEnv == 'production') {
      redirectUrl = kIsWeb ? redirectUrlWeb : redirectUrlMobile;
    } else {
      redirectUrl = redirectUrlDevelopment;
    }
    return Uri.parse('https://www.linkedin.com/oauth/v2/authorization'
        '?response_type=code'
        '&client_id=$clientId'
        '&scope=openid%20profile%20email'
        '&redirect_uri=$redirectUrl');
  }
}
