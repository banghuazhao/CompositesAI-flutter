import 'entities/message.dart';
import 'entities/chat.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  Future<List<Chat>> fetchChats();

  Future<List<Message>> fetchMessages(Chat chat);

  Future<void> deleteChat(Chat chat);

  Future<Chat> updateChatTitle(Chat chat, String newTitle);

  Future<Chat> togglePin(Chat chat);

  Stream<String> sendMessages(List<Message> messages, Chat chat);
  Future<String> shareChat(Chat chat);
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
  Stream<String> sendMessages(List<Message> messages, Chat chat) {
    return repository.sendMessages(messages, chat);
  }

  @override
  Future<String> shareChat(Chat chat) async {
    return repository.shareChat(chat);
  }
}
