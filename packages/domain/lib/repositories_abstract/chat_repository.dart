import '../entities/message.dart';

abstract class ChatRepository {
  Stream<Message> sendMessages(List<Message> messages);
}
