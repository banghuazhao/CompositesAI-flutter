import 'package:domain/entities/function_tool.dart';
import 'package:domain/entities/message.dart';
import 'package:domain/repositories_abstract/chat_repository.dart';
import '../data_sources/chat_completion_data_source.dart';

class ChatRepositoryImp implements ChatRepository {
  final ChatCompletionsDataSource chatCompletionsDataSource;

  ChatRepositoryImp({required this.chatCompletionsDataSource});

  @override
  Stream<String> sendMessages(List<Message> messages, List<FunctionTool> functionTools) {
    return chatCompletionsDataSource.sendMessages(messages, functionTools);
  }
}
