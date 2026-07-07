import 'dart:convert';

import 'package:data/auth/repositories/auth_repository_impl.dart';
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
