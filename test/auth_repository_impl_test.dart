import 'dart:convert';

import 'package:data/auth/repositories/auth_repository_impl.dart';
import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:mockito/mockito.dart';

class MockAuthenticatedHttpClient extends Mock
    implements AuthenticatedHttpClient {}

class FakeTokenProvider extends TokenProvider {
  String? savedToken;

  @override
  Future<void> saveToken(String token) async {
    savedToken = token;
  }
}

class FakeApiEnvironment extends APIEnvironment {
  @override
  Future<String> getBaseUrl() async => 'https://example.test/api';
}

void main() {
  test('signUp keeps FastAPI duplicate-email detail and does not save a token',
      () async {
    final tokenProvider = FakeTokenProvider();
    final repository = AuthRepositoryImpl(
      client: MockClient((request) async {
        expect(request.url.path, '/api/auths/signup');
        expect(jsonDecode(request.body)['email'], 'taken@example.com');
        return http.Response(
          jsonEncode({'detail': 'EMAIL_TAKEN'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
      authClient: MockAuthenticatedHttpClient(),
      apiEnvironment: FakeApiEnvironment(),
      tokenProvider: tokenProvider,
    );

    await expectLater(
      repository.signUp('Test User', 'taken@example.com', 'password123'),
      throwsA(isA<BadRequestException>()
          .having((error) => error.message, 'message', 'EMAIL_TAKEN')),
    );
    expect(tokenProvider.savedToken, isNull);
  });

  for (final provider in ['apple', 'google', 'github', 'microsoft']) {
    test('$provider OAuth exchange keeps backend status and detail', () async {
      final tokenProvider = FakeTokenProvider();
      final repository = AuthRepositoryImpl(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auths/oauth/$provider');
          return http.Response(
            jsonEncode({'detail': 'OAuth provider is not configured'}),
            404,
            headers: {'content-type': 'application/json'},
          );
        }),
        authClient: MockAuthenticatedHttpClient(),
        apiEnvironment: FakeApiEnvironment(),
        tokenProvider: tokenProvider,
      );

      final Future<AuthSession> exchange = switch (provider) {
        'apple' => repository.validateAppleToken('identity-token'),
        'google' => repository.validateGoogleToken('id-token'),
        'github' => repository.validateGithubAccessToken('access-token'),
        _ => repository.validateMicrosoftAccessToken('access-token'),
      };
      await expectLater(
        exchange,
        throwsA(isA<NotFoundException>().having(
            (error) => error.message,
            'message',
            'OAuth provider is not configured')),
      );
      expect(tokenProvider.savedToken, isNull);
    });
  }

  test('Google OAuth exchange preserves a backend validation failure', () async {
    final repository = AuthRepositoryImpl(
      client: MockClient((request) async => http.Response(
            jsonEncode({'detail': 'Invalid Google ID token audience'}),
            401,
            headers: {'content-type': 'application/json'},
          )),
      authClient: MockAuthenticatedHttpClient(),
      apiEnvironment: FakeApiEnvironment(),
      tokenProvider: FakeTokenProvider(),
    );

    await expectLater(
      repository.validateGoogleToken('id-token'),
      throwsA(isA<UnauthorizedException>().having(
          (error) => error.message,
          'message',
          'Invalid Google ID token audience')),
    );
  });
  test('syncUser saves access token when backend creates a new user', () async {
    final tokenProvider = FakeTokenProvider();
    final repository = AuthRepositoryImpl(
      client: MockClient((request) async {
        expect(
            request.url.toString(), 'https://example.test/api/auth/sync-user');
        return http.Response(
          jsonEncode({'accessToken': 'new-user-token'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
      authClient: MockAuthenticatedHttpClient(),
      apiEnvironment: FakeApiEnvironment(),
      tokenProvider: tokenProvider,
    );

    await repository.syncUser('New User', 'new@example.com', null);

    expect(tokenProvider.savedToken, 'new-user-token');
  });
}
