import 'dart:convert';

import 'package:domain/entities/application.dart';
import 'package:domain/repositories_abstract/composite_expert_repository.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';

import '../mappers/domain_exception_mapper.dart';

class CompositeExpertRepositoryImpl implements CompositeExpertRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;

  CompositeExpertRepositoryImpl({required this.authClient, required this.apiEnvironment});

  @override
  Future<List<CompositeExpertRequest>> getAllApplications() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final response = await authClient.get(
      Uri.parse('$baseURL/experts/applications'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final applications = data.map((json) => CompositeExpertRequest.fromJson(json)).toList();
      return applications;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override

  Future<void> deleteApplication(int userId) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final response = await authClient.delete(
      Uri.parse('$baseURL/experts/applications/applicant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete applicant. Status code: ${response.statusCode}');
    }
    return;
  }
}


