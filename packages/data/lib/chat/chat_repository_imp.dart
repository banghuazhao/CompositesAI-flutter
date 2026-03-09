import 'dart:convert';

import 'package:domain/chat/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/entities/chat/message.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';

import '../mappers/domain_exception_mapper.dart';

class ChatRepositoryImpl implements ChatRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;

  ChatRepositoryImpl({required this.authClient, required this.apiEnvironment});

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
    final response = await authClient.get(
        url,
        headers: {'Content-Type': 'application/json'}
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decoded);
      final List<dynamic> messagesJson = data["chat"]["messages"];
      final messages = messagesJson.map((json) => Message.fromJson(json)).toList();
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
      body: jsonEncode({'chat': {'title': newTitle}}),
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
}
