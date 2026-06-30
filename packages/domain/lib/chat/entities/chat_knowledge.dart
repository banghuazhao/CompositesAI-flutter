import 'chat_file.dart';

class ChatKnowledge {
  final String id;
  final String name;
  final String description;
  final List<ChatFile> files;
  final Map<String, dynamic> rawJson;

  const ChatKnowledge({
    required this.id,
    required this.name,
    this.description = '',
    this.files = const [],
    this.rawJson = const {},
  });

  factory ChatKnowledge.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return ChatKnowledge(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Knowledge',
      description: json['description']?.toString() ?? '',
      files: rawFiles is List
          ? rawFiles
              .whereType<Map<String, dynamic>>()
              .map((file) => ChatFile.fromKnowledgeFile(file, json))
              .where((file) => file.id.isNotEmpty)
              .toList()
          : const [],
      rawJson: Map<String, dynamic>.from(json),
    );
  }

  ChatFile toCollectionAttachment() {
    return ChatFile(
      type: 'collection',
      id: id,
      name: name,
      url: '',
      collectionName: id,
      status: 'uploaded',
      file: rawJson.isEmpty ? null : Map<String, dynamic>.from(rawJson),
    );
  }
}
