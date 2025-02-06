class MessageDelta {
  final String id;
  final String object;
  final Delta delta;

  MessageDelta({
    required this.id,
    required this.object,
    required this.delta,
  });

  factory MessageDelta.fromJson(Map<String, dynamic> json) {
    return MessageDelta(
      id: json['id'],
      object: json['object'],
      delta: Delta.fromJson(json['delta']),
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'object': object,
        'delta': delta.toJson(),
      };
}

class Delta {
  final List<DeltaContent> content;

  Delta({required this.content});

  factory Delta.fromJson(Map<String, dynamic> json) {
    var contentList = <DeltaContent>[];
    if (json['content'] != null) {
      contentList = (json['content'] as List)
          .map((i) => DeltaContent.fromJson(i))
          .toList();
    }
    return Delta(
      content: contentList,
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'content': content.map((e) => e.toJson()).toList(),
      };
}

class DeltaContent {
  final int index;
  final String type;
  final DeltaText text;

  DeltaContent({
    required this.index,
    required this.type,
    required this.text,
  });

  factory DeltaContent.fromJson(Map<String, dynamic> json) {
    return DeltaContent(
      index: json['index'],
      type: json['type'],
      text: DeltaText.fromJson(json['text']),
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'index': index,
        'type': type,
        'text': text.toJson(),
      };
}

class DeltaText {
  final String value;

  DeltaText({required this.value});

  factory DeltaText.fromJson(Map<String, dynamic> json) {
    return DeltaText(
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'value': value,
      };
}