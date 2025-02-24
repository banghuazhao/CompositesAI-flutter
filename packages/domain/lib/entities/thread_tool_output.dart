class ThreadToolOutput {
  final String callId;
  final String output;

  ThreadToolOutput({
    required this.callId,
    required this.output,
  });

  // Optional: Add a factory constructor for creating from JSON
  factory ThreadToolOutput.fromJson(Map<String, dynamic> json) {
    return ThreadToolOutput(
      callId: json['tool_call_id'],
      output: json['output'],
    );
  }

  // Optional: Add a method for converting to JSON
  Map<String, dynamic> toJson() => {
    'tool_call_id': callId,
    'output': output,
  };
}