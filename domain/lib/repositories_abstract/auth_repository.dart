// lib/domain/repositories/signup_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup(String email, String password);
  Future<String> login(String email, String password); // New login method
}
