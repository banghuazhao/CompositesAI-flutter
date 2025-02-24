import 'package:domain/entities/thread_response.dart';
import 'package:domain/entities/thread_tool_output.dart';

abstract class ThreadRunsRepository {
  Stream<ThreadResponse> createRunStream(String threadId, String assistantId);

  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message);

  Stream<ThreadResponse> submitToolOutputsToRunStream(
    String threadId, String runId, List<ThreadToolOutput> toolOutputs);
}
