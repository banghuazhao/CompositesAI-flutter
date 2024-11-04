// lib/domain/usecases/signup_usecase.dart

import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';
import '../repositories_abstract/token_provider.dart';

class AuthUseCase {
  final AuthRepository repository;
  final TokenProvider tokenProvider;

  AuthUseCase({required this.repository, required this.tokenProvider});

  Future<User> signup(String username, String email, String password) async {
    return await repository.signup(username, email, password);
  }

  Future<String> login(String username, String password) async {
    String accessToken = await repository.login(username, password);
    await tokenProvider.saveToken(accessToken);
    return accessToken;
  }

  Future<void> logout() async {
    await repository.logout();
    tokenProvider.deleteToken();
    return;
  }

  Future<bool> isLoggedIn() async {
    final token = await tokenProvider.getToken();
    return token != null;
  }

  Future<void> forgetPassword(String email) async {
    return await repository.forgetPassword(email);
  }

  Future<String> resetPasswordVerify(String token) async {
    return await repository.resetPasswordVerify(token);
  }

  Future<String> resetPassword(String token, String newPassword) async {
    return await repository.resetPassword(token, newPassword);
  }
}
