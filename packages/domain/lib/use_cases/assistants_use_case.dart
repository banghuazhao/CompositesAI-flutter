import 'package:domain/entities/assistant.dart';

import '../repositories_abstract/assistants_repository.dart';

abstract class AssistantsUseCase {
  Future<Assistant> createCompositeAssistant();
  String getCompositeAssistantId();
}

class AssistantsUseCaseImpl implements AssistantsUseCase {
  final AssistantsRepository repository;

  AssistantsUseCaseImpl({required this.repository});

  @override
  Future<Assistant> createCompositeAssistant() async {
    return await repository.createCompositeAssistant();
  }

  @override
  String getCompositeAssistantId() {
    return repository.getCompositeAssistantId();
  }
}