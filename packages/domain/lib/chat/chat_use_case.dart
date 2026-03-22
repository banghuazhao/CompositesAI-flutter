import 'entities/message.dart';
import 'entities/chat.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  Future<List<Chat>> fetchChats();

  Future<List<Message>> fetchMessages(Chat chat);

  Future<Chat> createChat(Message message);

  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  Future<Chat> togglePin(Chat chat);

  Stream<String> sendMessages(List<Message> messages, Chat chat, String id);

  Future<String> shareChat(Chat chat);

  Future<void> completeSendMessages(
      List<Message> messages, Chat chat, String id);

  Future<void> persistMessages(List<Message> messages, Chat chat);
}

class ChatUseCaseImpl implements ChatUseCase {
  final ChatRepository repository;

  ChatUseCaseImpl({required this.repository});

  @override
  Future<List<Chat>> fetchChats() async {
    return repository.fetchChats();
  }

  @override
  Future<List<Message>> fetchMessages(Chat chat) async {
    return repository.fetchMessages(chat);
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
  Stream<String> sendMessages(List<Message> messages, Chat chat, String id) {
    return repository.sendMessages(messages, chat, id);
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
  Future<void> persistMessages(
      List<Message> messages, Chat chat) async {
    return repository.persistMessages(messages, chat);
  }
}
