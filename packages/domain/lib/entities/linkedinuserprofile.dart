class LinkedinUserProfile {
  final String email;
  final String? name;
  final String? picture;

  LinkedinUserProfile({required this.email, this.name, this.picture});

  factory LinkedinUserProfile.fromJson(Map<String, dynamic> json) {
    return LinkedinUserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      picture: json['picture'],
    );
  }

  @override
  String toString() {
    return 'LinkedinUserProfile(name: $name, email: $email, picture: $picture)';
  }
}
