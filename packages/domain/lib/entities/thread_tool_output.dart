class ThreadToolOutput {
  final String callId;
  final String output;

  ThreadToolOutput({
    required this.callId,
    required this.output,
  });

  factory ThreadToolOutput.fromJson(Map<String, dynamic> json) {
    return ThreadToolOutput(
      callId: json['tool_call_id'],
      output: json['output'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tool_call_id': callId,
    'output': output,
  };
}