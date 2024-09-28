import '../../domain/entities/chat_session.dart';
import '../../domain/repositories_abstract/chat_session_repository.dart';

class ChatSessionRepositoryImpl implements ChatSessionRepository {
  @override
  Future<List<ChatSession>> getAllSessions() async {
    // Fetch sessions from data source (e.g., local storage, API)
    return [];
  }

  @override
  Future<void> createSession(ChatSession session) async {
    // Create session to a data source
  }

  @override
  Future<void> saveSession(ChatSession session) async {
    // Save session to a data source
  }

  @override
  Future<void> deleteSession(String id) async {
    // Delete session from data source
  }

  @override
  Future<ChatSession?> selectSession(String id) async {
    return null;
  }
}
