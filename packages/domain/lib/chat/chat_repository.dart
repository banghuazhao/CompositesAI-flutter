import 'entities/message.dart';
import 'entities/chat.dart';
import 'entities/chat_model.dart';
import 'entities/chat_stream_event.dart';
import 'entities/chat_tool.dart';
import 'entities/chat_file.dart';
import 'entities/feedback_response.dart';
import 'entities/chat_folder.dart';
import 'entities/chat_tag.dart';

abstract class ChatRepository {
  /// GET /api/v1/chats/ — unpinned chats, ordered by `updated_at` (optional `?page=`).
  /// Path uses a trailing slash; response is a JSON array of ChatResponse.
  Future<List<Chat>> fetchChats({int? page});

  /// GET /api/v1/chats/{chatId}/pinned — whether this chat is pinned (for Pin/Unpin label).
  Future<bool> fetchChatPinned(String chatId);

  /// GET /api/v1/chats/pinned — JSON array of ChatResponse (same shape as elsewhere).
  /// HTTP 200 with body `[]` when there are no pinned chats (not null, not 404).
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

  Future<Chat> createChat(Message message); // Fetch sessions from a data source
  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  /// POST /api/v1/chats/{chatId}/pin — no body; toggles pinned. Response may be
  /// ChatResponse JSON, 204, or empty body; client should refresh pinned list.
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

  /// GET /api/v1/chats/{chatId}
  Future<Map<String, dynamic>> fetchChatSnapshot(String chatId);

  /// POST /api/v1/evaluations/feedback
  Future<FeedbackResponse> createFeedback(Map<String, dynamic> feedbackForm);

  /// POST /api/v1/evaluations/feedback/{feedbackId}
  Future<FeedbackResponse> updateFeedback(
      String feedbackId, Map<String, dynamic> feedbackForm);
}
