class User {
  final String username;
  final String email;
  final String? name;
  final String? description;
  final String? avatarUrl;

  User(
      {required this.username,
      required this.email,
      this.name,
      this.description,
      this.avatarUrl});

  // Factory constructor to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
