// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../data_sources/authenticated_http_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;
  final AuthenticatedHttpClient authClient;

  AuthRepositoryImpl({required this.client, required this.authClient});

  @override
  Future<User> signup(String username, String email, String password) async {
    final url = Uri.parse('http://localhost:3000/api/users/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User(username: username, email: email);
    } else {
      throw Exception('Failed to sign up. Status code: ${response.statusCode}');
    }
  }

  @override
  Future<String> login(String username, String password) async {
    final url = Uri.parse('http://localhost:3000/api/auth/login');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['accessToken']; // Return access token on success
    } else {
      throw Exception('Login failed');
    }
  }

  @override
  Future<void> logout() async {
    final url = Uri.parse('http://localhost:3000/api/auth/logout');

    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return;
    } else {
      // Handle error responses
      throw ServerException(
          'Logout failed with status code: ${response.statusCode}');
    }
  }
}
