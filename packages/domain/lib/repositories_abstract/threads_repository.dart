import '../entities/thread.dart';

abstract class ThreadsRepository {
  Future<Thread> createThread();
}