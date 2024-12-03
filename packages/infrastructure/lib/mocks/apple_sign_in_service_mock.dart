// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_this, invalid_use_of_visible_for_testing_member, avoid_setters_without_getters

import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../apple_sign_in_service.dart';

class MockAppleSignInService extends Mock implements AppleSignInService {
  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
  }) {
    return super.noSuchMethod(
      Invocation.method(#getAppleIDCredential, [], {
        #scopes: scopes,
        #webAuthenticationOptions: webAuthenticationOptions,
      }),
      returnValue: Future.value(
        AuthorizationCredentialAppleID(
          userIdentifier: 'mock-user-id',
          givenName: 'Mock',
          familyName: 'User',
          email: 'mockuser@example.com',
          authorizationCode: 'mock-auth-code',
          identityToken: 'mock-identity-token',
        ),
      ),
      returnValueForMissingStub: Future.value(
        AuthorizationCredentialAppleID(
          userIdentifier: 'mock-user-id',
          givenName: 'Mock',
          familyName: 'User',
          email: 'mockuser@example.com',
          authorizationCode: 'mock-auth-code',
          identityToken: 'mock-identity-token',
        ),
      ),
    );
  }
}
