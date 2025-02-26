import '../repositories_abstract/assistants_repository.dart';

abstract class AssistantsUseCase {
  String getCompositeAssistantId();
}

class AssistantsUseCaseImpl implements AssistantsUseCase {
  final AssistantsRepository repository;

  AssistantsUseCaseImpl({required this.repository});

  @override
  String getCompositeAssistantId() {
    return repository.getCompositeAssistantId();
  }
}