class MessageDeltaDTO {
  final String id;
  final String object;
  final ChoiceDTO choice;

  MessageDeltaDTO({
    required this.id,
    required this.object,
    required this.choice,
  });

  factory MessageDeltaDTO.fromJson(Map<String, dynamic> json) {
    final choicesRaw = json['choices'];
    if (choicesRaw is! List || choicesRaw.isEmpty) {
      return MessageDeltaDTO(
        id: json['id'] as String? ?? '',
        object: json['object'] as String? ?? '',
        choice: ChoiceDTO(
          delta: DeltaDTO(content: null),
          finishReason: null,
        ),
      );
    }
    final first = choicesRaw.first;
    if (first is! Map<String, dynamic>) {
      return MessageDeltaDTO(
        id: json['id'] as String? ?? '',
        object: json['object'] as String? ?? '',
        choice: ChoiceDTO(
          delta: DeltaDTO(content: null),
          finishReason: null,
        ),
      );
    }
    return MessageDeltaDTO(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      choice: ChoiceDTO.fromJson(first),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'object': object,
        'choices': [choice.toJson()],
      };
}

class ChoiceDTO {
  final DeltaDTO delta;
  final String? finishReason;

  ChoiceDTO({
    required this.delta,
    this.finishReason,
  });

  factory ChoiceDTO.fromJson(Map<String, dynamic> json) {
    final deltaRaw = json['delta'];
    final DeltaDTO delta = deltaRaw is Map<String, dynamic>
        ? DeltaDTO.fromJson(deltaRaw)
        : DeltaDTO(content: null);
    return ChoiceDTO(
      delta: delta,
      finishReason: json['finish_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'delta': delta.toJson(),
        'finish_reason': finishReason,
      };
}

class DeltaDTO {
  final String? content;

  DeltaDTO({this.content});

  factory DeltaDTO.fromJson(Map<String, dynamic> json) {
    return DeltaDTO(
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
      };
}
