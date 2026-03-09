import 'dart:convert';

import 'package:data/chat/message_delta_dto.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

import '../mappers/domain_exception_mapper.dart';
import '../utils/sse_stream.dart';

class ChatRepositoryImpl implements ChatRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;
  final TokenProvider tokenProvider;

  ChatRepositoryImpl(
      {required this.authClient,
      required this.apiEnvironment,
      required this.tokenProvider});

  @override
  Future<List<Chat>> fetchChats() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/all');
    final response = await authClient.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is! List) {
        throw mapServerErrorToDomainException(response);
      }
      final chats = (data).map((json) => Chat.fromJson(json)).toList();
      return chats;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}');
    final response = await authClient
        .get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decoded);
      final List<dynamic> messagesJson = data["chat"]["messages"];
      final messages =
          messagesJson.map((json) => Message.fromJson(json)).toList();
      return messages;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> deleteChat(Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}');
    final response = await authClient.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<Chat> updateChatTitle(Chat chat, String newTitle) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat': {'title': newTitle}
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return Chat.fromJson(data);
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<Chat> togglePin(Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}/pin');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return Chat.fromJson(data);
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  Stream<String> sendMessages(List<Message> messages, Chat chat) async* {
    final accessToken = await tokenProvider.getToken();
    final url = Uri.parse('https://compositesai.com/api/chat/completions');
    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      })
      ..body = jsonEncode({
        "model": "gpt-4.1",
        "stream": true,
        "chat_id": chat.id,
        'messages': messages.map((message) {
          return {
            'role': message.role,
            'content': message.content,
          };
        }).toList()
      });

    final stream = await getStream(request);

    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      final jsonString = line.replaceFirst('data: ', '').trim();

      if (jsonString.isEmpty) continue;

      if (jsonString == '[DONE]') return;

      final data = jsonDecode(jsonString);

      final messageDelta = MessageDeltaDTO.fromJson(data);

      final content = messageDelta.choice.delta.content;
      if (content != null) {
        yield content;
      }
    }
  }
}
