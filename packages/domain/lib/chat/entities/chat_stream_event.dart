class ChatStreamEvent {
  final String content;
  final bool replacesContent;
  final ToolStatus? status;
  final String? error;

  const ChatStreamEvent({
    this.content = '',
    this.replacesContent = false,
    this.status,
    this.error,
  });

  bool get hasContent => content.isNotEmpty;
}

class ToolStatus {
  final String action;
  final String description;
  final String query;
  final bool? done;
  final bool hidden;
  final List<String> urls;

  const ToolStatus({
    this.action = '',
    this.description = '',
    this.query = '',
    this.done,
    this.hidden = false,
    this.urls = const [],
  });

  factory ToolStatus.fromJson(Map<String, dynamic> json) {
    final urlsRaw = json['urls'];
    return ToolStatus(
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      query: json['query']?.toString() ?? '',
      done: json['done'] is bool ? json['done'] as bool : null,
      hidden: json['hidden'] == true,
      urls: urlsRaw is List ? urlsRaw.map((e) => e.toString()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (action.isNotEmpty) 'action': action,
        if (description.isNotEmpty) 'description': description,
        if (query.isNotEmpty) 'query': query,
        if (done != null) 'done': done,
        if (hidden) 'hidden': hidden,
        if (urls.isNotEmpty) 'urls': urls,
      };
}
