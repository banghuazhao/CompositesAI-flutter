import '../entities/thread_response.dart';
import '../entities/thread_tool_output.dart';
import '../repositories_abstract/thread_runs_repository.dart';

abstract class ThreadRunsUseCase {
  Stream<ThreadResponse> createRunStream(String threadId, String assistantId);

  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message);

  Stream<ThreadResponse> submitToolOutputsToRunStream(
      String threadId, String runId, List<ThreadToolOutput> toolOutputs);
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

  @override
  Stream<ThreadResponse> submitToolOutputsToRunStream(
      String threadId, String runId, List<ThreadToolOutput> toolOutputs) {
    return threadRunsRepository.submitToolOutputsToRunStream(threadId, runId, toolOutputs);
  }
}
