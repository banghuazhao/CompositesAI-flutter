import 'dart:convert';
import 'dart:io';

import 'package:domain/entities/thread_message.dart';
import 'package:domain/repositories_abstract/messages_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class MessagesRepositoryImp implements MessagesRepository {
  final http.Client client;

  MessagesRepositoryImp({required this.client});

  @override
  Future<ThreadMessage> createMessage(String threadId, String message) async {
    final request = http.Request('POST',
        Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/messages"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "role": "user",
        "content": message,
      });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return ThreadMessage.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to create a message. '
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }

  @override
  Future<List<ThreadMessage>> listMessage(String threadId) async {
    final request = http.Request('GET',
        Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/messages"))
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

      final List<dynamic> data = jsonResponse['data'];

      // Map each JSON object to an AssistantMessage
      final List<ThreadMessage> messages = data
          .map((jsonItem) =>
              ThreadMessage.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

      return messages;
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to list messages.'
        'Status: ${streamedResponse.statusCode}, '
        'Response: $responseBody',
        uri: request.url,
      );
    }
  }

  @override
  Future<ThreadMessage> retrieveMessage(String threadId, String messageId) async {
    final request = http.Request('GET',
        Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/messages/$messageId"))
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

      return ThreadMessage.fromJson(jsonResponse);
    } else {
      // Provide as much detail as possible for debugging
      throw HttpException(
        'Failed to list messages.'
            'Status: ${streamedResponse.statusCode}, '
            'Response: $responseBody',
        uri: request.url,
      );
    }
  }
}
