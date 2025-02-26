import '../entities/chat/chat_session.dart';
import '../entities/chat/message.dart';
import '../repositories_abstract/chat_session_repository.dart';

abstract class ChatSessionUseCase {
  Future<List<ChatSession>> getAllSessions();
  Future<void> saveSession(ChatSession session);
  Future<void> deleteSession(String sessionId);
  ChatSession createNewSession();
  void addMessageToSession(ChatSession session, Message message);
  bool isLastMessageAssistInSession(ChatSession session);
  void updateLastAssistantMessage(ChatSession session, Message message);
}


class ChatSessionUseCaseImpl implements ChatSessionUseCase {
  final ChatSessionRepository repository;

  ChatSessionUseCaseImpl({required this.repository});

  Future<List<ChatSession>> getAllSessions() async {
    return repository.getAllSessions();
  }

  Future<void> saveSession(ChatSession session) async {
    // You can add business rules here (e.g., session validation)
    repository.saveSession(session);
  }

  Future<void> deleteSession(String sessionId) async {
    repository.deleteSession(sessionId);
  }

  ChatSession createNewSession() {
    final newSession = ChatSession(
      title: 'New Chat',
    );
    return newSession;
  }

  void addMessageToSession(ChatSession session, Message message) {
    session.messages.add(message);
    saveSession(session);
  }

  // Check if the last message in the session is from the assistant
  bool isLastMessageAssistInSession(ChatSession session) {
    final messages = session.messages;
    if (messages != null && messages.isNotEmpty) {
      return messages.last.role == 'assistant';
    }
    return false;
  }

  // Add a new method to update the last assistant message
  void updateLastAssistantMessage(ChatSession session, Message message) {
    // Find the last message that is from the assistant
    for (var i = session.messages.length - 1; i >= 0; i--) {
      if (session.messages[i].role == 'assistant') {
        session.messages[i] = message;
        break;
      }
    }
  }
}
