import 'message.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  final String id;
  final String title;
  List<Message> messages;

  // Constructor
  ChatSession({
    String? id,
    required this.title,
    List<Message>? messages, // Optional parameter for messages
  })  : id = id ?? const Uuid().v1(),
        messages =
            messages ?? []; // Initialize messages as an empty list if null

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    var messagesJson = json['messages'] as List;
    List<Message> messages =
        messagesJson.map((msg) => Message.fromJson(msg)).toList();

    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => (msg as Message).toJson()).toList(),
    };
  }
}
