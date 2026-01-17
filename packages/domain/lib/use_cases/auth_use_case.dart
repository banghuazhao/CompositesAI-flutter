// lib/domain/use_cases/signup_use_case.dart

import 'dart:ffi';

import 'package:infrastructure/token_provider.dart';

import '../entities/linkedin_user_profile.dart';
import '../entities/user.dart';
import '../repositories_abstract/auth_repository.dart';

abstract class AuthUseCase {
  Future<User> signup(String email, String password, String verificationCode,
      {String? name});

  Future<User> login(String email, String password);

  Future<void> logout();

  Future<bool> isLoggedIn();

  Future<void> forgetPassword(String email);

  Future<String> resetPassword(
      String email, String newPassword, String confirmationCode);

  Future<void> sendSignupVerificationCode(String email);

  Future<String> updatePassword(String newPassword);

  Future<void> syncUser(String? displayName, String email, String? photoUrl);

  Future<String> validateAppleToken(String identityToken);

  Future<bool> validateGoogleToken(String idToken);

  Future<String> handleAuthorizationCodeFromLinked(String? authorizationCode);

  Future<LinkedinUserProfile> fetchLinkedInUserProfile(String? accessToken);

  Future<Uri> getAuthUrl();
}

class AuthUseCaseImpl implements AuthUseCase {
  final AuthRepository repository;

  AuthUseCaseImpl({required this.repository});

  @override
  Future<User> signup(String email, String password, String verificationCode,
      {String? name}) async {
    return await repository.signup(email, password, verificationCode,
        name: name);
  }

  @override
  Future<User> login(String email, String password) async {
    User user = await repository.login(email, password);
    return user;
  }

  @override
  Future<void> logout() async {
    await repository.logout();
  }

  @override
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await repository.isLoggedIn();
    return isLoggedIn;
  }

  // Change return type to Future<String>
  @override
  Future<void> forgetPassword(String email) async {
    // Assuming repository.forgetPassword returns a reset token
    return await repository.forgetPassword(email);
  }

  @override
  Future<String> resetPassword(
      String email, String newPassword, String confirmationCode) async {
    return await repository.resetPassword(email, newPassword, confirmationCode);
  }

  @override
  Future<void> sendSignupVerificationCode(String email) async {
    return await repository.sendSignupVerificationCode(email);
  }

  @override
  Future<String> updatePassword(String newPassword) async {
    String message = await repository.updatePassword(newPassword);
    return message;
  }

  @override
  Future<void> syncUser(
      String? displayName, String email, String? photoUrl) async {
    await repository.syncUser(displayName, email, photoUrl);
  }

  @override
  Future<String> validateAppleToken(String identityToken) async {
    String email = await repository.validateAppleToken(identityToken);
    return email;
  }

  @override
  Future<bool> validateGoogleToken(String idToken) async {
    bool response = await repository.validateGoogleToken(idToken);
    return response;
  }

  @override
  Future<String> handleAuthorizationCodeFromLinked(
      String? authorizationCode) async {
    return await repository
        .handleAuthorizationCodeFromLinked(authorizationCode);
  }

  @override
  Future<LinkedinUserProfile> fetchLinkedInUserProfile(
      String? accessToken) async {
    return await repository.fetchLinkedInUserProfile(accessToken);
  }

  @override
  Future<Uri> getAuthUrl() async {
    return await repository.getAuthUrl();
  }
}
