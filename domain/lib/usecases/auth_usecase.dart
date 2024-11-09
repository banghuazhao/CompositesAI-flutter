// lib/domain/usecases/signup_usecase.dart


import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';
import '../repositories_abstract/token_provider.dart';

class AuthUseCase {
  final AuthRepository repository;
  final TokenProvider tokenProvider;

  AuthUseCase({required this.repository, required this.tokenProvider});

  Future<User> signup(String email, String password,String verificationCode,{String? name}) async {
    return await repository.signup(email, password, verificationCode, name: name);
  }

  Future<String> login(String email, String password) async {
    String accessToken = await repository.login(email, password);
    await tokenProvider.saveToken(accessToken);
    return accessToken;
  }

  Future<void> logout() async {
    await repository.logout();
    tokenProvider.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await tokenProvider.getToken();
    return token != null;
  }

  // Change return type to Future<String>
  Future<void> forgetPassword(String email) async {
    // Assuming repository.forgetPassword returns a reset token
    return await repository.forgetPassword(email);
  }

  Future<String> resetPassword(email, newPassword, confirmationCode) async {
    return await repository.resetPassword(email, newPassword, confirmationCode);
  }

  Future<void> sendSignupVerificationCode(String email) async {
    return await repository.sendSignupVerificationCode(email);
  }
}

  
