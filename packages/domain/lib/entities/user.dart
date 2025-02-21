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
        description: json['description'],
        avatarUrl: json['avatarUrl'],
        isAdmin: json['isAdmin'],
        isCompositeExpert: json['isCompositeExpert']);
  }

  @override
  String toString() {
    return 'User(username: $username, email: $email, name: $name, '
        'description: $description, avatarUrl: $avatarUrl, '
        'isAdmin: $isAdmin, isCompositeExpert: $isCompositeExpert)';
  }
}
