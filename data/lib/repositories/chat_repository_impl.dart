import 'package:domain/entities/message.dart';
import 'package:domain/repositories_abstract/chat_repository.dart';
import '../data_sources/chat_remote_data_source.dart';

class ChatRepositoryImp implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImp({required this.remoteDataSource});

  @override
  Stream<String> sendMessages(List<Message> messages) {
    return remoteDataSource.sendMessages(messages);
  }
}
