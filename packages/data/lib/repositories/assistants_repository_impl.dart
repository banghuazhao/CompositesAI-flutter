import 'package:http/http.dart' as http;
import 'package:domain/repositories_abstract/assistants_repository.dart';


class AssistantsRepositoryImpl implements AssistantsRepository {
  final http.Client client;

  AssistantsRepositoryImpl({required this.client});

  @override
  String getCompositeAssistantId() {
    return "asst_pxUDI3A9Q8afCqT9cqgUkWQP";
  }
}
