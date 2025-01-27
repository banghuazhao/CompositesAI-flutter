import '../entities/assistant.dart';
import '../entities/thread_run.dart';

abstract class ThreadRunsRepository {
    Future<ThreadRun> createRun(Assistant assistant);
    Future<ThreadRun> createMessageAndRun(Assistant assistant, String message);
}