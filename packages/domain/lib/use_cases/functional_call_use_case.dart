import '../entities/chat/function_tool.dart';
import '../entities/chat/function_tool_output.dart';
import '../repositories_abstract/functional_call_repository.dart';

abstract class FunctionalCallUseCase {
  Future<FunctionToolOutput> callFunctionTool(FunctionTool tool);
}

class FunctionalCallUseCaseImpl implements FunctionalCallUseCase {
  final FunctionalCallRepository repository;

  FunctionalCallUseCaseImpl({required this.repository});

  @override
  Future<FunctionToolOutput> callFunctionTool(FunctionTool tool) async {
    return await repository.callFunctionTool(tool);
  }
}
