class Message {
  final String role;
  String content;

  Message({required this.role, required this.content});

  // Factory constructor for creating a new Message instance from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
    );
  }

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}