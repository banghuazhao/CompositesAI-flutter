class ChatTool {
  final String id;
  final String name;
  final String description;
  final String content;
  final Map<String, dynamic> rawJson;
  final Map<String, dynamic> meta;

  const ChatTool({
    required this.id,
    required this.name,
    this.description = '',
    this.content = '',
    this.rawJson = const {},
    this.meta = const {},
  });

  factory ChatTool.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return ChatTool(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Tool',
      description: meta['description']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      rawJson: Map<String, dynamic>.from(json),
      meta: meta,
    );
  }

  bool get isServerTool => id.startsWith('server:');

  Map<String, dynamic> toAdminJson({
    String? id,
    String? name,
    String? description,
    String? content,
  }) {
    final updatedMeta = Map<String, dynamic>.from(meta);
    updatedMeta['description'] = description ?? this.description;

    return {
      'id': id ?? this.id,
      'name': name ?? this.name,
      'content': content ?? this.content,
      'meta': updatedMeta,
      'access_control': rawJson['access_control'],
    };
  }
}
