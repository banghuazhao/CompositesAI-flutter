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
    final choices = json['choices'] as List;
    return MessageDeltaDTO(
      id: json['id'] as String,
      object: json['object'] as String,
      choice: ChoiceDTO.fromJson(choices.first as Map<String, dynamic>),
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
    return ChoiceDTO(
      delta: DeltaDTO.fromJson(json['delta'] as Map<String, dynamic>),
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
