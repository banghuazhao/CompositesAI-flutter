// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/user_repository.dart';

import '../data_sources/authenticated_http_client.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthenticatedHttpClient authClient;

  UserRepositoryImpl({required this.authClient});

  @override
  Future<User> fetchMe() async {
    final url = Uri.parse('http://localhost:3000/api/users/me');
    final response = await authClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to sign up. Status code: ${response.statusCode}');
    }
  }
}
