import 'entities/message.dart';
import 'entities/chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> fetchChats(); // Fetch sessions from a data source
  Future<List<Message>> fetchMessages(Chat chat);

  Future<Chat> createChat(Message message); // Fetch sessions from a data source
  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  Future<Chat> togglePin(Chat chat);

  Stream<String> sendMessages(List<Message> messages, Chat chat, String id);

  Future<String> shareChat(Chat chat);

  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id);

  Future<void> persistMessages(List<Message> messages, Chat chat);
}
