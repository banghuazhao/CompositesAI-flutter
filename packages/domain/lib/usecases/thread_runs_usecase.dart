import '../entities/message.dart';
import '../entities/thread_response.dart';
import '../repositories_abstract/thread_runs_repository.dart';

abstract class ThreadRunsUseCase {
  Stream<Message> createRunStream(String threadId, String assistantId);

  Stream<ThreadResponse> createMessageAndRunStream(String assistantId, String message);
}

class ThreadRunsUseCaseImpl implements ThreadRunsUseCase {
  final ThreadRunsRepository repository;

  ThreadRunsUseCaseImpl({required this.repository});

  @override
  Stream<Message> createRunStream(String threadId, String assistantId) {
    return repository.createRunStream(threadId, assistantId);
  }

  @override
  Stream<ThreadResponse> createMessageAndRunStream(
      String assistantId, String message) {
    return repository.createMessageAndRunStream(assistantId, message);
  }
}
