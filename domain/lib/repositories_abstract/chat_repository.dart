import '../entities/function_tool.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Stream<String> sendMessages(List<Message> messages,
      List<FunctionTool> functionTools);
}
