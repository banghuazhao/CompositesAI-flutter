class ChatModel {
  final String id;
  final String name;
  final String? baseModelId;
  final String description;
  final bool isActive;
  final Map<String, dynamic> rawJson;
  final Map<String, dynamic> meta;
  final Map<String, dynamic> params;
  final List<String> toolIds;

  const ChatModel({
    required this.id,
    required this.name,
    this.baseModelId,
    this.description = '',
    this.isActive = true,
    required this.rawJson,
    this.meta = const {},
    this.params = const {},
    this.toolIds = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final info = json['info'];
    final rawMeta =
        json['meta'] ?? (info is Map<String, dynamic> ? info['meta'] : null);
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};
    final rawParams = json['params'];
    final params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : <String, dynamic>{};
    final rawToolIds = meta['toolIds'] ?? meta['tool_ids'];

    return ChatModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Model',
      baseModelId: json['base_model_id']?.toString(),
      description: meta['description']?.toString() ?? '',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      rawJson: Map<String, dynamic>.from(json),
      meta: meta,
      params: params,
      toolIds: rawToolIds is List
          ? rawToolIds.map((id) => id.toString()).toList()
          : [],
    );
  }

  Map<String, dynamic> toAdminJson({
    String? id,
    String? name,
    String? baseModelId,
    String? description,
    bool? isActive,
    List<String>? toolIds,
  }) {
    final updatedMeta = Map<String, dynamic>.from(meta);
    updatedMeta['description'] = description ?? this.description;
    updatedMeta['toolIds'] = toolIds ?? this.toolIds;

    return {
      'id': id ?? this.id,
      'base_model_id': _emptyToNull(baseModelId ?? this.baseModelId),
      'name': name ?? this.name,
      'meta': updatedMeta,
      'params': params,
      'access_control': rawJson['access_control'],
      'is_active': isActive ?? this.isActive,
    };
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

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
