import 'package:domain/entities/chat/function_tool_output.dart';

import '../entities/chat/function_tool.dart';

abstract class FunctionalCallRepository {
  Future<FunctionToolOutput> callFunctionTool(FunctionTool tool);
}