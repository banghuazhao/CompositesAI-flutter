class User {
  final String username;
  final String email;
  final String? name;

  User({required this.username, required this.email, this.name});

  // Factory constructor to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
    );
  }
}
