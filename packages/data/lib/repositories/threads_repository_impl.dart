import 'dart:convert';
import 'dart:io';

import 'package:domain/entities/chat/thread.dart';
import 'package:domain/repositories_abstract/threads_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class ThreadsRepositoryImpl implements ThreadsRepository {
  final http.Client client;

  ThreadsRepositoryImpl(
      {required this.client});

  @override
  Future<Thread> createThread() async {
    final request =
        http.Request('POST', Uri.parse(ApiConstants.threadsEndpoint))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.apiKey}',
            'OpenAI-Beta': 'assistants=v2',
          });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return Thread.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to create a thread. '
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }

  @override
  Future<Thread> retrieveThread(String threadId) async {
    final request =
    http.Request('POST', Uri.parse("${ApiConstants.threadsEndpoint}/$threadId"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return Thread.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to retrieve a thread. '
            'Status: ${streamedResponse.statusCode}, '
            'Response: $responseBody',
        uri: request.url,
      );
    }
  }

}
