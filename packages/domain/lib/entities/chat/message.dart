import 'package:domain/entities/chat/chat_response.dart';
import 'package:uuid/uuid.dart';

class Message extends ChatResponse {
  String id;
  final String role;
  bool? isLiked;
  String content;
  int timestamp;

  Message({this.id = '', required this.role, this.isLiked, this.content = '', this.timestamp = 0});

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        role = json['role'] ?? 'user',
        isLiked = json['isLiked'],
        content = json['content'] ?? '',
        timestamp = json['timestamp'] ?? 0;

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['isLiked'] = isLiked;
    data['timestamp'] = timestamp;
    return data;
  }
}
