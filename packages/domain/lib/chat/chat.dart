import '../entities/chat/message.dart';
import 'package:uuid/uuid.dart';

class Chat {
  final String id;
  String title;
  bool pinned;

  Chat({
    required this.id,
    required this.title,
    this.pinned = false,
  });

  /// GET /chats/all: id, title, pinned at top level. Other endpoints may nest under "chat".
  factory Chat.fromJson(Map<String, dynamic> json) {
    final bool hasTopLevel = json['id'] != null || json['title'] != null;
    final map = hasTopLevel ? json : (json['chat'] is Map<String, dynamic> ? json['chat'] as Map<String, dynamic> : json);
    return Chat(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      pinned: map['pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pinned': pinned,
    };
  }
}
