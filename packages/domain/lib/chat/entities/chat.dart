class Chat {
  final String id;
  String title;
  int updatedAt;
  int createdAt;

  /// Pinned state is not stored here: use [GET /chats/{id}/pinned], the Pinned vs
  /// Previous list partition, or optimistic UI after POST …/pin.
  Chat({
    required this.id,
    required this.title,
    this.updatedAt = 0,
    this.createdAt = 0,
  });

  /// GET /chats, nested `chat`, etc. Ignores extra fields (e.g. `pinned` on ChatResponse).
  factory Chat.fromJson(Map<String, dynamic> json) {
    final bool hasTopLevel = json['id'] != null || json['title'] != null;
    final map = hasTopLevel ? json : (json['chat'] is Map<String, dynamic> ? json['chat'] as Map<String, dynamic> : json);

    return Chat(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      updatedAt: map['updated_at'] as int? ?? 0,
      createdAt: map['created_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }
}
