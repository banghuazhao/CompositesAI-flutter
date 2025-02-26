import '../entities/chat/thread.dart';

abstract class ThreadsRepository {
  Future<Thread> createThread();
  Future<Thread> retrieveThread(String threadId);
}