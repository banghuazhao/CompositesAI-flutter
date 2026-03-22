import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String role;
  String content;
  int timestamp;
  List<String> childrenIds = [];
  String? parentId;
  List<String> models = [];
  String modelName;

  Message(
      {required this.role,
      this.content = '',
      this.parentId,
      this.childrenIds = const []})
      : id = const Uuid().v4(),
        timestamp = DateTime.now().microsecondsSinceEpoch ~/ 1000,
        models = ["composites-ai-2026-02-23"],
        modelName = role == 'assistant' ? 'CompositeAI' : '';

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        role = json['role'] ?? 'user',
        content = json['content'] ?? '',
        timestamp = json['timestamp'] ?? 0,
        childrenIds = List<String>.from(json['childrenIds'] ?? []),
        parentId = json['parentId'],
        modelName = json['modelName'] ?? '',
        models = List<String>.from(json['models'] ?? []);

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['timestamp'] = timestamp;
    data['childrenIds'] = childrenIds;
    data['parentId'] = parentId;
    data['models'] = models;
    if (role == 'assistant') {
      data['modelName'] = modelName;
      data['userContext'] = null;
      data['modelIdx'] = 0;
      data['done'] = true;
      data['thinking_elapsed'] = 5;
    }
    return data;
  }

  Map<String, dynamic> toCompletedJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['timestamp'] = timestamp;
    return data;
  }

  Map<String, dynamic> toHistoryJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[id] = toJson();
    return data;
  }
}
