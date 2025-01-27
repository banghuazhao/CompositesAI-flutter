import '../entities/assistant.dart';

abstract class AssistantsRepository {
  Future<Assistant> createCompositeAssistant();
  String getCompositeAssistantId();
}