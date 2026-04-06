import 'entities/message.dart';
import 'entities/chat.dart';
import 'entities/feedback_response.dart';

abstract class ChatRepository {
  /// GET /api/v1/chats/ — unpinned chats, ordered by `updated_at` (optional `?page=`).
  /// Path uses a trailing slash; response is a JSON array of ChatResponse.
  Future<List<Chat>> fetchChats({int? page});

  /// GET /api/v1/chats/{chatId}/pinned — whether this chat is pinned (for Pin/Unpin label).
  Future<bool> fetchChatPinned(String chatId);

  /// GET /api/v1/chats/pinned — JSON array of ChatResponse (same shape as elsewhere).
  /// HTTP 200 with body `[]` when there are no pinned chats (not null, not 404).
  Future<List<Chat>> fetchPinnedChats();

  Future<List<Message>> fetchMessages(Chat chat);

  Future<Chat> createChat(Message message); // Fetch sessions from a data source
  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  /// POST /api/v1/chats/{chatId}/pin — no body; toggles pinned. Response may be
  /// ChatResponse JSON, 204, or empty body; client should refresh pinned list.
  Future<Chat> togglePin(Chat chat);

  Stream<String> sendMessages(List<Message> messages, Chat chat, String id);

  Future<String> shareChat(Chat chat);

  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id);

  Future<void> persistMessages(List<Message> messages, Chat chat);

  Future<void> updateChatMessage(Message message, Chat chat);

  /// GET /api/v1/chats/{chatId}
  Future<Map<String, dynamic>> fetchChatSnapshot(String chatId);

  /// POST /api/v1/evaluations/feedback
  Future<FeedbackResponse> createFeedback(
      Map<String, dynamic> feedbackForm);

  /// POST /api/v1/evaluations/feedback/{feedbackId}
  Future<FeedbackResponse> updateFeedback(
      String feedbackId, Map<String, dynamic> feedbackForm);
}
