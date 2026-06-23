import 'dart:async';
import 'dart:convert';

import 'package:data/chat/message_delta_dto.dart';
import 'package:data/chat/chat_socket_session.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/feedback_response.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

import '../mappers/domain_exception_mapper.dart';

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
      final chat = data['chat'];
      if (chat is! Map<String, dynamic>) {
        throw FormatException('GET /chats/:id: missing or invalid "chat"');
      }
      final messagesRaw = chat['messages'];
      if (messagesRaw is! List) {
        return <Message>[];
      }
      final messages = messagesRaw
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
      return messages;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<ChatTool>> fetchTools() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/tools/');
    final response = await authClient.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is! List) {
        throw FormatException('GET /tools/: expected a JSON array');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatTool.fromJson)
          .where((tool) => tool.id.isNotEmpty)
          .toList();
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<ChatModel>> fetchModels() async {
    final webBaseUrl = await apiEnvironment.getWebBaseUrl();
    final url = Uri.parse('$webBaseUrl/api/models');
    final response = await authClient.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      final modelsRaw = data is Map<String, dynamic> ? data['data'] : null;
      if (modelsRaw is! List) {
        throw FormatException('GET /api/models: expected data array');
      }
      return modelsRaw
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .where((model) => model.id.isNotEmpty)
          .toList();
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  }) async {
    if (size == 0) {
      throw Exception('Cannot upload an empty file.');
    }
    if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
      throw Exception('No readable file data found.');
    }

    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/files/');
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Accept': 'application/json',
      });

    if (path != null && path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('file', path, filename: name),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes!, filename: name),
      );
    }

    final response = await authClient.send(request);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Upload response was not a JSON object.');
      }
      final id = decoded['id']?.toString();
      if (id == null || id.isEmpty) {
        throw FormatException('Upload response did not include file id.');
      }
      return ChatFile.fromUploadResponse(
        json: decoded,
        url: '$baseURL/files/$id',
      );
    }

    throw Exception(
        'File upload failed (${response.statusCode}): $responseBody');
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
  Stream<ChatStreamEvent> sendMessages(
    List<Message> messages,
    Chat chat,
    String id, {
    List<String> toolIds = const [],
    ChatModel? model,
  }) async* {
    final accessToken = await tokenProvider.getToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No active chat session token found.');
    }

    final webBaseUrl = await apiEnvironment.getWebBaseUrl();
    final webBaseUri = Uri.parse(webBaseUrl);
    final url = Uri.parse('$webBaseUrl/api/chat/completions');
    final chatModel = model ?? ChatModel.fallback();
    final attachedFiles = _attachedFilesFromMessages(messages);
    ChatSocketSession? socketSession;

    if (toolIds.isNotEmpty) {
      socketSession = await ChatSocketSession.connect(
        webBaseUri: webBaseUri,
        token: accessToken,
      );

      if (socketSession == null) {
        throw Exception(
          'Unable to connect to the chat socket required for tool execution.',
        );
      }
    }

    final body = {
      "model": chatModel.id,
      "stream": true,
      "chat_id": chat.id,
      "id": id,
      if (socketSession != null) "session_id": socketSession.sessionId,
      if (toolIds.isNotEmpty) "tool_ids": toolIds,
      if (attachedFiles.isNotEmpty) "files": attachedFiles,
      "model_item": chatModel.rawJson,
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
    };
    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      })
      ..body = jsonEncode(body);

    if (kDebugMode) {
      debugPrint(
        'sendMessages request: url=$url model=${chatModel.id} '
        'toolIds=$toolIds messages=${messages.length} chatId=${chat.id} '
        'id=$id sessionId=${socketSession?.sessionId ?? ''}',
      );
    }

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (kDebugMode) {
        debugPrint(
          'sendMessages response: status=${response.statusCode} '
          'contentType=${response.headers['content-type']}',
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = await response.stream.bytesToString();
        if (kDebugMode) {
          debugPrint('sendMessages error body: $responseBody');
        }
        throw Exception(
          'Chat completion failed (${response.statusCode}): $responseBody',
        );
      }

      if (socketSession != null &&
          !contentType.contains('text/event-stream') &&
          !contentType.contains('application/x-ndjson')) {
        final responseBody = await response.stream.bytesToString();
        if (kDebugMode) {
          debugPrint('sendMessages socket kickoff body: $responseBody');
        }
        _throwIfKickoffFailed(responseBody);

        yield* _eventsFromChatSocket(
          socketSession,
          chatId: chat.id,
          messageId: id,
        );
        return;
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final jsonString = _jsonStringFromStreamLine(line);

        if (jsonString == null || jsonString.isEmpty) continue;

        if (jsonString == '[DONE]') return;

        final dynamic decoded;
        try {
          decoded = jsonDecode(jsonString);
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'sendMessages ignored unparsable stream line: $jsonString');
          }
          continue;
        }

        if (decoded is! Map<String, dynamic>) {
          if (kDebugMode) {
            debugPrint(
                'sendMessages ignored non-object stream event: $decoded');
          }
          continue;
        }

        final event = _chatStreamEventFromJson(decoded);
        if (event != null) {
          if (kDebugMode) {
            final type = decoded['type']?.toString() ?? 'chat:completion';
            debugPrint(
              'sendMessages event: type=$type '
              'contentLength=${event.content.length} '
              'replace=${event.replacesContent} '
              'status=${event.status?.description ?? ''}',
            );
          }
          yield event;
        } else if (kDebugMode) {
          debugPrint('sendMessages ignored stream event: $decoded');
        }
      }
    } finally {
      client.close();
      await socketSession?.close();
    }
  }

  List<Map<String, dynamic>> _attachedFilesFromMessages(
      List<Message> messages) {
    final filesById = <String, ChatFile>{};
    for (final message in messages) {
      for (final file in message.files) {
        final key = file.id.isNotEmpty ? file.id : file.url;
        if (key.isNotEmpty) {
          filesById[key] = file;
        }
      }
    }
    return filesById.values.map((file) => file.toJson()).toList();
  }

  void _throwIfKickoffFailed(String responseBody) {
    if (responseBody.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error != null) {
          throw Exception(error.toString());
        }
        if (decoded['status'] == false) {
          throw Exception(responseBody);
        }
      }
    } on FormatException {
      return;
    }
  }

  Stream<ChatStreamEvent> _eventsFromChatSocket(
    ChatSocketSession socketSession, {
    required String chatId,
    required String messageId,
  }) async* {
    var sawContent = false;

    await for (final envelope in socketSession.events.timeout(
      const Duration(minutes: 3),
      onTimeout: (sink) {
        sink.addError(
          TimeoutException('Timed out waiting for chat socket response.'),
        );
      },
    )) {
      if (!_isSocketEventForMessage(envelope, chatId, messageId)) {
        continue;
      }

      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('sendMessages ignored socket event payload: $envelope');
        }
        continue;
      }

      final event = _chatStreamEventFromJson(data);
      if (event != null) {
        sawContent = sawContent || event.hasContent || event.error != null;
        if (kDebugMode) {
          final type = data['type']?.toString() ?? 'chat:completion';
          debugPrint(
            'sendMessages socket event: type=$type '
            'contentLength=${event.content.length} '
            'replace=${event.replacesContent} '
            'status=${event.status?.description ?? ''} '
            'error=${event.error ?? ''}',
          );
        }
        yield event;
      } else if (kDebugMode) {
        debugPrint('sendMessages ignored socket event: $data');
      }

      if (_isDoneChatCompletion(data)) {
        if (!sawContent && kDebugMode) {
          debugPrint('sendMessages socket completed without content.');
        }
        return;
      }
    }
  }

  bool _isSocketEventForMessage(
    Map<String, dynamic> envelope,
    String chatId,
    String messageId,
  ) {
    return envelope['chat_id']?.toString() == chatId &&
        envelope['message_id']?.toString() == messageId;
  }

  bool _isDoneChatCompletion(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final eventData = data['data'];
    if (type == 'chat:completion' && eventData is Map<String, dynamic>) {
      return eventData['done'] == true;
    }
    return data['done'] == true;
  }

  String? _jsonStringFromStreamLine(String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) return null;

    if (trimmedLine.startsWith('data:')) {
      return trimmedLine.replaceFirst(RegExp(r'^data:\s*'), '').trim();
    }

    if (trimmedLine.startsWith('{') || trimmedLine.startsWith('[')) {
      return trimmedLine;
    }

    if (kDebugMode) {
      debugPrint('sendMessages ignored non-data stream line: $trimmedLine');
    }
    return null;
  }

  @override
  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id) async {
    final webBaseUrl = await apiEnvironment.getWebBaseUrl();
    final url = Uri.parse('$webBaseUrl/api/chat/completed');
    final modelItem = _completedModelItemFromMessages(messages);
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_id': chat.id,
        'id': id,
        'model': modelItem['id'] ?? "composites-ai-2026-02-23",
        'messages': messages.map((m) => m.toCompletedJson()).toList(),
        'model_item': modelItem,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  ChatStreamEvent? _chatStreamEventFromJson(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final eventData = data['data'];

    if (type == 'status' && eventData is Map<String, dynamic>) {
      return ChatStreamEvent(status: ToolStatus.fromJson(eventData));
    }
    if ((type == 'chat:message:delta' || type == 'message') &&
        eventData is Map<String, dynamic>) {
      final content = eventData['content']?.toString() ?? '';
      return content.isEmpty ? null : ChatStreamEvent(content: content);
    }
    if ((type == 'chat:message' || type == 'replace') &&
        eventData is Map<String, dynamic>) {
      final content = eventData['content']?.toString() ?? '';
      return content.isEmpty
          ? null
          : ChatStreamEvent(content: content, replacesContent: true);
    }
    if (type == 'chat:completion' && eventData is Map<String, dynamic>) {
      return _chatCompletionEventFromJson(eventData);
    }

    return _chatCompletionEventFromJson(data);
  }

  ChatStreamEvent? _chatCompletionEventFromJson(Map<String, dynamic> data) {
    final error = data['error'];
    if (error != null) {
      return ChatStreamEvent(error: error.toString());
    }

    final content = data['content'];
    if (content is String && content.isNotEmpty) {
      return ChatStreamEvent(content: content, replacesContent: true);
    }

    final messageDelta = MessageDeltaDTO.fromJson(data);
    final deltaContent = messageDelta.choice.delta.content;
    if (deltaContent != null && deltaContent.isNotEmpty) {
      return ChatStreamEvent(content: deltaContent);
    }

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final messageContent = message['content'];
          if (messageContent is String && messageContent.isNotEmpty) {
            return ChatStreamEvent(content: messageContent);
          }
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _completedModelItemFromMessages(List<Message> messages) {
    for (final message in messages.reversed) {
      if (message.role == 'assistant' && message.model.isNotEmpty) {
        return ChatModel.fallback(
          id: message.model,
          name:
              message.modelName.isNotEmpty ? message.modelName : 'CompositesAI',
        ).rawJson;
      }
    }
    return ChatModel.fallback().rawJson;
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
        body: jsonEncode({'content': message.content}));

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
