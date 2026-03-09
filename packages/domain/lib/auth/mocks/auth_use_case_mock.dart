import 'package:mockito/mockito.dart';

import '../entities/auth_session.dart';
import '../entities/user.dart';
import '../use_cases/auth_use_case.dart';

class MockAuthUseCase extends Mock implements AuthUseCase {
  @override
  Future<User> login(String email, String password) =>
      super.noSuchMethod(Invocation.method(#login, [email, password]),
          returnValue: Future.value(User(email: '')),
          returnValueForMissingStub: Future.value(User(email: '')));

  @override
  Future<AuthSession> validateGoogleToken(String idToken) =>
      super.noSuchMethod(Invocation.method(#validateGoogleToken, [idToken]),
          returnValue: Future.value(const AuthSession(token: 'token')),
          returnValueForMissingStub: Future.value(const AuthSession(token: 'token')));

  @override
  Future<AuthSession> validateGithubAccessToken(String accessToken) =>
      super.noSuchMethod(
        Invocation.method(#validateGithubAccessToken, [accessToken]),
        returnValue: Future.value(const AuthSession(token: 'token')),
        returnValueForMissingStub: Future.value(const AuthSession(token: 'token')),
      );

  @override
  Future<AuthSession> validateMicrosoftAccessToken(String accessToken) =>
      super.noSuchMethod(
        Invocation.method(#validateMicrosoftAccessToken, [accessToken]),
        returnValue: Future.value(const AuthSession(token: 'token')),
        returnValueForMissingStub: Future.value(const AuthSession(token: 'token')),
      );

  @override
  Future<void> syncUser(String? displayName, String email, String? photoUrl) =>
      super.noSuchMethod(Invocation.method(#syncUser, [displayName, email, photoUrl]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<AuthSession> validateAppleToken(
    String identityToken, {
    String? email,
    String? displayName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#validateAppleToken, [identityToken], {
          #email: email,
          #displayName: displayName,
        }),
        returnValue: Future.value(const AuthSession(token: 'token')),
        returnValueForMissingStub: Future.value(const AuthSession(token: 'token')),
      );

  @override
  Future<AuthSession> signUp(
    String name,
    String email,
    String password, {
    String? profileImageUrl,
  }) =>
      super.noSuchMethod(
        Invocation.method(#signUp, [name, email, password], {
          #profileImageUrl: profileImageUrl,
        }),
        returnValue: Future.value(const AuthSession(token: 'token')),
        returnValueForMissingStub: Future.value(const AuthSession(token: 'token')),
      );

  @override
  Future<void> sendSignupVerificationCode(String email) =>
      super.noSuchMethod(
        Invocation.method(#sendSignupVerificationCode, [email]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );
  @override
  Future<void> forgetPassword(String email) =>
      super.noSuchMethod(
        Invocation.method(#forgetPassword, [email]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );
  @override
  Future<String> resetPassword(String email, String newPassword, String confirmationCode) =>
      super.noSuchMethod(Invocation.method(#resetPassword, [email, newPassword, confirmationCode]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<String> updatePassword(String currentPassword, String newPassword) =>
      super.noSuchMethod(
        Invocation.method(#updatePassword, [currentPassword, newPassword]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<bool> isLoggedIn() =>
      super.noSuchMethod(
        Invocation.method(#isLoggedIn, []),
        returnValue: Future.value(true), // Corrected to Future<bool>
        returnValueForMissingStub: Future.value(false), // Default fallback to false
      );

  @override
  Future<void> logout() =>
      super.noSuchMethod(
        Invocation.method(#logout, []),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

}





