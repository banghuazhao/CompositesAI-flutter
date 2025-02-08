import '../entities/thread_response.dart';
import '../repositories_abstract/messages_repository.dart';
import '../repositories_abstract/thread_runs_repository.dart';

abstract class ThreadRunsUseCase {
  Stream<ThreadResponse> createRunStream(String threadId, String assistantId);

  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message);
}

class ThreadRunsUseCaseImpl implements ThreadRunsUseCase {
  final ThreadRunsRepository threadRunsRepository;

  ThreadRunsUseCaseImpl({required this.threadRunsRepository});

  @override
  Stream<ThreadResponse> createRunStream(String threadId, String assistantId) {
    return threadRunsRepository.createRunStream(threadId, assistantId);
  }

  @override
  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message) {
    return threadRunsRepository.createMessageAndRunStream(
        threadId, assistantId, message);
  }

  @override
  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message) {
    return threadRunsRepository.createThreadAndRunStream(
        assistantId, message);
  }
}
