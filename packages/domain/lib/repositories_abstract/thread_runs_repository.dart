import 'package:domain/entities/thread_response.dart';

abstract class ThreadRunsRepository {
  Stream<ThreadResponse> createRunStream(String threadId, String assistantId);

  Stream<ThreadResponse> createMessageAndRunStream(
      String threadId, String assistantId, String message);

  Stream<ThreadResponse> createThreadAndRunStream(
      String assistantId, String message);
}
