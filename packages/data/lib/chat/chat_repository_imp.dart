import 'dart:convert';

import 'package:domain/chat/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';

import '../mappers/domain_exception_mapper.dart';

class ChatRepositoryImpl implements ChatRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;

  ChatRepositoryImpl({required this.authClient, required this.apiEnvironment});

  @override
  Future<List<Chat>> getChatList() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/');
    final response = await authClient.get(
      url,
      headers: {'Content-Type': 'application/json'}
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(decoded);
      final chats = data.map((json) => Chat.fromJson(json)).toList();
      return chats;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }
}
