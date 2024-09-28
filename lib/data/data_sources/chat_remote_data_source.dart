import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/message.dart';
import '../core/api_constants.dart';
import '../core/network_exceptions.dart';

abstract class ChatRemoteDataSource {
  Stream<String> sendMessages(List<Message> messages);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client client;

  ChatRemoteDataSourceImpl({required this.client});

  @override
  Stream<String> sendMessages(List<Message> messages) async* {
    final request = http.Request('POST', Uri.parse(ApiConstants.chatEndpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
      })
      ..body = jsonEncode({
        "model": "gpt-4o",
        "stream": true,
        'messages': messages,
      });

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
              final content = data['choices'][0]['delta']['content'] ?? '';
              if (content.isNotEmpty) {
                yield content;
              }
            } catch (_) {
              // Handle JSON parsing errors
              continue;
            }
          }
        }
      }
    } else {
      throw NetworkException('Failed to send message: ${response.statusCode}');
    }
  }
}
