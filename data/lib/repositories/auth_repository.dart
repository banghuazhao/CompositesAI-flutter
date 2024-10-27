// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:http/http.dart' as http;

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;

  AuthRepositoryImpl({required this.client});

  @override
  Future<User> signup(String email, String password) async {
    final url = Uri.parse('http://localhost:3000/api/users/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User(email: email);
    } else {
      throw Exception('Failed to sign up. Status code: ${response.statusCode}');
    }
  }

  @override
  Future<String> login(String email, String password) async {
    final url = Uri.parse('http://localhost:3000/api/auth/login');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['accessToken']; // Return access token on success
    } else {
      throw Exception('Login failed');
    }
  }
}
