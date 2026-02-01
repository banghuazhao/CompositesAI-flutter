import '../entities/chat/message.dart';
import 'chat.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  Future<List<Chat>> fetchChats();
  Future<List<Message>> fetchMessages(Chat chat);
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
}
