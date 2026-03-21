class Message {
  String id;
  final String role;
  String content;
  int timestamp;
  List<String> childrenIds = [];
  List<String> models = [];

  Message(
      {this.id = '',
      required this.role,
      this.content = '',
      this.childrenIds = const []})
      : timestamp = DateTime.now().microsecondsSinceEpoch ~/ 1000,
        models = ["composites-ai-2026-02-23"];

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        role = json['role'] ?? 'user',
        content = json['content'] ?? '',
        timestamp = json['timestamp'] ?? 0,
        childrenIds = List<String>.from(json['childrenIds'] ?? []),
        models = List<String>.from(json['models'] ?? []);

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['timestamp'] = timestamp;
    data['childrenIds'] = childrenIds;
    data['models'] = models;
    return data;
  }

  Map<String, dynamic> toHistoryJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[id] = toJson();
    return data;
  }
}
