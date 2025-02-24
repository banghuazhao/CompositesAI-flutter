import '../entities/thread_function_tool.dart';
import '../entities/thread_tool_output.dart';
import '../repositories_abstract/functional_call_repository.dart';

abstract class FunctionalCallUseCase {
  Future<ThreadToolOutput> callFunctionTool(ThreadFunctionTool tool);
}

class FunctionalCallUseCaseImpl implements FunctionalCallUseCase {
  final FunctionalCallRepository repository;

  FunctionalCallUseCaseImpl({required this.repository});

  @override
  Future<ThreadToolOutput> callFunctionTool(ThreadFunctionTool tool) async {
    return await repository.callFunctionTool(tool);
  }
}
