import 'package:domain/entities/assistant.dart';
import 'package:domain/entities/assistant_message.dart';

import '../entities/thread.dart';
import '../repositories_abstract/assistant_repository.dart';

abstract class AssistantUseCase {
  Future<Assistant> createCompositeAssistant();
  String getCompositeAssistantId();
}

class AssistantUseCaseImpl implements AssistantUseCase {
  final AssistantRepository repository;

  AssistantUseCaseImpl({required this.repository});

  @override
  Future<Assistant> createCompositeAssistant() async {
    return await repository.createCompositeAssistant();
  }

  @override
  String getCompositeAssistantId() {
    return repository.getCompositeAssistantId();
  }
}