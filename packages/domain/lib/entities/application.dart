class CompositeExpertRequest {
  final int userId;
  String? reason;


  CompositeExpertRequest({
    required this.userId,
    this.reason,
  });

  // Factory constructor to create a User instance from JSON
  factory CompositeExpertRequest.fromJson(Map<String, dynamic> json) {
    return CompositeExpertRequest(
      userId: json['userId'],
      reason: json['reason'] ?? '',
    );
  }
}
