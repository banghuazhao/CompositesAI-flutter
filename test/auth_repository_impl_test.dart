import 'dart:async';
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
  int saveCount = 0;
  int deleteCount = 0;

  @override
  Future<void> saveToken(String token) async {
    saveCount++;
    savedToken = token;
  }

  @override
  Future<String?> getToken() async => savedToken;

  @override
  Future<void> deleteToken() async {
    deleteCount++;
    savedToken = null;
  }
}

class FakeApiEnvironment extends APIEnvironment {
  @override
  Future<String> getBaseUrl() async => 'https://example.test/api';
}

void main() {
  AuthRepositoryImpl repositoryFor(
    http.Client client, {
    FakeTokenProvider? tokenProvider,
    Duration requestTimeout = const Duration(seconds: 30),
  }) {
    final storage = tokenProvider ?? FakeTokenProvider();
    return AuthRepositoryImpl(
      client: client,
      authClient: AuthenticatedHttpClient(client, storage),
      apiEnvironment: FakeApiEnvironment(),
      tokenProvider: storage,
      requestTimeout: requestTimeout,
    );
  }

  test('forgot password uses the backend reset-code contract', () async {
    final storage = FakeTokenProvider()..savedToken = 'existing-session';
    final repository = repositoryFor(
      MockClient((request) async {
        expect(
          request.url.path,
          '/api/auths/send-reset-password-verification-code',
        );
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'email': 'person@example.com',
          'captcha_response': '',
        });
        expect(request.headers['authorization'], isNull);
        return http.Response(jsonEncode({'message': 'Code sent'}), 200);
      }),
      tokenProvider: storage,
    );

    await repository.forgetPassword(' Person@Example.com ');

    expect(storage.savedToken, 'existing-session');
    expect(storage.saveCount, 0);
  });

  test(
    'reset password sends code and keeps the current session intact',
    () async {
      final storage = FakeTokenProvider()..savedToken = 'existing-session';
      final repository = repositoryFor(
        MockClient((request) async {
          expect(request.url.path, '/api/auths/reset-password');
          expect(jsonDecode(request.body), {
            'email': 'person@example.com',
            'password': 'replacement-password',
            'code': '123456',
          });
          return http.Response(
            jsonEncode({'message': 'Password reset successfully'}),
            200,
          );
        }),
        tokenProvider: storage,
      );

      expect(
        await repository.resetPassword(
          ' Person@Example.com ',
          'replacement-password',
          ' 123456 ',
        ),
        'Password reset successfully',
      );
      expect(storage.savedToken, 'existing-session');
      expect(storage.saveCount, 0);
    },
  );

  test('reset-code request preserves the backend rate-limit status', () async {
    final repository = repositoryFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Please wait before requesting another code'}),
          429,
        ),
      ),
    );

    await expectLater(
      repository.forgetPassword('person@example.com'),
      throwsA(isA<TooManyRequestsException>()),
    );
  });

  test(
    'reset failure preserves the backend status and does not save a session',
    () async {
      final storage = FakeTokenProvider();
      final repository = repositoryFor(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Invalid or expired verification code'}),
            400,
          ),
        ),
        tokenProvider: storage,
      );

      await expectLater(
        repository.resetPassword(
          'person@example.com',
          'replacement-password',
          '123456',
        ),
        throwsA(isA<BadRequestException>()),
      );
      expect(storage.saveCount, 0);
    },
  );

  test(
    'email login persists the validated session and returns its user',
    () async {
      final storage = FakeTokenProvider();
      final repository = repositoryFor(
        MockClient((request) async {
          expect(request.url.path, '/api/auths/signin');
          return http.Response(
            jsonEncode({
              'token': 'new-session',
              'email': 'person@example.com',
              'name': 'Test Person',
            }),
            200,
          );
        }),
        tokenProvider: storage,
      );

      final user = await repository.login(
        'person@example.com',
        'test-password',
      );

      expect(user.email, 'person@example.com');
      expect(storage.savedToken, 'new-session');
      expect(storage.saveCount, 1);
    },
  );

  test('email login rejects a response without a session token', () async {
    final storage = FakeTokenProvider()..savedToken = 'existing-session';
    final repository = repositoryFor(
      MockClient(
        (_) async =>
            http.Response(jsonEncode({'email': 'person@example.com'}), 200),
      ),
      tokenProvider: storage,
    );

    await expectLater(
      repository.login('person@example.com', 'test-password'),
      throwsException,
    );

    expect(storage.savedToken, 'existing-session');
    expect(storage.saveCount, 0);
  });

  test('session restore rejects missing or blank stored tokens', () async {
    final storage = FakeTokenProvider();
    final repository = repositoryFor(
      MockClient((_) async => throw StateError('No HTTP request expected')),
      tokenProvider: storage,
    );

    for (final token in <String?>[null, '', '   ']) {
      storage.savedToken = token;
      expect(await repository.isLoggedIn(), isFalse);
    }
    storage.savedToken = 'existing-session';
    expect(await repository.isLoggedIn(), isTrue);
  });

  test('LinkedIn exchange errors do not expose the response body', () async {
    final repository = repositoryFor(MockClient((_) async =>
        http.Response('raw-provider-diagnostic-with-private-data', 400)));

    await expectLater(
      repository.handleAuthorizationCodeFromLinked('code'),
      throwsA(isA<Exception>().having(
        (error) => error.toString(),
        'safe message',
        'Exception: LinkedIn sign-in could not be completed. Please try again.',
      )),
    );
  });

  final requests = <String, Future<dynamic> Function(AuthRepositoryImpl)>{
    'email login': (repository) =>
        repository.login('person@example.com', 'test-password'),
    'signup': (repository) =>
        repository.signUp('Test Person', 'person@example.com', 'test-password'),
    'Google exchange': (repository) => repository.validateGoogleToken('token'),
    'Apple exchange': (repository) => repository.validateAppleToken('token'),
    'GitHub exchange': (repository) =>
        repository.validateGithubAccessToken('token'),
    'Microsoft exchange': (repository) =>
        repository.validateMicrosoftAccessToken('token'),
    'profile session exchange': (repository) =>
        repository.syncUser('Test Person', 'person@example.com', null),
    'forgot password': (repository) =>
        repository.forgetPassword('person@example.com'),
    'reset password': (repository) => repository.resetPassword(
          'person@example.com',
          'replacement-password',
          '123456',
        ),
    'update password': (repository) =>
        repository.updatePassword('current-password', 'replacement-password'),
    'signup verification': (repository) =>
        repository.sendSignupVerificationCode('person@example.com'),
    'LinkedIn exchange': (repository) =>
        repository.handleAuthorizationCodeFromLinked('code'),
    'LinkedIn profile': (repository) =>
        repository.fetchLinkedInUserProfile('token'),
  };
  for (final request in requests.entries) {
    test(
      '${request.key} times out without accepting a late response',
      () async {
        final storage = FakeTokenProvider()..savedToken = 'existing-session';
        final response = Completer<http.Response>();
        final repository = repositoryFor(
          MockClient((_) => response.future),
          tokenProvider: storage,
          requestTimeout: const Duration(milliseconds: 1),
        );

        await expectLater(
          request.value(repository),
          throwsA(
            isA<TimeoutException>().having(
              (error) => error.message,
              'safe message',
              'Authentication request timed out. Please try again.',
            ),
          ),
        );
        response.complete(
          http.Response(
            jsonEncode({
              'token': 'late-session',
              'accessToken': 'late-session',
              'email': 'person@example.com',
              'message': 'Success',
              'user': {'email': 'person@example.com'},
            }),
            200,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(storage.savedToken, 'existing-session');
        expect(storage.saveCount, 0);
        expect(storage.deleteCount, 0);
      },
    );
  }

  test(
    'signUp keeps FastAPI duplicate-email detail and does not save a token',
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
        throwsA(
          isA<BadRequestException>().having(
            (error) => error.message,
            'message',
            'EMAIL_TAKEN',
          ),
        ),
      );
      expect(tokenProvider.savedToken, isNull);
    },
  );

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
        throwsA(
          isA<NotFoundException>().having(
            (error) => error.message,
            'message',
            'OAuth provider is not configured',
          ),
        ),
      );
      expect(tokenProvider.savedToken, isNull);
    });
  }

  test(
    'Google OAuth exchange preserves a backend validation failure',
    () async {
      final repository = AuthRepositoryImpl(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({'detail': 'Invalid Google ID token audience'}),
            401,
            headers: {'content-type': 'application/json'},
          ),
        ),
        authClient: MockAuthenticatedHttpClient(),
        apiEnvironment: FakeApiEnvironment(),
        tokenProvider: FakeTokenProvider(),
      );

      await expectLater(
        repository.validateGoogleToken('id-token'),
        throwsA(
          isA<UnauthorizedException>().having(
            (error) => error.message,
            'message',
            'Invalid Google ID token audience',
          ),
        ),
      );
    },
  );
  test('syncUser saves access token when backend creates a new user', () async {
    final tokenProvider = FakeTokenProvider();
    final repository = AuthRepositoryImpl(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://example.test/api/auth/sync-user',
        );
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
