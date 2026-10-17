import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/token_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final uri = Uri.parse('https://example.test/api/auths/update/password');
  late TokenProvider tokens;
  String? storedToken;
  var deleteCount = 0;
  var writeCount = 0;
  Future<void> Function()? beforeRead;

  setUp(() {
    tokens = TokenProvider();
    storedToken = null;
    deleteCount = 0;
    writeCount = 0;
    beforeRead = null;
    messenger.setMockMethodCallHandler(storageChannel, (call) async {
      switch (call.method) {
        case 'read':
          final value = storedToken;
          await beforeRead?.call();
          return value;
        case 'write':
          writeCount++;
          storedToken = (call.arguments as Map)['value'] as String?;
          return null;
        case 'delete':
          deleteCount++;
          storedToken = null;
          return null;
        default:
          throw StateError('Unexpected storage operation');
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(storageChannel, null));

  test('late 401 for A preserves a newer B session', () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final client = AuthenticatedHttpClient(MockClient((request) {
      expect(request.headers['authorization'], 'Bearer account-a-session');
      received.complete();
      return response.future;
    }), tokens);
    addTearDown(client.close);
    await tokens.saveToken('account-a-session');
    final request = client.get(uri);
    await received.future;

    await tokens.saveToken('account-b-session');
    response.complete(http.Response('', 401));
    expect((await request).statusCode, 401);

    expect(await tokens.getToken(), 'account-b-session');
    expect(deleteCount, 0);
  });

  test('401 for the current session removes its token', () async {
    final client = AuthenticatedHttpClient(
      MockClient((_) async => http.Response('', 401)),
      tokens,
    );
    addTearDown(client.close);
    await tokens.saveToken('current-session');

    expect((await client.get(uri)).statusCode, 401);

    expect(await tokens.getToken(), isNull);
    expect(deleteCount, 1);
  });

  test('a 401 without an outbound session does not remove a newly saved token',
      () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final client = AuthenticatedHttpClient(MockClient((request) {
      expect(request.headers['authorization'], isNull);
      received.complete();
      return response.future;
    }), tokens);
    addTearDown(client.close);
    final request = client.get(uri);
    await received.future;

    await tokens.saveToken('new-session');
    response.complete(http.Response('', 401));
    await request;

    expect(await tokens.getToken(), 'new-session');
    expect(deleteCount, 0);
  });

  test('a new sign-in cannot interleave between token comparison and deletion',
      () async {
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final client = AuthenticatedHttpClient(MockClient((_) {
      received.complete();
      return response.future;
    }), tokens);
    addTearDown(client.close);
    await tokens.saveToken('account-a-session');
    final request = client.get(uri);
    await received.future;
    final comparing = Completer<void>();
    final releaseComparison = Completer<void>();
    beforeRead = () async {
      comparing.complete();
      await releaseComparison.future;
    };

    response.complete(http.Response('', 401));
    await comparing.future;
    final signIn = TokenProvider().saveToken('account-b-session');
    await Future<void>.delayed(Duration.zero);
    expect(writeCount, 1);
    beforeRead = null;
    releaseComparison.complete();
    await Future.wait([request, signIn]);

    expect(await tokens.getToken(), 'account-b-session');
    expect(deleteCount, 1);
    expect(writeCount, 2);
  });

  test('a storage failure does not block later token operations', () async {
    beforeRead = () async => throw PlatformException(code: 'storage_failure');

    await expectLater(tokens.getToken(), throwsA(isA<PlatformException>()));
    beforeRead = null;
    await tokens.saveToken('recovered-session');

    expect(await tokens.getToken(), 'recovered-session');
  });
}
