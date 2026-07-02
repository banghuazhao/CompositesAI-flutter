import 'user.dart';

class ExpertUpgradeRequest {
  final String id;
  final String userId;
  final String requestedLevel;
  final String status;
  final String requesterNotes;
  final int createdAt;
  final int updatedAt;
  final User? user;

  const ExpertUpgradeRequest({
    required this.id,
    required this.userId,
    required this.requestedLevel,
    required this.status,
    required this.requesterNotes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  bool get isPending => status == 'pending';

  factory ExpertUpgradeRequest.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];

    return ExpertUpgradeRequest(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      requestedLevel:
          (json['requested_level'] ?? json['requestedLevel'])?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requesterNotes:
          (json['requester_notes'] ?? json['requesterNotes'])?.toString() ?? '',
      createdAt: _parseInt(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseInt(json['updated_at'] ?? json['updatedAt']),
      user: rawUser is Map<String, dynamic> ? User.fromJson(rawUser) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
