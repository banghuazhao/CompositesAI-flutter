import 'chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> getChatList();  // Fetch sessions from a data source
}
