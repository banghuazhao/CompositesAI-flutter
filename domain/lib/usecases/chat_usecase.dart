import '../entities/message.dart';
import '../repositories_abstract/chat_repository.dart';

class ChatUseCase {
  final ChatRepository chatRepository;

  ChatUseCase(
      {required this.chatRepository});

  final Message systemMessage = Message(
      role: "system",
      content:
          "You are an expert in composite materials and structures. Please answer questions related to composites design and manufacturing.");

  Stream<Message> sendMessages(List<Message> messages) {
    final chatHistory = [systemMessage] + messages;
    return chatRepository.sendMessages(chatHistory);
  }
}
