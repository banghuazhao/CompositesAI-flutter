import 'package:domain/entities/chat/chat_response.dart';
import 'package:domain/entities/chat/function_tool_output.dart';

abstract class ThreadRunsRepository {
  Stream<ChatResponse> createRunStream(String threadId, String assistantId);

  Stream<ChatResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ChatResponse> createThreadAndRunStream(
      String assistantId, String message);

  Stream<ChatResponse> submitToolOutputsToRunStream(
    String threadId, String runId, List<FunctionToolOutput> toolOutputs);
}
