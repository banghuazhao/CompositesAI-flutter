import 'package:domain/entities/thread_message.dart';
import '../entities/thread.dart';
import '../repositories_abstract/messages_repository.dart';

abstract class MessagesUseCase {
  Future<ThreadMessage> createMessage(String threadId, String message);
  Future<List<ThreadMessage>> listMessage(String threadId);
  Future<ThreadMessage> retrieveMessage(String threadId, String messageId);
}

class MessagesUseCaseImpl implements MessagesUseCase {
  final MessagesRepository repository;

  MessagesUseCaseImpl({required this.repository});

  @override
  Future<ThreadMessage> createMessage(String threadId, String message) async {
    return await repository.createMessage(threadId, message);
  }

  @override
  Future<List<ThreadMessage>> listMessage(String threadId) async {
    return await repository.listMessage(threadId);
  }

  @override
  Future<ThreadMessage> retrieveMessage(String threadId, String messageId) async {
    return await retrieveMessage(threadId, messageId);
  }


}