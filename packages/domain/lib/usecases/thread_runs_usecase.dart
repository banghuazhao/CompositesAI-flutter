import 'package:domain/entities/assistant.dart';

import '../entities/thread_run.dart';
import '../repositories_abstract/thread_runs_repository.dart';


abstract class ThreadRunsUseCase {
  Future<ThreadRun> createRun(Assistant assistant);
  Future<ThreadRun> createMessageAndRun(Assistant assistant, String message);
}

class ThreadRunsUseCaseImpl implements ThreadRunsUseCase {
  final ThreadRunsRepository repository;

  ThreadRunsUseCaseImpl({required this.repository});

  @override
  Future<ThreadRun> createRun(Assistant assistant) async {
    return await repository.createRun(assistant);
  }

  @override
  Future<ThreadRun> createMessageAndRun(Assistant assistant, String message) async {
    return await repository.createMessageAndRun(assistant, message);
  }
}