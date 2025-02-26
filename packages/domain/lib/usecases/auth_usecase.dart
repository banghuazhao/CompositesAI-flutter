// lib/domain/usecases/signup_usecase.dart


import 'package:infrastructure/token_provider.dart';

import '../entities/linkedin_user_profile.dart';
import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';

abstract class AuthUseCase {
  Future<User> signup(String email, String password, String verificationCode,{String? name});
  Future<String> login(String email, String password);
  Future<void> logout();
  Future<void> forgetPassword(String email);
  Future<String> resetPassword(String email, String newPassword, String confirmationCode);
  Future<void> sendSignupVerificationCode(String email);
  Future<String> updatePassword(String newPassword);
  Future<void> syncUser(String? displayName, String email, String? photoUrl);
  Future<String> validateAppleToken(String identityToken);
  Future<bool> validateGoogleToken(String idToken);
  Future<bool> isLoggedIn();
  Future<String> handleAuthorizationCodeFromLinked(String? authorizationCode);
  Future<LinkedinUserProfile> fetchLinkedInUserProfile(String? accessToken);
  Future<Uri> getAuthUrl();
}

class AuthUseCaseImpl implements AuthUseCase {
  final AuthRepository repository;
  final TokenProvider tokenProvider;

  AuthUseCaseImpl({required this.repository, required this.tokenProvider});

  Future<User> signup(String email, String password, String verificationCode,
      {String? name}) async {
    return await repository.signup(email, password, verificationCode, name: name);
  }

  Future<String> login(String email, String password) async {
    String accessToken = await repository.login(email, password);
    await tokenProvider.saveToken(accessToken);
    return accessToken;
  }

  Future<void> logout() async {
    final accessToken = await tokenProvider.getToken();
    if (accessToken == null || accessToken == "") {
      return;
    }
    try {
      await repository.logout();
    } catch (e) {
      rethrow;
    } finally {
      await tokenProvider.deleteToken();
    }
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

  Future<String> resetPassword(String email, String newPassword, String confirmationCode) async {
    return await repository.resetPassword(email, newPassword, confirmationCode);
  }

  Future<void> sendSignupVerificationCode(String email) async {
    return await repository.sendSignupVerificationCode(email);
  }

  Future<String> updatePassword(String newPassword) async {
    String message =  await repository.updatePassword(newPassword);
    return message;
  }

  Future<void> syncUser(String? displayName, String email, String? photoUrl) async {
    String accessToken = await repository.syncUser(displayName, email, photoUrl);
    await tokenProvider.saveToken(accessToken);
    return;
  }

  Future<String> validateAppleToken(String identityToken) async {
    String email = await repository.validateAppleToken(identityToken);
    return email;
  }
  Future<bool> validateGoogleToken(String idToken) async {
    bool response =  await repository.validateGoogleToken(idToken);
    return response;
  }
  Future<String> handleAuthorizationCodeFromLinked(String? authorizationCode) async {
    return await repository.handleAuthorizationCodeFromLinked(authorizationCode);
  }

  Future<LinkedinUserProfile> fetchLinkedInUserProfile(String? accessToken) async {
    return await repository.fetchLinkedInUserProfile(accessToken);
  }
  Future<Uri> getAuthUrl() async {
    return await repository.getAuthUrl();
  }


}