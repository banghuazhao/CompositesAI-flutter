class ChatTool {
  final String id;
  final String name;
  final String description;

  const ChatTool({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory ChatTool.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    String description = '';
    if (meta is Map<String, dynamic>) {
      description = meta['description']?.toString() ?? '';
    }

    return ChatTool(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Tool',
      description: description,
    );
  }
}
