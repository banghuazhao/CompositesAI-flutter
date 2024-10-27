// lib/domain/usecases/signup_usecase.dart

import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';

class AuthUseCase {
  final AuthRepository repository;

  AuthUseCase({required this.repository});

  Future<User> signup(String email, String password) async {
    // Add any business logic or validation here if needed
    return await repository.signup(email, password);
  }

  Future<String> login(String email, String password) async {
    // Add any business logic or validation here if needed
    return await repository.login(email, password);
  }
}
