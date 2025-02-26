import '../entities/chat/chat_response.dart';
import '../entities/chat/function_tool_output.dart';
import '../repositories_abstract/thread_runs_repository.dart';

abstract class ThreadRunsUseCase {
  Stream<ChatResponse> createRunStream(String threadId, String assistantId);

  Stream<ChatResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ChatResponse> createThreadAndRunStream(
      String assistantId, String message);

  Stream<ChatResponse> submitToolOutputsToRunStream(
      String threadId, String runId, List<FunctionToolOutput> toolOutputs);
}

class ThreadRunsUseCaseImpl implements ThreadRunsUseCase {
  final ThreadRunsRepository threadRunsRepository;

  ThreadRunsUseCaseImpl({required this.threadRunsRepository});

  @override
  Stream<ChatResponse> createRunStream(String threadId, String assistantId) {
    return threadRunsRepository.createRunStream(threadId, assistantId);
  }

  @override
  Stream<ChatResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message) {
    return threadRunsRepository.createMessageAndRunStream(
        threadId, assistantId, message);
  }

  @override
  Stream<ChatResponse> createThreadAndRunStream(
      String assistantId, String message) {
    return threadRunsRepository.createThreadAndRunStream(
        assistantId, message);
  }

  @override
  Stream<ChatResponse> submitToolOutputsToRunStream(
      String threadId, String runId, List<FunctionToolOutput> toolOutputs) {
    return threadRunsRepository.submitToolOutputsToRunStream(threadId, runId, toolOutputs);
  }
}
