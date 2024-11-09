// lib/domain/repositories/signup_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup(String email, String password, {String? name});
  Future<String> login(String email, String password);
  Future<void> logout();
  Future<void> forgetPassword(String email);
  Future<String> resetPassword(String email, String newPassword, String confirmationCode);
}
