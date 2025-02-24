import 'package:domain/entities/thread_function_tool.dart';
import 'package:domain/entities/thread_tool_output.dart';

abstract class FunctionalCallRepository {
  Future<ThreadToolOutput> callFunctionTool(ThreadFunctionTool tool);
}