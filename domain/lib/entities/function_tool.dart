class FunctionTool {
  final String name;
  final String description;
  final bool strict;
  final Map<String, dynamic> parameters;

  FunctionTool({
    required this.name,
    required this.description,
    this.strict = false,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'function',
      'strict': strict,
      "function": {
        'name': name,
        'description': description,
        'parameters': parameters,
      }
    };
  }
}