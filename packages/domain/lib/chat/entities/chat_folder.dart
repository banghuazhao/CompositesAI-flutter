import 'chat.dart';

class ChatFolder {
  final String id;
  final String name;
  final String? parentId;
  final bool isExpanded;
  final List<Chat> chats;

  const ChatFolder({
    required this.id,
    required this.name,
    this.parentId,
    this.isExpanded = false,
    this.chats = const [],
  });

  factory ChatFolder.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final rawChats = items is Map<String, dynamic> ? items['chats'] : null;

    return ChatFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Folder',
      parentId: json['parent_id']?.toString(),
      isExpanded: json['is_expanded'] == true,
      chats: rawChats is List
          ? rawChats
              .whereType<Map<String, dynamic>>()
              .map(Chat.fromJson)
              .where((chat) => chat.id.isNotEmpty)
              .toList()
          : const [],
    );
  }
}
