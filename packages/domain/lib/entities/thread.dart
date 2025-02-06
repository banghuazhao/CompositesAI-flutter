import 'package:domain/entities/thread_response.dart';

class Thread extends ThreadResponse {
  final String id;
  final String object;
  final int createdAt;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> toolResources;

  Thread({
    required this.id,
    required this.object,
    required this.createdAt,
    required this.metadata,
    required this.toolResources,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'],
      object: json['object'],
      createdAt: json['created_at'],
      metadata: json['metadata'] ?? {},
      toolResources: json['tool_resources'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'object': object,
    'created_at': createdAt,
    'metadata': metadata,
    'tool_resources': toolResources,
  };
}