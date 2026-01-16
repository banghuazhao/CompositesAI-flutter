class User {
  final String? username;
  final String email;
  String? name;
  final String? description;
  final String? avatarUrl;
  final bool isAdmin; // Value from the database
  bool isCompositeExpert;

  User({
    this.username,
    required this.email,
    this.name,
    this.description,
    this.avatarUrl,
    this.isAdmin = false, // Optional: Provide a default in Dart
    this.isCompositeExpert = false,
  });

  // Factory constructor to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        name: json['name'],
        description: json['description'] ?? '',
        avatarUrl: json['profile_image_url'],
        isAdmin: json['role'] == "admin",
        isCompositeExpert: json['is_expert']);
  }

  @override
  String toString() {
    return 'User(username: $username, email: $email, name: $name, '
        'isAdmin: $isAdmin, isCompositeExpert: $isCompositeExpert)';
  }
}
