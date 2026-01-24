import '../entities/chat/message.dart';
import 'package:uuid/uuid.dart';

class Chat {
  final String id;
  String title;

  // Constructor
  Chat({
    required this.id,
    required this.title// Optional parameter for messages
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title
    };
  }
}
