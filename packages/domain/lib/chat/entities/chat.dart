import 'message.dart';
import 'package:uuid/uuid.dart';

class Chat {
  final String id;
  String title;
  int updatedAt;
  int createdAt;

  Chat({
    required this.id,
    required this.title,
    this.updatedAt = 0,
    this.createdAt = 0,
  });

  /// GET /chats/all: id, title, pinned at top level. Other endpoints may nest under "chat".
  factory Chat.fromJson(Map<String, dynamic> json) {
    final bool hasTopLevel = json['id'] != null || json['title'] != null;
    final map = hasTopLevel ? json : (json['chat'] is Map<String, dynamic> ? json['chat'] as Map<String, dynamic> : json);
    return Chat(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      updatedAt: map['updated_at'] as int? ?? 0,
      createdAt: map['created_at'] as int? ?? 0
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt,
      'createdAt': createdAt
    };
  }
}
