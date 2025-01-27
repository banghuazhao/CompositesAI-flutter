import 'package:domain/entities/thread_message.dart';

abstract class MessagesRepository {
  Future<ThreadMessage> createMessage(String threadId, String message);
  Future<List<ThreadMessage>> listMessage(String threadId);
  Future<ThreadMessage> retrieveMessage(String threadId, String messageId);
}