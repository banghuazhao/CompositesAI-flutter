import 'dart:convert';
import 'dart:io';

import 'package:domain/entities/assistant.dart';
import 'package:http/http.dart' as http;

import 'package:domain/repositories_abstract/assistants_repository.dart';

import '../utils/api_constants.dart';

class AssistantsRepositoryImp implements AssistantsRepository {
  final http.Client client;

  AssistantsRepositoryImp(
      {required this.client});

  @override
  Future<Assistant> createCompositeAssistant() async {
    final request =
        http.Request('POST', Uri.parse(ApiConstants.assistantsEndpoint))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.apiKey}',
            'OpenAI-Beta': 'assistants=v2',
          })
          ..body = jsonEncode({
            "model": "gpt-4o",
            "name": "Composites AI",
            'description':
                "You are an expert in composite materials and structures. Please answer questions related to composites simulation, design and manufacturing."
          });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return Assistant.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to create assistant. '
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }
  
  @override
  String getCompositeAssistantId() {
    return "asst_pxUDI3A9Q8afCqT9cqgUkWQP";
  }
}
