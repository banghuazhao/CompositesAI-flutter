import 'chat.dart';
import 'chat_repository.dart';

abstract class ChatUseCase {
  Future<List<Chat>> getChatList();
}


class ChatUseCaseImpl implements ChatUseCase {
  final ChatRepository repository;

  ChatUseCaseImpl({required this.repository});

  Future<List<Chat>> getChatList() async {
    return repository.getChatList();
  }
}
