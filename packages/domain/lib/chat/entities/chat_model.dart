class ChatModel {
  final String id;
  final String name;
  final Map<String, dynamic> rawJson;
  final List<String> toolIds;

  const ChatModel({
    required this.id,
    required this.name,
    required this.rawJson,
    this.toolIds = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final info = json['info'];
    final meta = info is Map<String, dynamic> ? info['meta'] : null;
    final rawToolIds = meta is Map<String, dynamic> ? meta['toolIds'] : null;

    return ChatModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Model',
      rawJson: Map<String, dynamic>.from(json),
      toolIds: rawToolIds is List
          ? rawToolIds.map((id) => id.toString()).toList()
          : [],
    );
  }

  static ChatModel fallback({
    String id = 'composites-ai-2026-02-23',
    String name = 'CompositesAI',
  }) {
    return ChatModel(
      id: id,
      name: name,
      rawJson: {
        'id': id,
        'object': 'model',
        'created': 1744316542,
        'owned_by': 'openai',
        'name': name,
        'tags': [],
      },
    );
  }
}
