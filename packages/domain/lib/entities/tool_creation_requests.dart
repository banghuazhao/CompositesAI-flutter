class ToolCreationRequest {
  final int id;
  final int userId;
  String title;
  String? toolAvatar;
  String? userName;
  String? description;
  String? instructions;
  String fileUrl;




  ToolCreationRequest({
    required this.id,
    required this.userId,
    required this.title,
    this.toolAvatar,
    this.userName,
    this.description,
    this.instructions,
    required this.fileUrl
  });

  // Factory constructor to create a ToolCreationRequest instance from JSON
  factory ToolCreationRequest.fromJson(Map<String, dynamic> json) {
    return ToolCreationRequest(
      id: json["id"],
      userId: json['userId'],
      title: json['title'],
      toolAvatar: json['toolAvatar'],
      userName: json['userName'],
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      fileUrl: json['fileUrl'],
    );
  }
}
