import '../entities/chat/message.dart';
import 'chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> fetchChats();  // Fetch sessions from a data source
  Future<List<Message>> fetchMessages(Chat chat);
}
