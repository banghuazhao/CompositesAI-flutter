// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:data/mappers/domain_exception_mapper.dart';
import 'package:domain/entities/domain_exceptions.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/api_env_repository.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:http/http.dart' as http;

import '../data_sources/authenticated_http_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;
  final AuthenticatedHttpClient authClient;
  final APIEnvironmentRepository apiEnvironmentRepository;

  AuthRepositoryImpl(
      {required this.client, required this.authClient, required this.apiEnvironmentRepository});

  @override
  Future<User> signup(String email, String password, String verificationCode,
      {String? name}) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
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
  Future<String> login(String email, String password) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/login');
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
      return data['accessToken']; // Return access token on success
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> logout() async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/logout');

    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  Future<void> forgetPassword(String email) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
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

  Future<String> resetPassword(String email, String newPassword, String confirmationCode) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/reset-password');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {"email": email, 'password': newPassword, "confirmationCode": confirmationCode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  Future<void> sendSignupVerificationCode(String email) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
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

  Future<String> updatePassword(String newPassword) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
    final url = Uri.parse('$baseURL/auth/update-password');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  Future<String> syncUser(String? displayName, String email, String? photoUrl) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
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
        return accessToken; // Return the access token
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
  Future<String> validateAppleToken(String identityToken) async {
    final baseURL = await apiEnvironmentRepository.getBaseUrl();
    final url =
    Uri.parse('http://localhost:8080/api/auth/sign_in_with_apple');
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'identityToken': identityToken,
      }),
    );
    if (response.statusCode != 200) {
      print('Token validation failed: ${response.body}');
      throw Exception('Failed to validate token with backend');
    }
    final responseJson = jsonDecode(response.body);

    // Extract email from the payload
    final String? email = responseJson["payload"]?["email"]; // Safely access payload

    if (email == null || email.isEmpty) {
      throw Exception('Validation failed: email not retrieved from token');
    }
    return email;
  }
}
