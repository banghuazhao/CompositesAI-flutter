// lib/domain/repositories/signup_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup(String username, String email, String password);
  Future<String> login(String email, String password, {String? nickname});
  Future<void> logout();
  Future<void> forgetPassword(String email);
  Future<String> resetPassword(String email, String newPassword, String confirmationCode);
}
