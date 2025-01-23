import 'package:domain/entities/assistant_message.dart';
import '../entities/message.dart';
import '../entities/thread.dart';

abstract class MessagesRepository {
  Future<AssistantMessage> createMessage(Thread thread, Message message);
}