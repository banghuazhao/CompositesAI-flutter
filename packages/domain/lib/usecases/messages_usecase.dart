import 'package:domain/entities/assistant_message.dart';
import '../entities/message.dart';
import '../entities/thread.dart';
import '../repositories_abstract/messages_repository.dart';

abstract class MessagesUseCase {
  Future<AssistantMessage> createMessage(Thread thread, Message message);
}

class MessagesUseCaseImpl implements MessagesUseCase {
  final MessagesRepository repository;

  MessagesUseCaseImpl({required this.repository});

  @override
  Future<AssistantMessage> createMessage(Thread thread, Message message) async {
    return await repository.createMessage(thread, message);
  }
}