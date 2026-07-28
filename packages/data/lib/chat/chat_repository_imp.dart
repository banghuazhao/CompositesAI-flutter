import 'dart:async';
import 'dart:convert';

import 'package:data/chat/message_delta_dto.dart';
import 'package:data/chat/chat_socket_session.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_configuration.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:domain/chat/entities/feedback_response.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:domain/chat/entities/message.dart';
import 'package:domain/chat/entities/chat_source.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

import '../mappers/domain_exception_mapper.dart';

const Duration _chatConnectionTimeout = Duration(seconds: 30);
const Duration _chatInactivityTimeout = Duration(minutes: 3);

/// Main chat list: `GET {base}/chats/` (trailing slash matters on some servers).
String _unpinnedChatsListUri(String baseURL, {int? page}) {
  final base = baseURL.endsWith('/')
      ? baseURL.substring(0, baseURL.length - 1)
      : baseURL;
  final root = Uri.parse('$base/chats/');
  if (page == null) return root.toString();
  return root.replace(queryParameters: {'page': '$page'}).toString();
}

List<Chat> _decodeChatListResponse(http.Response response, String label) {
  if (response.statusCode == 200) {
    final decoded = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decoded);
    if (data is! List) {
      throw FormatException('$label: expected JSON array');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Chat.fromJson)
        .where((chat) => chat.id.isNotEmpty)
        .toList();
  }
  throw mapServerErrorToDomainException(response);
}

Map<String, dynamic> _decodeMapResponse(http.Response response, String label) {
  final decoded = utf8.decode(response.bodyBytes);
  final data = jsonDecode(decoded);
  if (data is Map<String, dynamic>) {
    return data;
  }
  throw FormatException('$label: expected JSON object');
}

List<ChatFolder> _decodeFolderListResponse(
  http.Response response,
  String label,
) {
  if (response.statusCode == 200) {
    final decoded = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decoded);
    if (data is! List) {
      throw FormatException('$label: expected JSON array');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatFolder.fromJson)
        .where((folder) => folder.id.isNotEmpty)
        .toList();
  }
  throw mapServerErrorToDomainException(response);
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
        throw const FormatException(
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
      throw const FormatException(
          'Unexpected /chats/.../pinned response shape');
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
  Future<List<Chat>> searchChats(String text, {int page = 1}) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/search').replace(
      queryParameters: {
        'text': text,
        'page': '$page',
      },
    );
    final response = await authClient.get(
      url,
      headers: {'Accept': 'application/json'},
    );
    return _decodeChatListResponse(response, 'GET /chats/search');
  }

  @override
  Future<List<Chat>> fetchArchivedChats() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/archived');
    final response = await authClient.get(
      url,
      headers: {'Accept': 'application/json'},
    );
    return _decodeChatListResponse(response, 'GET /chats/archived');
  }

  @override
  Future<List<Chat>> fetchChatsByFolder(String folderId) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/folder/$folderId');
    final response = await authClient.get(
      url,
      headers: {'Accept': 'application/json'},
    );
    return _decodeChatListResponse(response, 'GET /chats/folder/:id');
  }

  @override
  Future<List<ChatFolder>> fetchFolders() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/folders/');
    final response = await authClient.get(
      url,
      headers: {'Accept': 'application/json'},
    );
    return _decodeFolderListResponse(response, 'GET /folders/');
  }

  @override
  Future<ChatFolder> createFolder(String name) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/folders/');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        return ChatFolder.fromJson(data);
      }
      throw const FormatException('POST /folders/: expected JSON object');
    }
    throw mapServerErrorToDomainException(response);
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
      final chatPayload = data['chat'];
      if (chatPayload is! Map<String, dynamic>) {
        throw const FormatException(
            'GET /chats/:id: missing or invalid "chat"');
      }
      return _messagesFromChatPayload(chatPayload);
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  /// Prefer `history.messages` (where CompositesAI stores sources/citations),
  /// falling back to the flat `messages` array and hydrating missing fields.
  List<Message> _messagesFromChatPayload(Map<String, dynamic> chatPayload) {
    final history = chatPayload['history'];
    final historyMessagesRaw =
        history is Map ? history['messages'] : null;
    final currentId =
        history is Map ? history['currentId']?.toString() : null;

    final historyById = <String, Map<String, dynamic>>{};
    if (historyMessagesRaw is Map) {
      historyMessagesRaw.forEach((key, value) {
        if (value is Map) {
          final json = Map<String, dynamic>.from(value);
          json['id'] ??= key.toString();
          historyById[key.toString()] = json;
        }
      });
    }

    if (historyById.isNotEmpty &&
        currentId != null &&
        currentId.isNotEmpty &&
        historyById.containsKey(currentId)) {
      final ordered = _createMessagesList(historyById, currentId);
      if (ordered.isNotEmpty) {
        return ordered.map(Message.fromJson).toList(growable: false);
      }
    }

    final messagesRaw = chatPayload['messages'];
    if (messagesRaw is! List) return <Message>[];

    return messagesRaw.whereType<Map>().map((raw) {
      final json = Map<String, dynamic>.from(raw);
      final id = json['id']?.toString() ?? '';
      final historyJson = historyById[id];
      if (historyJson != null) {
        _hydrateMessageJson(json, historyJson);
      }
      return Message.fromJson(json);
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _createMessagesList(
    Map<String, Map<String, dynamic>> historyMessages,
    String messageId,
  ) {
    final message = historyMessages[messageId];
    if (message == null) return const [];

    final parentId = message['parentId']?.toString();
    if (parentId != null &&
        parentId.isNotEmpty &&
        historyMessages.containsKey(parentId)) {
      return [
        ..._createMessagesList(historyMessages, parentId),
        message,
      ];
    }
    return [message];
  }

  void _hydrateMessageJson(
    Map<String, dynamic> target,
    Map<String, dynamic> historyJson,
  ) {
    bool missingList(String key) {
      final value = target[key];
      return value is! List || value.isEmpty;
    }

    if (missingList('sources') && historyJson['sources'] is List) {
      target['sources'] = historyJson['sources'];
    }
    if (missingList('citations') && historyJson['citations'] is List) {
      target['citations'] = historyJson['citations'];
    }
    if (missingList('statusHistory') &&
        historyJson['statusHistory'] is List) {
      target['statusHistory'] = historyJson['statusHistory'];
    }
    if (missingList('status_history') &&
        historyJson['status_history'] is List) {
      target['status_history'] = historyJson['status_history'];
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
        throw const FormatException('GET /tools/: expected a JSON array');
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
        throw const FormatException('GET /api/models: expected data array');
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
  Future<ChatConfiguration> fetchChatConfiguration() async {
    final webBaseUrl = await apiEnvironment.getWebBaseUrl();
    final url = Uri.parse('$webBaseUrl/api/config');
    final token = kIsWeb ? null : await tokenProvider.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Cookie': 'token=$token',
    };
    final response = await authClient.get(url, headers: headers);

    if (response.statusCode == 200) {
      return ChatConfiguration.fromJson(
        _decodeMapResponse(response, 'GET /api/config'),
      );
    }
    throw mapServerErrorToDomainException(response);
  }

  @override
  Future<List<ChatKnowledge>> fetchKnowledgeBases() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/knowledge/');
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
        throw const FormatException('GET /knowledge/: expected a JSON array');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatKnowledge.fromJson)
          .where((knowledge) => knowledge.id.isNotEmpty)
          .toList();
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<ChatModel>> fetchWorkspaceModels() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/models/');
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
        throw const FormatException('GET /models/: expected a JSON array');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .where((model) => model.id.isNotEmpty)
          .toList();
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<ChatModel> createModel(Map<String, dynamic> model) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/models/create');
    final response = await authClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model),
    );

    if (response.statusCode == 200) {
      return ChatModel.fromJson(
          _decodeMapResponse(response, 'POST /models/create'));
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<ChatModel> updateModel(String id, Map<String, dynamic> model) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/models/model/update')
        .replace(queryParameters: {'id': id});
    final response = await authClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model),
    );

    if (response.statusCode == 200) {
      return ChatModel.fromJson(
        _decodeMapResponse(response, 'POST /models/model/update'),
      );
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<ChatModel> toggleModel(String id) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/models/model/toggle')
        .replace(queryParameters: {'id': id});
    final response = await authClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return ChatModel.fromJson(
        _decodeMapResponse(response, 'POST /models/model/toggle'),
      );
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> deleteModel(String id) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/models/model/delete')
        .replace(queryParameters: {'id': id});
    final response = await authClient.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<List<ChatTool>> fetchToolList() async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/tools/list');
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
        throw const FormatException('GET /tools/list: expected a JSON array');
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
  Future<ChatTool> createTool(Map<String, dynamic> tool) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/tools/create');
    final response = await authClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(tool),
    );

    if (response.statusCode == 200) {
      return ChatTool.fromJson(
          _decodeMapResponse(response, 'POST /tools/create'));
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<ChatTool> updateTool(String id, Map<String, dynamic> tool) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/tools/id/$id/update');
    final response = await authClient.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(tool),
    );

    if (response.statusCode == 200) {
      return ChatTool.fromJson(
        _decodeMapResponse(response, 'POST /tools/id/:id/update'),
      );
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<void> deleteTool(String id) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/tools/id/$id/delete');
    final response = await authClient.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
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
        throw const FormatException('Upload response was not a JSON object.');
      }
      final id = decoded['id']?.toString();
      if (id == null || id.isEmpty) {
        throw const FormatException('Upload response did not include file id.');
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
          'models': [
            message.model.isNotEmpty ? message.model : ChatModel.defaultModelId,
          ],
          'history': {'messages': message.toHistoryJson()},
          'messages': [message.toJson()]
        }
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        throw const FormatException('POST /chats/new: missing chat response');
      }
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
      if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        chat.title = newTitle;
        return chat;
      }
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
  Future<Chat> updateChatFolder(Chat chat, String? folderId) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}/folder');
    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'folder_id': folderId}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        chat.folderId = folderId;
        return chat;
      }
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return Chat.fromJson(data);
      }
      chat.folderId = folderId;
      return chat;
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }

  @override
  Future<Chat> archiveChat(Chat chat) async {
    final baseURL = await apiEnvironment.getBaseUrl();
    final url = Uri.parse('$baseURL/chats/${chat.id}/archive');
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
      if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
        throw const FormatException('POST /chats/:id/share: missing share id');
      }
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
      final response = await client.send(request).timeout(
            _chatConnectionTimeout,
            onTimeout: () => throw TimeoutException(
              'Timed out while connecting to the chat service.',
            ),
          );
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
        throw mapServerErrorToDomainException(
          http.Response(
            responseBody,
            response.statusCode,
            headers: response.headers,
            reasonPhrase: response.reasonPhrase,
            request: request,
          ),
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
          .timeout(
            _chatInactivityTimeout,
            onTimeout: (sink) {
              sink
                ..addError(
                  TimeoutException(
                    'Timed out waiting for the next chat response event.',
                  ),
                )
                ..close();
            },
          )
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
      _chatInactivityTimeout,
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
        'model': modelItem['id'] ?? ChatModel.defaultModelId,
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
    if ((type == 'source' || type == 'citation') && eventData != null) {
      final sources = ChatSource.listFromPayload(eventData);
      return sources.isEmpty ? null : ChatStreamEvent(sources: sources);
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

    final sources = ChatSource.merge(
      ChatSource.listFromPayload(data['sources']),
      ChatSource.listFromPayload(data['citations']),
    );

    final content = data['content'];
    if (content is String && content.isNotEmpty) {
      return ChatStreamEvent(
        content: content,
        replacesContent: true,
        sources: sources,
      );
    }

    final messageDelta = MessageDeltaDTO.fromJson(data);
    final deltaContent = messageDelta.choice.delta.content;
    if (deltaContent != null && deltaContent.isNotEmpty) {
      return ChatStreamEvent(content: deltaContent, sources: sources);
    }

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final messageContent = message['content'];
          if (messageContent is String && messageContent.isNotEmpty) {
            return ChatStreamEvent(
              content: messageContent,
              sources: sources,
            );
          }
        }
      }
    }

    if (sources.isNotEmpty) {
      return ChatStreamEvent(sources: sources);
    }

    return null;
  }

  Map<String, dynamic> _completedModelItemFromMessages(List<Message> messages) {
    for (final message in messages.reversed) {
      if (message.role == 'assistant' && message.model.isNotEmpty) {
        return ChatModel.fallback(
          id: message.model,
          name:
              message.modelName.isNotEmpty ? message.modelName : ChatModel.defaultModelName,
        ).rawJson;
      }
    }
    return ChatModel.fallback().rawJson;
  }

  List<String> _modelIdsForPersist(List<Message> messages) {
    for (final message in messages.reversed) {
      if (message.model.isNotEmpty) {
        return [message.model];
      }
    }
    return const [ChatModel.defaultModelId];
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
            'models': [_modelIdsForPersist(messages)],
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

    if (response.statusCode == 200 || response.statusCode == 204) {
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

    if (response.statusCode == 200 || response.statusCode == 204) {
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
      throw const FormatException('Unexpected chat snapshot format');
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
      throw const FormatException('Unexpected feedback format');
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
      throw const FormatException('Unexpected feedback format');
    } else {
      throw mapServerErrorToDomainException(response);
    }
  }
}
