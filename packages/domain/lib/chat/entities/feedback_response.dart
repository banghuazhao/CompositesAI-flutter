class FeedbackResponse {
  final String id;
  final String? userId;
  final int? version;
  final String? type;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? snapshot;
  final int? createdAt;
  final int? updatedAt;

  FeedbackResponse({
    required this.id,
    this.userId,
    this.version,
    this.type,
    this.data,
    this.meta,
    this.snapshot,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      throw FormatException('Feedback response missing id');
    }

    return FeedbackResponse(
      id: id,
      userId: json['user_id']?.toString(),
      version: json['version'] is int ? json['version'] as int : null,
      type: json['type']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
      snapshot: json['snapshot'] is Map<String, dynamic>
          ? json['snapshot'] as Map<String, dynamic>
          : null,
      createdAt:
          json['created_at'] is int ? json['created_at'] as int : null,
      updatedAt:
          json['updated_at'] is int ? json['updated_at'] as int : null,
    );
  }
}

