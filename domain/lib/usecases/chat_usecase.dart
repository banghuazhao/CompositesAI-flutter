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
      "You are an expert assistant specialized in composite materials. Your role is to provide accurate and detailed answers to questions related to composite material properties, design, calculations, and analysis.");

  Stream<Message> sendMessages(List<Message> messages) {
    final chatHistory = [systemMessage] + messages;
    final functionTools = functionToolsRepository.getAllFunctionTools();
    return chatRepository.sendMessages(
        chatHistory, functionTools);
  }
}