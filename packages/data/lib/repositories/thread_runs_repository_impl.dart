import 'dart:convert';
import 'dart:io';
import 'package:domain/entities/assistant.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_message.dart';
import 'package:domain/entities/thread_run.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class ThreadRunsRepositoryImp implements ThreadRunsRepository {
  final http.Client client;

  ThreadRunsRepositoryImp({required this.client});

  @override
  Future<ThreadRun> createRun(Assistant assistant) async {
    final request =
        http.Request('POST', Uri.parse("${ApiConstants.threadsEndpoint}/runs"))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.apiKey}',
            'OpenAI-Beta': 'assistants=v2',
          })
          ..body = jsonEncode({
            "assistant_id": assistant.id,
          });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return ThreadRun.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to thread run.'
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }

  @override
  Future<ThreadRun> createMessageAndRun(
      Assistant assistant, String message) async {
    final request =
        http.Request('POST', Uri.parse("${ApiConstants.threadsEndpoint}/runs"))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.apiKey}',
            'OpenAI-Beta': 'assistants=v2',
          })
          ..body = jsonEncode({
            "assistant_id": assistant.id,
            "thread": {
              "messages": [
                {"role": "user", "content": message}
              ]
            }
          });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return ThreadRun.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to thread run.'
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }
}
