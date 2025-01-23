class AssistantMessage {
  final String id;
  final String object;
  final int createdAt;
  final String? assistantId;
  final String threadId;
  final String? runId;
  final String role;
  final List<Content> content;
  final List<dynamic> attachments;
  final Map<String, dynamic> metadata;

  AssistantMessage({
    required this.id,
    required this.object,
    required this.createdAt,
    this.assistantId,
    required this.threadId,
    this.runId,
    required this.role,
    required this.content,
    required this.attachments,
    required this.metadata,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    var contentList = <Content>[];
    if (json['content'] != null) {
      contentList = (json['content'] as List)
          .map((i) => Content.fromJson(i))
          .toList();
    }

    return AssistantMessage(
      id: json['id'],
      object: json['object'],
      createdAt: json['created_at'],
      assistantId: json['assistant_id'],
      threadId: json['thread_id'],
      runId: json['run_id'],
      role: json['role'],
      content: contentList,
      attachments: json['attachments'] ?? [],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'object': object,
    'created_at': createdAt,
    'assistant_id': assistantId,
    'thread_id': threadId,
    'run_id': runId,
    'role': role,
    'content': content.map((e) => e.toJson()).toList(),
    'attachments': attachments,
    'metadata': metadata,
  };
}

class Content {
  final String type;
  final TextContent text;

  Content({required this.type, required this.text});

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      type: json['type'],
      text: TextContent.fromJson(json['text']),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text.toJson(),
  };
}

class TextContent {
  final String value;
  final List<dynamic> annotations;

  TextContent({required this.value, required this.annotations});

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      value: json['value'],
      annotations: json['annotations'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'annotations': annotations,
  };
}