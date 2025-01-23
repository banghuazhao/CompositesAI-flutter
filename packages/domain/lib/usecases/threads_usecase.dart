import '../entities/thread.dart';
import '../repositories_abstract/threads_repository.dart';

abstract class ThreadsUseCase {
  Future<Thread> createThread();
}

class ThreadsUseCaseImpl implements ThreadsUseCase {
  final ThreadsRepository repository;

  ThreadsUseCaseImpl({required this.repository});

  @override
  Future<Thread> createThread() async {
    return await repository.createThread();
  }
}