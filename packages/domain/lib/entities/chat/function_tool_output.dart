class FunctionToolOutput {
  final String callId;
  final String output;

  FunctionToolOutput({
    required this.callId,
    required this.output,
  });

  factory FunctionToolOutput.fromJson(Map<String, dynamic> json) {
    return FunctionToolOutput(
      callId: json['tool_call_id'],
      output: json['output'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tool_call_id': callId,
    'output': output,
  };
}