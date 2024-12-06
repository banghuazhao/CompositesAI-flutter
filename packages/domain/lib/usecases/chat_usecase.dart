import 'package:domain/domain.dart';

abstract class ChatUseCase {
  Stream<Message> sendMessage(Message newMessage, ChatSession session);
}

class ChatUseCaseImpl implements ChatUseCase {
  final ChatRepository chatRepository;

  ChatUseCaseImpl({required this.chatRepository});

  final Message systemMessage = Message(
      role: "system",
      content:
          "You are an expert in composite materials and structures. Please answer questions related to composites design and manufacturing.");

  Stream<Message> sendMessage(Message newMessage, ChatSession session) {
    final chatMessages = [systemMessage] + session.messages + [newMessage];
    return chatRepository.sendMessages(chatMessages);
  }
}
