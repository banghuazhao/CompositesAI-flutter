import '../entities/function_tool.dart';
import '../entities/message.dart';
import '../repositories_abstract/chat_repository.dart';
import '../repositories_abstract/function_tools_repository.dart';

class ChatUseCase {
  final ChatRepository chatRepository;
  final FunctionToolsRepository functionToolsRepository;

  ChatUseCase({required this.chatRepository, required this.functionToolsRepository});

  final Message systemMessage = Message(
      role: "system",
      content:
      "You are an expert in composite materials and structures. Please answer questions related to composites design and manufacturing.");

  Stream<Message> sendMessages(List<Message> messages) {
    final chatHistory = [systemMessage] + messages;
    final functionTools = functionToolsRepository.getAllFunctionTools();
    return chatRepository.sendMessages(
        chatHistory, functionTools);
  }
}