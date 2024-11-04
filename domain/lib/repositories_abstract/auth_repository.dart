// lib/domain/repositories/signup_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup(String username, String email, String password);
  Future<String> login(String username, String password);
  Future<void> logout();
  Future<void> forgetPassword(String email);
  Future<String> resetPasswordVerify(String token);
  Future<String> resetPassword(String token, String newPassword);
}
