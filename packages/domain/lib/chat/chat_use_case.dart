import 'entities/message.dart';
import 'entities/chat.dart';
import 'entities/chat_model.dart';
import 'entities/chat_stream_event.dart';
import 'entities/chat_tool.dart';
import 'entities/chat_file.dart';
import 'entities/chat_folder.dart';
import 'entities/chat_knowledge.dart';
import 'entities/chat_tag.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  /// GET /api/v1/chats (?page= optional).
  Future<List<Chat>> fetchChats({int? page});

  /// GET /api/v1/chats/{chatId}/pinned — server truth for pinned flag.
  Future<bool> fetchChatPinned(String chatId);

  Future<List<Chat>> fetchPinnedChats();

  Future<List<Chat>> searchChats(String text, {int page = 1});

  Future<List<Chat>> fetchArchivedChats();

  Future<List<Chat>> fetchChatsByTag(String tagName);

  Future<List<Chat>> fetchChatsByFolder(String folderId);

  Future<List<ChatTag>> fetchAllTags();

  Future<List<ChatTag>> fetchChatTags(String chatId);

  Future<List<ChatTag>> addChatTag(String chatId, String tagName);

  Future<List<ChatTag>> removeChatTag(String chatId, String tagName);

  Future<List<ChatFolder>> fetchFolders();

  Future<ChatFolder> createFolder(String name);

  Future<List<Message>> fetchMessages(Chat chat);

  Future<List<ChatTool>> fetchTools();

  Future<List<ChatModel>> fetchModels();

  Future<List<ChatKnowledge>> fetchKnowledgeBases();

  Future<List<ChatModel>> fetchWorkspaceModels();

  Future<ChatModel> createModel(Map<String, dynamic> model);

  Future<ChatModel> updateModel(String id, Map<String, dynamic> model);

  Future<ChatModel> toggleModel(String id);

  Future<void> deleteModel(String id);

  Future<List<ChatTool>> fetchToolList();

  Future<ChatTool> createTool(Map<String, dynamic> tool);

  Future<ChatTool> updateTool(String id, Map<String, dynamic> tool);

  Future<void> deleteTool(String id);

  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  });

  Future<Chat> createChat(Message message);

  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  Future<Chat> togglePin(Chat chat);

  Future<Chat> updateChatFolder(Chat chat, String? folderId);

  Future<Chat> archiveChat(Chat chat);

  Stream<ChatStreamEvent> sendMessages(
    List<Message> messages,
    Chat chat,
    String id, {
    List<String> toolIds = const [],
    ChatModel? model,
  });

  Future<String> shareChat(Chat chat);

  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id);

  Future<void> persistMessages(List<Message> messages, Chat chat);

  Future<void> updateChatMessage(Message message, Chat chat);

  /// Create or update rating feedback for an assistant message.
  /// Returns feedback id (stored into message.feedbackId).
  Future<String> submitMessageFeedback({
    required Chat chat,
    required Message message,
    required int goodBadRating, // 1 for Good, -1 for Bad
    required int detailsRating, // 1..10 from UI
    required List<String> reasons, // selected chips
    String? comment, // optional
    required int messageIndex, // backend meta.message_index (1-based)
  });
}

class ChatUseCaseImpl implements ChatUseCase {
  final ChatRepository repository;

  ChatUseCaseImpl({required this.repository});

  @override
  Future<List<Chat>> fetchChats({int? page}) async {
    return repository.fetchChats(page: page);
  }

  @override
  Future<bool> fetchChatPinned(String chatId) async {
    return repository.fetchChatPinned(chatId);
  }

  @override
  Future<List<Chat>> fetchPinnedChats() async {
    return repository.fetchPinnedChats();
  }

  @override
  Future<List<Chat>> searchChats(String text, {int page = 1}) {
    return repository.searchChats(text, page: page);
  }

  @override
  Future<List<Chat>> fetchArchivedChats() {
    return repository.fetchArchivedChats();
  }

  @override
  Future<List<Chat>> fetchChatsByTag(String tagName) {
    return repository.fetchChatsByTag(tagName);
  }

  @override
  Future<List<Chat>> fetchChatsByFolder(String folderId) {
    return repository.fetchChatsByFolder(folderId);
  }

  @override
  Future<List<ChatTag>> fetchAllTags() {
    return repository.fetchAllTags();
  }

  @override
  Future<List<ChatTag>> fetchChatTags(String chatId) {
    return repository.fetchChatTags(chatId);
  }

  @override
  Future<List<ChatTag>> addChatTag(String chatId, String tagName) {
    return repository.addChatTag(chatId, tagName);
  }

  @override
  Future<List<ChatTag>> removeChatTag(String chatId, String tagName) {
    return repository.removeChatTag(chatId, tagName);
  }

  @override
  Future<List<ChatFolder>> fetchFolders() {
    return repository.fetchFolders();
  }

  @override
  Future<ChatFolder> createFolder(String name) {
    return repository.createFolder(name);
  }

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    return repository.fetchMessages(chat);
  }

  @override
  Future<List<ChatTool>> fetchTools() {
    return repository.fetchTools();
  }

  @override
  Future<List<ChatModel>> fetchModels() {
    return repository.fetchModels();
  }

  @override
  Future<List<ChatKnowledge>> fetchKnowledgeBases() {
    return repository.fetchKnowledgeBases();
  }

  @override
  Future<List<ChatModel>> fetchWorkspaceModels() {
    return repository.fetchWorkspaceModels();
  }

  @override
  Future<ChatModel> createModel(Map<String, dynamic> model) {
    return repository.createModel(model);
  }

  @override
  Future<ChatModel> updateModel(String id, Map<String, dynamic> model) {
    return repository.updateModel(id, model);
  }

  @override
  Future<ChatModel> toggleModel(String id) {
    return repository.toggleModel(id);
  }

  @override
  Future<void> deleteModel(String id) {
    return repository.deleteModel(id);
  }

  @override
  Future<List<ChatTool>> fetchToolList() {
    return repository.fetchToolList();
  }

  @override
  Future<ChatTool> createTool(Map<String, dynamic> tool) {
    return repository.createTool(tool);
  }

  @override
  Future<ChatTool> updateTool(String id, Map<String, dynamic> tool) {
    return repository.updateTool(id, tool);
  }

  @override
  Future<void> deleteTool(String id) {
    return repository.deleteTool(id);
  }

  @override
  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  }) {
    return repository.uploadChatFile(
      name: name,
      size: size,
      path: path,
      bytes: bytes,
    );
  }

  @override
  Future<Chat> createChat(Message message) {
    return repository.createChat(message);
  }

  @override
  Future<void> deleteChat(Chat chat) async {
    return repository.deleteChat(chat);
  }

  @override
  Future<Chat> updateChatTitle(Chat chat, String newTitle) async {
    return repository.updateChatTitle(chat, newTitle);
  }

  @override
  Future<Chat> togglePin(Chat chat) async {
    return repository.togglePin(chat);
  }

  @override
  Future<Chat> updateChatFolder(Chat chat, String? folderId) {
    return repository.updateChatFolder(chat, folderId);
  }

  @override
  Future<Chat> archiveChat(Chat chat) {
    return repository.archiveChat(chat);
  }

  @override
  Stream<ChatStreamEvent> sendMessages(
    List<Message> messages,
    Chat chat,
    String id, {
    List<String> toolIds = const [],
    ChatModel? model,
  }) {
    return repository.sendMessages(
      messages,
      chat,
      id,
      toolIds: toolIds,
      model: model,
    );
  }

  @override
  Future<String> shareChat(Chat chat) async {
    return repository.shareChat(chat);
  }

  @override
  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id) async {
    return repository.completeSendMessages(messages, chat, id);
  }

  @override
  Future<void> persistMessages(List<Message> messages, Chat chat) async {
    return repository.persistMessages(messages, chat);
  }

  @override
  Future<void> updateChatMessage(Message message, Chat chat) async {
    return repository.updateChatMessage(message, chat);
  }

  @override
  Future<String> submitMessageFeedback({
    required Chat chat,
    required Message message,
    required int goodBadRating,
    required int detailsRating,
    required List<String> reasons,
    String? comment,
    required int messageIndex,
  }) async {
    final Map<String, dynamic> commonForm = {
      'type': 'rating',
      'data': {
        'rating': goodBadRating,
        'model_id': message.model,
        'sibling_model_ids': message.models,
        'tags': reasons,
        'reason': reasons.isEmpty ? 'Other' : reasons.join(', '),
        'comment': comment ?? '',
        'details': {
          'rating': detailsRating,
        },
      },
      'meta': {
        'arena': false,
        'chat_id': chat.id,
        'message_id': message.id,
        'message_index': messageIndex, // 1-based
        'tags': reasons,
        'model_id': message.model,
        // Backend allows extra meta fields; best-effort.
        'base_models': {for (final m in message.models) m: null},
      },
    };

    if (message.feedbackId == null) {
      // Create: must include snapshot.chat (ChatResponse verbatim).
      final snapshotChat = await repository.fetchChatSnapshot(chat.id);
      final Map<String, dynamic> createForm = {
        ...commonForm,
        'snapshot': {
          'chat': snapshotChat,
        },
      };

      final created = await repository.createFeedback(createForm);
      final feedbackId = created.id.trim();
      if (feedbackId.isEmpty) {
        throw Exception('Feedback created but id missing.');
      }
      return feedbackId;
    }

    // Update: omit snapshot to keep old snapshot on backend.
    final Map<String, dynamic> updateForm = commonForm;

    final updated = await repository.updateFeedback(
      message.feedbackId!,
      updateForm,
    );
    final feedbackId = updated.id.trim();
    if (feedbackId.isEmpty) {
      throw Exception('Feedback updated but id missing in response.');
    }
    return feedbackId;
  }
}
