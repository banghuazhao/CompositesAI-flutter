import 'dart:convert';
import 'package:domain/entities/function_tool.dart';
import 'package:domain/entities/message.dart';
import 'package:http/http.dart' as http;
import '../models/chat_chunk.dart';
import '../utils/api_constants.dart';
import '../utils/network_exceptions.dart';

abstract class OpenAIDataSource {
  Stream<ChatChunk> sendMessages(List<Message> messages, List<FunctionTool> functionTools);
}

class ChatRemoteDataSourceImpl implements OpenAIDataSource {
  final http.Client client;

  ChatRemoteDataSourceImpl({required this.client});

  @override
  Stream<ChatChunk> sendMessages(List<Message> messages,
      List<FunctionTool> functionTools) async* {
    final request = http.Request('POST', Uri.parse(ApiConstants.chatCompletionsEndpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
      })
      ..body = functionTools.isEmpty ? jsonEncode({
        "model": "gpt-4o",
        "stream": true,
        'messages': messages
      }) :
      jsonEncode({
        "model": "gpt-4o",
        "stream": true,
        'messages': messages,
        "tools": functionTools
      });

    // var prettyBody = const JsonEncoder.withIndent('  ').convert(jsonDecode(request.body));
    // print(prettyBody);

    final response = await client.send(request);

    if (response.statusCode == 200) {
      final utf8DecodedStream = response.stream.transform(utf8.decoder);
      String buffer = '';

      await for (var chunk in utf8DecodedStream) {
        buffer += chunk;
        List<String> lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (var line in lines) {
          if (line.startsWith('data:')) {
            var jsonString = line.replaceFirst('data: ', '').trim();

            if (jsonString == '[DONE]') {
              return;
            }

            try {
              final data = jsonDecode(jsonString);
              final chatChunk = ChatChunk.fromJson(data);
              yield chatChunk;
            } catch (e) {
              // Handle JSON parsing errors
              print('Error decoding chat completion JSON: $e. $jsonString');
              continue;
            }
          }
        }
      }
    } else {
      print('Failed to send message: ${response.statusCode}');
      throw NetworkException('Failed to send message: ${response.statusCode}');
    }
  }
}
