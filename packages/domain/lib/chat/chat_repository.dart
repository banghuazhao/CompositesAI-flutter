import '../entities/chat/message.dart';
import 'chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> fetchChats();  // Fetch sessions from a data source
  Future<List<Message>> fetchMessages(Chat chat);
  Future<void> deleteChat(Chat chat);
  Future<Chat> updateChatTitle(Chat chat, String newTitle);
  Future<Chat> togglePin(Chat chat);
}
