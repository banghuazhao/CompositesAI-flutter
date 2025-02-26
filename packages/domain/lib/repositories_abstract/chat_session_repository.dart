import '../entities/chat/chat_session.dart';

abstract class ChatSessionRepository {
  Future<List<ChatSession>> getAllSessions();  // Fetch sessions from a data source
  Future<void> createSession(ChatSession session);
  Future<void> saveSession(ChatSession session);
  Future<void> deleteSession(String id);
  Future<ChatSession?> selectSession(String id);
}
