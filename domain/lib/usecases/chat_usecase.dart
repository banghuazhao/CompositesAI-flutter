import '../entities/message.dart';
import '../repositories_abstract/chat_repository.dart';

class ChatUseCase {
  final ChatRepository repository;

  ChatUseCase(this.repository);

  Stream<String> sendMessages(List<Message> messages) {
    return repository.sendMessages(messages);
  }
}
