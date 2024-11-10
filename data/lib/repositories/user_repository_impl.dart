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

    // No need to add Authorization header; AuthenticatedHttpClient handles it
    final response = await authClient.get(url, headers: {
      'Content-Type': 'application/json',
    });

    // Check the response status and handle accordingly
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized request. Please log in again.');
    } else {
      throw Exception('Failed to fetch user data. Status code: ${response.statusCode}');
    }
  }


  @override
  Future<void> updateMe(String newName) async {
    try {
      final response = await authClient.patch(
        Uri.parse('http://localhost:3000/api/users/me'), // Adjust URL as necessary
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': newName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update name. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating name: $error');
      throw Exception('Error updating name: $error');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final url = Uri.parse('http://localhost:3000/api/users/me');
    final response = await authClient.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account. Status code: ${response.statusCode}');
    }
  }
}
