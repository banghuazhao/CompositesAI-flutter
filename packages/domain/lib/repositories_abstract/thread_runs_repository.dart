import 'package:domain/entities/thread_response.dart';

import '../entities/message.dart';

abstract class ThreadRunsRepository {
    Stream<Message> createRunStream(String threadId, String assistantId);
    Stream<ThreadResponse> createMessageAndRunStream(String assistantId, String message);
}