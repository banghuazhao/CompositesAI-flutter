import '../entities/thread.dart';
import '../repositories_abstract/threads_repository.dart';

abstract class ThreadsUseCase {
  Future<Thread> createThread();
  Future<Thread> retrieveThread(String threadId);
}

class ThreadsUseCaseImpl implements ThreadsUseCase {
  final ThreadsRepository repository;

  ThreadsUseCaseImpl({required this.repository});

  @override
  Future<Thread> createThread() async {
    return await repository.createThread();
  }

  @override
  Future<Thread> retrieveThread(String threadId) async {
    return await repository.retrieveThread(threadId);
  }
}