import 'package:domain/entities/message.dart';

class ChatChunk {
  String? id;
  String? object;
  int? created;
  String? model;
  String? systemFingerprint;
  List<Choices>? choices;

  ChatChunk(
      {this.id,
      this.object,
      this.created,
      this.model,
      this.systemFingerprint,
      this.choices});

  ChatChunk.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    created = json['created'];
    model = json['model'];
    systemFingerprint = json['system_fingerprint'];
    if (json['choices'] != null) {
      choices = <Choices>[];
      json['choices'].forEach((v) {
        choices!.add(new Choices.fromJson(v));
      });
    }
  }
}

class Choices {
  int? index;
  Delta? delta;
  String? logprobs;
  String? finishReason;

  Choices({this.index, this.delta, this.logprobs, this.finishReason});

  Choices.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    delta = json['delta'] != null ? new Delta.fromJson(json['delta']) : null;
    logprobs = json['logprobs'];
    finishReason = json['finish_reason'];
  }
}

class Delta {
  String? content;
  List<ToolCalls>? toolCalls;

  Delta({this.content, this.toolCalls});

  Delta.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    if (json['tool_calls'] != null) {
      toolCalls = <ToolCalls>[];
      json['tool_calls'].forEach((v) {
        toolCalls!.add(ToolCalls.fromJson(v));
      });
    }
  }
}
