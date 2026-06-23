import 'package:uuid/uuid.dart';

import 'chat_file.dart';
import 'chat_stream_event.dart';

class Message {
  final String id;
  final String role;
  String content;
  int timestamp;
  List<String> childrenIds = [];
  String? parentId;
  List<String> models = [];
  String model;
  String modelName;
  int thinkingElapsed = 0;
  bool isDone = false;
  List<ToolStatus> statusHistory = [];
  List<ChatFile> files = [];
  // Client-side cache for evaluation update.
  // Filled after first POST /evaluations/feedback returns FeedbackModel.id.
  String? feedbackId;

  Message(
      {required this.role,
      this.content = '',
      this.parentId,
      this.childrenIds = const [],
      List<ChatFile> files = const [],
      List<ToolStatus> statusHistory = const []})
      : id = const Uuid().v4(),
        timestamp = DateTime.now().microsecondsSinceEpoch ~/ 1000,
        statusHistory = List<ToolStatus>.from(statusHistory),
        files = List<ChatFile>.from(files),
        models = ["composites-ai-2026-02-23"],
        model = "composites-ai-2026-02-23",
        modelName = role == 'assistant' ? 'CompositeAI' : '';

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        role = json['role'] ?? 'user',
        content = json['content'] ?? '',
        timestamp = json['timestamp'] ?? 0,
        childrenIds = List<String>.from(json['childrenIds'] ?? []),
        parentId = json['parentId'],
        modelName = json['modelName'] ?? '',
        models = List<String>.from(json['models'] ?? []),
        model = json['model'] ?? '',
        thinkingElapsed = json['thinking_elapsed'] ?? 0,
        isDone = json['done'] ?? false,
        files = _parseFiles(json),
        statusHistory = _parseStatusHistory(json),
        feedbackId = json['feedbackId'] ?? json['feedback_id'];

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['timestamp'] = timestamp;
    data['childrenIds'] = childrenIds;
    data['parentId'] = parentId;
    if (files.isNotEmpty) {
      data['files'] = files.map((file) => file.toJson()).toList();
    }

    if (role == 'assistant') {
      data['model'] = model;
      data['modelName'] = modelName;
      data['userContext'] = null;
      data['modelIdx'] = 0;
      if (isDone) {
        data['done'] = true;
      }
      data['thinking_elapsed'] = thinkingElapsed;
      if (statusHistory.isNotEmpty) {
        data['statusHistory'] =
            statusHistory.map((status) => status.toJson()).toList();
      }
    } else {
      data['models'] = models;
    }
    return data;
  }

  Map<String, dynamic> toCompletedJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    data['timestamp'] = timestamp;
    if (files.isNotEmpty) {
      data['files'] = files.map((file) => file.toJson()).toList();
    }
    return data;
  }

  Map<String, dynamic> toHistoryJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[id] = toJson();
    return data;
  }

  static List<ToolStatus> _parseStatusHistory(Map<String, dynamic> json) {
    final rawStatuses = json['statusHistory'] ?? json['status_history'];
    final rawStatus = json['status'];
    final statuses = <ToolStatus>[];

    if (rawStatuses is List) {
      for (final raw in rawStatuses) {
        if (raw is Map<String, dynamic>) {
          statuses.add(ToolStatus.fromJson(raw));
        }
      }
    }
    if (rawStatus is Map<String, dynamic>) {
      statuses.add(ToolStatus.fromJson(rawStatus));
    }

    return statuses;
  }

  static List<ChatFile> _parseFiles(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    if (rawFiles is! List) return <ChatFile>[];

    return rawFiles
        .whereType<Map<String, dynamic>>()
        .map(ChatFile.fromJson)
        .where((file) => file.id.isNotEmpty || file.url.isNotEmpty)
        .toList();
  }
}
