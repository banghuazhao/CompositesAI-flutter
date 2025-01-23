class Assistant {
  final String id;
  final String object;
  final int createdAt;
  final String name;
  final String description;
  final String model;
  final dynamic instructions;
  final List<dynamic> tools;
  final double topP;
  final double temperature;
  final Map<String, dynamic> toolResources;
  final Map<String, dynamic> metadata;
  final String responseFormat;

  Assistant({
    required this.id,
    required this.object,
    required this.createdAt,
    required this.name,
    required this.description,
    required this.model,
    required this.instructions,
    required this.tools,
    required this.topP,
    required this.temperature,
    required this.toolResources,
    required this.metadata,
    required this.responseFormat,
  });

  /// Parses an [Assistant] from a JSON object
  factory Assistant.fromJson(Map<String, dynamic> json) {
    return Assistant(
      id: json['id'] as String,
      object: json['object'] as String,
      createdAt: json['created_at'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      model: json['model'] as String,
      instructions: json['instructions'], // can be null
      tools: (json['tools'] ?? []) as List<dynamic>,
      topP: (json['top_p'] ?? 1.0).toDouble(),
      temperature: (json['temperature'] ?? 1.0).toDouble(),
      toolResources: (json['tool_resources'] ?? {}) as Map<String, dynamic>,
      metadata: (json['metadata'] ?? {}) as Map<String, dynamic>,
      responseFormat: json['response_format'] as String? ?? 'auto',
    );
  }
}
