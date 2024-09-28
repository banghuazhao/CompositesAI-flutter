import '../entities/message.dart';

abstract class ChatRepository {
  Stream<String> sendMessages(List<Message> messages);
}