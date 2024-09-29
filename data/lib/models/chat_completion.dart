class ChatCompletion {
  String? id;
  String? object;
  int? created;
  String? model;
  String? systemFingerprint;
  List<Choices>? choices;

  ChatCompletion(
      {this.id,
        this.object,
        this.created,
        this.model,
        this.systemFingerprint,
        this.choices});

  ChatCompletion.fromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['object'] = this.object;
    data['created'] = this.created;
    data['model'] = this.model;
    data['system_fingerprint'] = this.systemFingerprint;
    if (this.choices != null) {
      data['choices'] = this.choices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Choices {
  int? index;
  Delta? delta;
  Null? logprobs;
  Null? finishReason;

  Choices({this.index, this.delta, this.logprobs, this.finishReason});

  Choices.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    delta = json['delta'] != null ? new Delta.fromJson(json['delta']) : null;
    logprobs = json['logprobs'];
    finishReason = json['finish_reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['index'] = this.index;
    if (this.delta != null) {
      data['delta'] = this.delta!.toJson();
    }
    data['logprobs'] = this.logprobs;
    data['finish_reason'] = this.finishReason;
    return data;
  }
}

class Delta {
  String? content;

  Delta({this.content});

  Delta.fromJson(Map<String, dynamic> json) {
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['content'] = this.content;
    return data;
  }
}