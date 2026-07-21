class ChatConfiguration {
  final List<String> defaultModelIds;
  final List<String> defaultPrompts;

  const ChatConfiguration({
    this.defaultModelIds = const [],
    this.defaultPrompts = const [],
  });

  factory ChatConfiguration.fromJson(Map<String, dynamic> json) {
    final rawModels = json['default_models'];
    final defaultModelIds = rawModels is String
        ? rawModels
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList()
        : rawModels is List
            ? rawModels
                .map((id) => id.toString().trim())
                .where((id) => id.isNotEmpty)
                .toList()
            : <String>[];

    final rawPrompts = json['default_prompt_suggestions'];
    final defaultPrompts = rawPrompts is List
        ? rawPrompts
            .map((prompt) {
              if (prompt is Map) return prompt['content']?.toString().trim();
              return prompt?.toString().trim();
            })
            .whereType<String>()
            .where((prompt) => prompt.isNotEmpty)
            .toList()
        : <String>[];

    return ChatConfiguration(
      defaultModelIds: defaultModelIds,
      defaultPrompts: defaultPrompts,
    );
  }
}
