import '../entities/assistant.dart';
import '../entities/thread.dart';

abstract class AssistantRepository {
  Future<Assistant> createCompositeAssistant();
  String getCompositeAssistantId();
  Future<Thread> createThread();
}