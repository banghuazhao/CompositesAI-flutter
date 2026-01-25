// lib/domain/repositories/signup_repository.dart

import '../entities/linkedin_user_profile.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup(String email, String password, String verificationCode,{String? name});
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<void> forgetPassword(String email);
  Future<String> resetPassword(String email, String newPassword, String confirmationCode);
  Future<void> sendSignupVerificationCode(String email);
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<void> syncUser(String? displayName, String email, String? photoUrl);
  Future<String> validateAppleToken(String identityToken);
  Future<bool> validateGoogleToken(String idToken);
  Future<String> handleAuthorizationCodeFromLinked(String? authorizationCode);
  Future<LinkedinUserProfile> fetchLinkedInUserProfile(String? accessToken);
  Future<Uri> getAuthUrl();
}
