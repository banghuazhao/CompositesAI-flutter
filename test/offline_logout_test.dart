import 'dart:async';

import 'package:data/auth/repositories/auth_repository_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/microsoft_sign_in_service.dart';
import 'package:infrastructure/token_provider.dart';

class _Environment extends APIEnvironment {
  Future<String> Function()? lookup;

  @override
  Future<String> getBaseUrl() async =>
      lookup == null ? 'https://example.test/api' : await lookup!();
}

class _Microsoft extends MicrosoftSignInService {
  int cleanupCalls = 0;
  Future<void> Function()? cleanup;

  @override
  Future<void> clearAppSession() {
    cleanupCalls++;
    return cleanup?.call() ?? Future<void>.value();
  }

  @override
  Future<String?> acquireAccessToken({bool Function()? isActive}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late TokenProvider tokens;
  late _Environment environment;
  late _Microsoft microsoft;
  String? stored;
  int deletes = 0;
  bool failDelete = false;
  Future<void> Function()? beforeRead;

  AuthRepositoryImpl repository(http.Client client) {
    addTearDown(client.close);
    return AuthRepositoryImpl(
      client: client,
      authClient: AuthenticatedHttpClient(client, tokens),
      apiEnvironment: environment,
      tokenProvider: tokens,
      microsoftSignInService: microsoft,
      requestTimeout: const Duration(milliseconds: 10),
    );
  }

  setUp(() {
    tokens = TokenProvider();
    environment = _Environment();
    microsoft = _Microsoft();
    stored = 'account-a-session';
    deletes = 0;
    failDelete = false;
    beforeRead = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          final snapshot = stored;
          await beforeRead?.call();
          return snapshot;
        case 'write':
          stored = (call.arguments as Map)['value'] as String?;
          return null;
        case 'delete':
          if (failDelete) throw PlatformException(code: 'storage_unavailable');
          deletes++;
          stored = null;
          return null;
        default:
          throw StateError('Unexpected secure-storage operation');
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('logout resolves before a hanging server or native cleanup', () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final native = Completer<void>();
    microsoft.cleanup = () => native.future;
    final repo = repository(MockClient((request) {
      expect(request.url.path, '/api/auths/signout');
      expect(request.headers['authorization'], 'Bearer account-a-session');
      received.complete();
      return response.future;
    }));

    await repo.logout();
    expect(await tokens.getToken(), isNull);
    expect(await repo.isLoggedIn(), isFalse);
    expect(microsoft.cleanupCalls, 1);
    expect(native.isCompleted, isFalse);
    expect(response.isCompleted, isFalse);

    await received.future;
    response.complete(http.Response('', 200));
    native.complete();
    await Future<void>.delayed(Duration.zero);
  });

  for (final status in [200, 401, 500]) {
    test('late server $status cannot remove a newer account session', () async {
      final received = Completer<void>();
      final response = Completer<http.Response>();
      final repo = repository(MockClient((request) {
        expect(request.headers['authorization'], 'Bearer account-a-session');
        received.complete();
        return response.future;
      }));

      await repo.logout();
      await received.future;
      await tokens.saveToken('account-b-session');
      response.complete(http.Response('', status));
      await Future<void>.delayed(Duration.zero);

      expect(await tokens.getToken(), 'account-b-session');
      expect(deletes, 1);
    });
  }

  test('offline and native failures do not undo local sign-out', () async {
    microsoft.cleanup = () => Future<void>.error(StateError('Native failure'));
    final repo = repository(MockClient((_) async {
      throw http.ClientException('Offline');
    }));

    await repo.logout();
    await Future<void>.delayed(Duration.zero);

    expect(await tokens.getToken(), isNull);
    expect(microsoft.cleanupCalls, 1);
  });

  test('expired environment lookup does not launch a late sign-out request',
      () async {
    final baseUrl = Completer<String>();
    environment.lookup = () => baseUrl.future;
    var requests = 0;
    final repo = repository(MockClient((_) async {
      requests++;
      return http.Response('', 200);
    }));

    await repo.logout();
    expect(stored, isNull);
    await tokens.saveToken('account-b-session');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    baseUrl.complete('https://example.test/api');
    await Future<void>.delayed(Duration.zero);

    expect(requests, 0);
    expect(await tokens.getToken(), 'account-b-session');
  });

  test('server response after the cleanup timeout cannot change a new session',
      () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final repo = repository(MockClient((_) {
      received.complete();
      return response.future;
    }));

    await repo.logout();
    await received.future;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await tokens.saveToken('account-b-session');
    response.complete(http.Response('', 401));
    await Future<void>.delayed(Duration.zero);

    expect(await tokens.getToken(), 'account-b-session');
  });

  test('secure-storage failure remains an unsuccessful logout', () async {
    failDelete = true;
    var requests = 0;
    final repo = repository(MockClient((_) async {
      requests++;
      return http.Response('', 200);
    }));

    await expectLater(repo.logout(), throwsA(isA<PlatformException>()));

    expect(stored, 'account-a-session');
    expect(requests, 0);
  });

  test('native cleanup is queued before local storage yields', () async {
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    beforeRead = () async {
      expect(microsoft.cleanupCalls, 1);
      readStarted.complete();
      await releaseRead.future;
    };
    final repo = repository(MockClient((_) async => http.Response('', 200)));

    final signOut = repo.logout();
    await readStarted.future;
    beforeRead = null;
    releaseRead.complete();
    await signOut;
    await Future<void>.delayed(Duration.zero);

    expect(stored, isNull);
  });

  test('atomic removal cannot delete a sign-in queued during its read',
      () async {
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    beforeRead = () async {
      readStarted.complete();
      await releaseRead.future;
    };

    final departing = tokens.takeToken();
    await readStarted.future;
    final newLogin = TokenProvider().saveToken('account-b-session');
    beforeRead = null;
    releaseRead.complete();

    expect(await departing, 'account-a-session');
    await newLogin;
    expect(await tokens.getToken(), 'account-b-session');
    expect(deletes, 1);
  });

  test('already signed-out sessions do not send an anonymous server request',
      () async {
    stored = null;
    var requests = 0;
    final repo = repository(MockClient((_) async {
      requests++;
      return http.Response('', 200);
    }));

    await repo.logout();
    await Future<void>.delayed(Duration.zero);

    expect(requests, 0);
    expect(microsoft.cleanupCalls, 1);
    expect(deletes, 0);
  });
}
