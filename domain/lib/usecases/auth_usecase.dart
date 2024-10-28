// lib/domain/usecases/signup_usecase.dart

import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';
import '../repositories_abstract/token_provider.dart';

class AuthUseCase {
  final AuthRepository repository;
  final TokenProvider tokenProvider;

  AuthUseCase({required this.repository, required this.tokenProvider});

  Future<User> signup(String email, String password) async {
    // Add any business logic or validation here if needed
    return await repository.signup(email, password);
  }

  Future<String> login(String email, String password) async {
    // Add any business logic or validation here if needed
    String accessToken = await repository.login(email, password);
    await tokenProvider.saveToken(accessToken);
    return accessToken;
  }

  Future<void> logout() async {
    await repository.logout();
    tokenProvider.deleteToken();
    return;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await tokenProvider.getToken();
    return token != null;
  }
}
