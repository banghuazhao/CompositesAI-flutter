import 'dart:convert';
import 'dart:io';

import 'package:domain/entities/assistant_message.dart';
import 'package:domain/entities/message.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/repositories_abstract/messages_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class MessagesRepositoryImp implements MessagesRepository {
  final http.Client client;

  MessagesRepositoryImp({required this.client});

  @override
  Future<AssistantMessage> createMessage(Thread thread, Message message) async {
    final request = http.Request('POST',
        Uri.parse(ApiConstants.threadsEndpoint + "/${thread.id}/messages"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "role": "user",
        "content": message.content,
      });

    // 2. Send the request
    final http.StreamedResponse streamedResponse = await client.send(request);
    final String responseBody = await streamedResponse.stream.bytesToString();

    // 3. Handle success or throw an error
    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      return AssistantMessage.fromJson(jsonResponse);
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
}
