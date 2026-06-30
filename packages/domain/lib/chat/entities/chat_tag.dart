class ChatTag {
  final String id;
  final String name;

  const ChatTag({
    required this.id,
    required this.name,
  });

  factory ChatTag.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? json['id']?.toString() ?? '';
    return ChatTag(
      id: json['id']?.toString() ?? name.replaceAll(' ', '_').toLowerCase(),
      name: name,
    );
  }
}
