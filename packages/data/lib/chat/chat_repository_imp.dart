import 'dart:convert';

import 'package:data/chat/message_delta_dto.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/chat/entities/feedback_response.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

import '../mappers/domain_exception_mapper.dart';
import '../utils/sse_stream.dart';

/// Main chat list: `GET {base}/chats/` (trailing slash matters on some servers).
String _unpinnedChatsListUri(String baseURL, {int? page}) {
  final base = baseURL.endsWith('/')
      ? baseURL.substring(0, baseURL.length - 1)
      : baseURL;
  final root = Uri.parse('$base/chats/');
  if (page == null) return root.toString();
  return root.replace(queryParameters: {'page': '$page'}).toString();
}

class ChatRepositoryImpl implements ChatRepository {
  final AuthenticatedHttpClient authClient;
  final APIEnvironment apiEnvironment;
  final TokenProvider tokenProvider;

  ChatRepositoryImpl(
      {required this.authClient,
      required this.apiEnvironment,
      required this.tokenProvider});

  @override
  Future<List<Chat>> fetchChats({int? page}) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse(_unpinnedChatsListUri(baseURL, page: page));
    final response = await authClient.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes).trimLeft();
      if (decoded.startsWith('<') || decoded.startsWith('<!')) {
        throw FormatException(
          'GET /chats/ returned HTML, not JSON. '
          'Check base URL and path (use /chats/ with trailing slash).',
        );
      }
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
  Future<bool> fetchChatPinned(String chatId) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/$chatId/pinned');
    final response = await authClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is bool) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        final v = data['pinned'] ?? data['is_pinned'];
        if (v is bool) return v;
        if (v == true || v == 1) return true;
        if (v == false || v == 0) return false;
      }
      throw FormatException('Unexpected /chats/.../pinned response shape');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<Chat>> fetchPinnedChats() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/pinned');
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
      return (data).map((json) => Chat.fromJson(json)).toList();
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
  Future<Chat> createChat(Message message) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/new');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat': {
          'id': "",
          'title': message.content,
          'models': ["composites-ai-2026-02-23"],
          'history': {'messages': message.toHistoryJson()},
          'messages': [message.toJson()]
        }
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final chat = Chat.fromJson(data);
      return chat;
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
    // Toggle: no body; server updates pinned state.
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        return chat;
      }
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return Chat.fromJson(data);
      }
      return chat;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<String> shareChat(Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}/share');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final item = Chat.fromJson(data);
      final webBaseUrl = await apiEnvironment.getWebBaseUrl();
      final shareLink = '$webBaseUrl/s/${item.id}';
      return shareLink;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Stream<String> sendMessages(
      List<Message> messages, Chat chat, String id) async* {
    final accessToken = await tokenProvider.getToken();
    final url = Uri.parse('https://compositesai.com/api/chat/completions');
    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      })
      ..body = jsonEncode({
        "model": "composites-ai-2026-02-23",
        "stream": true,
        "chat_id": chat.id,
        "id": id,
        "tool_ids": [
          // "laminate_analysis",
          // "ann_based_woven_analysis",
          // "cylindrical_bending_api",
          // "a2",
          // "a1",
          // "dev_composites_knowledge_retrieval",
          // "cs_analysis_assistant_dev"
        ],
        'features': {
          'image_generation': false,
          'code_interpreter': false,
          'web_search': false
        },
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

  @override
  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id) async {
    final url = Uri.parse('https://compositesai.com/api/chat/completed');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_id': chat.id,
        'id': id,
        'model': "composites-ai-2026-02-23",
        'messages': messages.map((m) => m.toCompletedJson()).toList(),
        'model_item': {
          'id': "composites-ai-2026-02-23",
          'object': "model",
          'created': 1744316542,
          'owned_by': "openai",
          'name': "CompositesAI",
          'tags': []
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> persistMessages(List<Message> messages, Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}');
    final response = await authClient.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat': {
            'id': chat.id,
            'title': chat.title,
            'models': ["composites-ai-2026-02-23"],
            'files': [],
            'params': {},
            'history': {
              'currentId': messages.last.id,
              'messages': {for (var m in messages) m.id: m.toJson()}
            },
            'messages': messages.map((m) => m.toJson()).toList(),
            'timestamp': DateTime.now().microsecondsSinceEpoch
          },
          'created_at': chat.createdAt,
          'updated_at': chat.updatedAt,
          'dismissed_at': null
        }));

    if (response.statusCode == 200) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> updateChatMessage(Message message, Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}/messages/${message.id}');
    final response = await authClient.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': message.content
        }));

    if (response.statusCode == 200) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchChatSnapshot(String chatId) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/$chatId');
    final response = await authClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw FormatException('Unexpected chat snapshot format');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<FeedbackResponse> createFeedback(
      Map<String, dynamic> feedbackForm) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/evaluations/feedback');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(feedbackForm),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      if (response.bodyBytes.isEmpty) {
        throw Exception('Feedback create returned empty body.');
      }
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return FeedbackResponse.fromJson(data);
      }
      throw FormatException('Unexpected feedback format');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<FeedbackResponse> updateFeedback(
      String feedbackId, Map<String, dynamic> feedbackForm) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/evaluations/feedback/$feedbackId');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(feedbackForm),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      if (response.bodyBytes.isEmpty) {
        throw Exception('Feedback update returned empty body.');
      }
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return FeedbackResponse.fromJson(data);
      }
      throw FormatException('Unexpected feedback format');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }
}
