class ThreadRun {
  final String id;
  final String object;
  final int createdAt;
  final String assistantId;
  final String threadId;
  final String status;
  final int? startedAt;
  final int? expiresAt;
  final int? cancelledAt;
  final int? failedAt;
  final int? completedAt;
  final LastError? lastError;
  final String model;
  final String? instructions;
  final dynamic incompleteDetails; // Can be null or a complex object
  final List<Tool> tools;
  final Map<String, dynamic> metadata;
  final dynamic usage; // Can be null or a complex object
  final double temperature;
  final double topP;
  final int maxPromptTokens;
  final int maxCompletionTokens;
  final TruncationStrategy truncationStrategy;
  final String responseFormat;
  final String toolChoice;
  final bool parallelToolCalls;

  ThreadRun({
    required this.id,
    required this.object,
    required this.createdAt,
    required this.assistantId,
    required this.threadId,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.cancelledAt,
    this.failedAt,
    this.completedAt,
    this.lastError,
    required this.model,
    this.instructions,
    this.incompleteDetails,
    required this.tools,
    required this.metadata,
    this.usage,
    required this.temperature,
    required this.topP,
    required this.maxPromptTokens,
    required this.maxCompletionTokens,
    required this.truncationStrategy,
    required this.responseFormat,
    required this.toolChoice,
    required this.parallelToolCalls,
  });

  factory ThreadRun.fromJson(Map<String, dynamic> json) {
    var toolsList = <Tool>[];
    if (json['tools'] != null) {
      toolsList = (json['tools'] as List).map((i) => Tool.fromJson(i)).toList();
    }

    return ThreadRun(
      id: json['id'],
      object: json['object'],
      createdAt: json['created_at'],
      assistantId: json['assistant_id'],
      threadId: json['thread_id'],
      status: json['status'],
      startedAt: json['started_at'],
      expiresAt: json['expires_at'],
      cancelledAt: json['cancelled_at'],
      failedAt: json['failed_at'],
      completedAt: json['completed_at'],
      lastError: json['last_error'] != null ? LastError.fromJson(
          json['last_error']) : null,
      model: json['model'],
      instructions: json['instructions'],
      incompleteDetails: json['incomplete_details'],
      tools: toolsList,
      metadata: json['metadata'] ?? {},
      usage: json['usage'],
      temperature: json['temperature']?.toDouble() ?? 0.0,
      topP: json['top_p']?.toDouble() ?? 0.0,
      maxPromptTokens: json['max_prompt_tokens'] ?? 0,
      maxCompletionTokens: json['max_completion_tokens'] ?? 0,
      truncationStrategy: TruncationStrategy.fromJson(
          json['truncation_strategy']),
      responseFormat: json['response_format'],
      toolChoice: json['tool_choice'],
      parallelToolCalls: json['parallel_tool_calls'] ?? false,
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'object': object,
        'created_at': createdAt,
        'assistant_id': assistantId,
        'thread_id': threadId,
        'status': status,
        'started_at': startedAt,
        'expires_at': expiresAt,
        'cancelled_at': cancelledAt,
        'failed_at': failedAt,
        'completed_at': completedAt,
        'last_error': lastError?.toJson(),
        'model': model,
        'instructions': instructions,
        'incomplete_details': incompleteDetails,
        'tools': tools.map((e) => e.toJson()).toList(),
        'metadata': metadata,
        'usage': usage,
        'temperature': temperature,
        'top_p': topP,
        'max_prompt_tokens': maxPromptTokens,
        'max_completion_tokens': maxCompletionTokens,
        'truncation_strategy': truncationStrategy.toJson(),
        'response_format': responseFormat,
        'tool_choice': toolChoice,
        'parallel_tool_calls': parallelToolCalls,
      };
}

class LastError {
  // Define properties for last_error if it's not always null
  // Example:
  final String? code;
  final String? message;

  LastError({this.code, this.message});

  factory LastError.fromJson(Map<String, dynamic> json) {
    return LastError(
      code: json['code'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'code': code,
        'message': message,
      };
}

class Tool {
  final String type;

  Tool({required this.type});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'type': type,
      };
}

class TruncationStrategy {
  final String type;
  final dynamic lastMessages; // Can be null or a number

  TruncationStrategy({required this.type, this.lastMessages});

  factory TruncationStrategy.fromJson(Map<String, dynamic> json) {
    return TruncationStrategy(
      type: json['type'],
      lastMessages: json['last_messages'],
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'type': type,
        'last_messages': lastMessages,
      };
}