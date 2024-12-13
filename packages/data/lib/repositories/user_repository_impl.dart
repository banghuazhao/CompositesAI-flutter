// lib/data/repositories/signup_repository_impl.dart

import 'dart:convert';

import 'package:domain/entities/user.dart';
import 'package:domain/repositories_abstract/user_repository.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';

import '../mappers/domain_exception_mapper.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;

  UserRepositoryImpl({required this.authClient, required this.apiEnvironment});

  @override
  Future<User> fetchMe() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/users/me');
    //convert plain url(string) to Uri object
    // No need to add Authorization header; AuthenticatedHttpClient handles it
    final response = await authClient.get(url, headers: {
      'Content-Type': 'application/json',
    });

    // Check the response status and handle accordingly
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(User.fromJson(data));
      return User.fromJson(data);

    } else {
      throw mapServerErrorToDomainException(response);
    }
  }


  @override
  Future<void> updateMe(String newName) async {
    final baseURL = await apiEnvironment.getBaseUrl();

    final response = await authClient.patch(
      Uri.parse('$baseURL/users/me'), // Adjust URL as necessary
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': newName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update name. Status code: ${response.statusCode}');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/users/me');
    final response = await authClient.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account. Status code: ${response.statusCode}');
    }
    return;
  }

  @override
  Future<String> submitApplication(String? reason) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/experts/register-expert');
    final response = await authClient.post(
        url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          if (reason != null) 'reason': reason,
        },
      ),
    );
    if (response.statusCode == 200) {
      return 'success';
    } else if (response.statusCode == 400) {
      return 'failed';
    } else {
      return 'error';
    }
  }
}
