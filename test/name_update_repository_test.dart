import 'dart:async';
import 'dart:convert';

import 'package:data/auth/repositories/user_repository_impl.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

class _Storage extends TokenProvider {
  String? token = 'session-a';
  int reads = 0;
  int removals = 0;
  Future<String?> Function(int)? read;

  @override
  Future<String?> getToken() async {
    final count = ++reads;
    return read == null ? token : await read!(count);
  }

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<bool> deleteTokenIfMatches(String expectedToken) async {
    if (token != expectedToken) return false;
    removals++;
    token = null;
    return true;
  }
}

class _Environment extends APIEnvironment {
  Future<String> Function()? lookup;

  @override
  Future<String> getBaseUrl() async =>
      lookup == null ? 'https://example.test/api' : await lookup!();
}

http.Response _profile() => http.Response(
      jsonEncode({
        'id': 'account-a',
        'email': 'a@example.test',
        'name': 'Previous name',
        'profile_image_url': 'https://example.test/avatar-a.png',
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late _Storage storage;
  late _Environment environment;

  UserRepositoryImpl repository(
    Future<http.Response> Function(http.Request) respond, {
    Duration updateTimeout = const Duration(seconds: 1),
    Duration profileTimeout = const Duration(seconds: 1),
  }) {
    final client = MockClient(respond);
    addTearDown(client.close);
    return UserRepositoryImpl(
      authClient: AuthenticatedHttpClient(client, storage),
      apiEnvironment: environment,
      profileRequestTimeout: profileTimeout,
      profileUpdateTimeout: updateTimeout,
    );
  }

  setUp(() {
    storage = _Storage();
    environment = _Environment();
  });

  test('name update keeps one authorization and preserves the profile image',
      () async {
    final methods = <String>[];
    final users = repository((request) async {
      methods.add(request.method);
      expect(request.headers['authorization'], 'Bearer session-a');
      if (request.method == 'GET') {
        expect(request.url.path, '/api/auths/');
        return _profile();
      }
      expect(request.url.path, '/api/auths/update/profile');
      expect(jsonDecode(request.body), {
        'name': 'Updated name',
        'profile_image_url': 'https://example.test/avatar-a.png',
      });
      return http.Response('', 200);
    });

    await users.updateMe('Updated name');

    expect(methods, ['GET', 'POST']);
    expect(storage.token, 'session-a');
    expect(storage.removals, 0);
  });

  test('signed-out update cannot make an anonymous profile or update request',
      () async {
    storage.token = null;
    var requests = 0;
    final users = repository((_) async {
      requests++;
      return _profile();
    });

    await expectLater(users.updateMe('Updated name'),
        throwsA(isA<AuthenticatedSessionChangedException>()));

    expect(requests, 0);
  });

  test('changed session before first send cannot read another profile',
      () async {
    storage.read = (count) async {
      if (count == 2) storage.token = 'session-b';
      return storage.token;
    };
    var requests = 0;
    final users = repository((_) async {
      requests++;
      return _profile();
    });

    await expectLater(users.updateMe('Updated name'),
        throwsA(isA<AuthenticatedSessionChangedException>()));

    expect(requests, 0);
    expect(storage.token, 'session-b');
  });

  for (final nextToken in <String?>['session-b', null]) {
    test(
        'profile response after ${nextToken == null ? 'logout' : 'account change'} cannot launch POST',
        () async {
      final response = Completer<http.Response>();
      final started = Completer<void>();
      final methods = <String>[];
      final users = repository((request) {
        methods.add(request.method);
        expect(request.method, 'GET');
        expect(request.headers['authorization'], 'Bearer session-a');
        started.complete();
        return response.future;
      });
      final result = expectLater(users.updateMe('Updated name'),
          throwsA(isA<AuthenticatedSessionChangedException>()));
      await started.future;

      storage.token = nextToken;
      response.complete(_profile());
      await result;

      expect(methods, ['GET']);
      expect(storage.token, nextToken);
      expect(storage.removals, 0);
    });
  }

  test('late update 401 cannot remove a newly signed-in account', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final users = repository((request) {
      expect(request.headers['authorization'], 'Bearer session-a');
      if (request.method == 'GET') return Future.value(_profile());
      started.complete();
      return response.future;
    });
    final result = expectLater(
        users.updateMe('Updated name'), throwsA(isA<UnauthorizedException>()));
    await started.future;

    await storage.saveToken('session-b');
    response.complete(http.Response('', 401));
    await result;

    expect(storage.token, 'session-b');
    expect(storage.removals, 0);
  });

  test('401 still invalidates the session actually used for the update',
      () async {
    final users = repository((request) async =>
        request.method == 'GET' ? _profile() : http.Response('', 401));

    await expectLater(
        users.updateMe('Updated name'), throwsA(isA<UnauthorizedException>()));

    expect(storage.token, isNull);
    expect(storage.removals, 1);
  });

  test('late profile after the whole-update deadline cannot launch POST',
      () async {
    final response = Completer<http.Response>();
    final methods = <String>[];
    final users = repository((request) {
      methods.add(request.method);
      return response.future;
    }, updateTimeout: const Duration(milliseconds: 40));

    await expectLater(
      users.updateMe('Updated name'),
      throwsA(isA<TimeoutException>().having(
        (error) => error.message,
        'safe message',
        'Name update timed out. Please try again.',
      )),
    );
    response.complete(_profile());
    await Future<void>.delayed(Duration.zero);

    expect(methods, ['GET']);
    expect(storage.token, 'session-a');
  });

  test('slow environment lookup is bounded and cannot start late requests',
      () async {
    final baseUrl = Completer<String>();
    environment.lookup = () => baseUrl.future;
    var requests = 0;
    final users = repository((request) async {
      requests++;
      return _profile();
    }, updateTimeout: const Duration(milliseconds: 40));

    await expectLater(
        users.updateMe('Updated name'), throwsA(isA<TimeoutException>()));
    baseUrl.complete('https://example.test/api');
    await Future<void>.delayed(Duration.zero);

    expect(requests, 0);
    expect(storage.token, 'session-a');
  });

  test('POST timeout stays failed when a successful response arrives late',
      () async {
    final response = Completer<http.Response>();
    var posts = 0;
    var succeeded = false;
    final users = repository((request) {
      if (request.method == 'GET') return Future.value(_profile());
      posts++;
      return response.future;
    }, updateTimeout: const Duration(milliseconds: 40));
    final update = users.updateMe('Updated name').then((_) => succeeded = true);

    await expectLater(update, throwsA(isA<TimeoutException>()));
    response.complete(http.Response('', 200));
    await Future<void>.delayed(Duration.zero);

    expect(posts, 1);
    expect(succeeded, isFalse);
    expect(storage.token, 'session-a');
  });

  test('deadline during POST token lookup cannot start a late write', () async {
    final postTokenRead = Completer<void>();
    final releaseToken = Completer<String?>();
    storage.read = (count) async {
      if (count == 3) {
        postTokenRead.complete();
        return releaseToken.future;
      }
      return storage.token;
    };
    final methods = <String>[];
    final users = repository((request) async {
      methods.add(request.method);
      return request.method == 'GET' ? _profile() : http.Response('', 200);
    }, updateTimeout: const Duration(milliseconds: 40));
    final result = expectLater(
        users.updateMe('Updated name'), throwsA(isA<TimeoutException>()));
    await postTokenRead.future;

    await result;
    releaseToken.complete('session-a');
    await Future<void>.delayed(Duration.zero);

    expect(methods, ['GET']);
    expect(storage.token, 'session-a');
  });

  test('profile fetch retains its existing timeout and safe message', () async {
    final response = Completer<http.Response>();
    final users = repository((_) => response.future,
        profileTimeout: const Duration(milliseconds: 15));

    await expectLater(
      users.fetchMe(),
      throwsA(isA<TimeoutException>().having(
        (error) => error.message,
        'safe message',
        'Profile request timed out. Please try again.',
      )),
    );
    response.complete(_profile());
    await Future<void>.delayed(Duration.zero);

    expect(storage.token, 'session-a');
    expect(storage.removals, 0);
  });

  test('server rejection propagates so the form can remain open', () async {
    final users = repository((request) async => request.method == 'GET'
        ? _profile()
        : http.Response('Server diagnostic', 500));

    await expectLater(users.updateMe('Updated name'),
        throwsA(isA<InternalServerErrorException>()));

    expect(storage.token, 'session-a');
  });
}
