import 'dart:async';
import 'dart:convert';

import 'package:data/auth/repositories/auth_repository_impl.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/microsoft_sign_in_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:swiftcomp/app/services/microsoft_sign_in_service.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

class _Storage extends TokenProvider {
  String? token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async => token = null;
}

class _Environment extends APIEnvironment {
  @override
  Future<String> getBaseUrl() async => 'https://example.test/api';
}

Map<String, dynamic> _account(String id) => {
      'id': id,
      'username': '$id@example.com',
      'name': 'Test Account',
    };

Map<String, dynamic> _result(String id) => {
      'accessToken': 'access-$id',
      'authenticationScheme': 'Bearer',
      'expiresOn': DateTime(2030).millisecondsSinceEpoch,
      'idToken': null,
      'authority': 'https://login.microsoftonline.com/organizations',
      'tenantId': null,
      'scopes': ['User.Read'],
      'correlationId': null,
      'account': _account(id),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('msal_auth');
  const signing = MethodChannel('com.compositesai/auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MicrosoftSignInServiceImpl service;
  late _Storage storage;
  late AuthRepositoryImpl repository;
  late LoginViewModel model;
  late Set<String> accounts;
  late List<String> calls;
  late List<String> selection;
  late bool removalSucceeds;
  Completer<bool>? removal;

  setUp(() {
    dotenv.loadFromString(envString: 'MICROSOFT_CLIENT_ID=example-client');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    service = MicrosoftSignInServiceImpl();
    storage = _Storage();
    accounts = {};
    calls = [];
    selection = ['account-a', 'account-b'];
    removalSucceeds = true;
    removal = null;
    messenger.setMockMethodCallHandler(
        signing,
        (_) async => {
              'packageName': 'com.example.app',
              'signatureHash': base64.encode(List<int>.filled(20, 0)),
            });
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'createMultipleAccountPca':
          return null;
        case 'getAccounts':
          return accounts.map(_account).toList();
        case 'removeAccount':
          final success =
              removal == null ? removalSucceeds : await removal!.future;
          if (success) accounts.remove(call.arguments);
          return success;
        case 'acquireToken':
          expect((call.arguments as Map)['prompt'], 'selectAccount');
          expect((call.arguments as Map)['scopes'], ['User.Read']);
          final selected = selection.removeAt(0);
          accounts.add(selected);
          return _result(selected);
        default:
          fail('Unexpected native operation; global sign-out is forbidden.');
      }
    });
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/oauth/microsoft')) {
        final access = jsonDecode(request.body)['accessToken'] as String;
        final id = access.substring('access-'.length);
        return http.Response(
            jsonEncode({
              'token': 'session-$id',
              'id': id,
              'email': '$id@example.com',
              'name': 'Test Account',
            }),
            200);
      }
      expect(request.url.path, '/api/auths/signout');
      return http.Response('{}', 200);
    });
    repository = AuthRepositoryImpl(
      client: client,
      authClient: AuthenticatedHttpClient(client, storage),
      apiEnvironment: _Environment(),
      tokenProvider: storage,
      microsoftSignInService: service,
    );
    model = LoginViewModel(
      authUseCase: AuthUseCaseImpl(repository: repository),
      appleSignInService: MockAppleSignInService(),
      googleSignInService: MockGoogleSignInService(),
      microsoftSignInService: service,
    );
  });

  tearDown(() {
    model.dispose();
    dotenv.clean();
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(signing, null);
  });

  test('account A signs out locally before Microsoft account B signs in',
      () async {
    await model.signInWithMicrosoft();
    expect(model.signedInUser?.id, 'account-a');
    expect(storage.token, 'session-account-a');
    expect(accounts, {'account-a'});

    await repository.logout();

    expect(storage.token, isNull);
    expect(accounts, isEmpty);
    await model.signInWithMicrosoft();
    expect(model.signedInUser?.id, 'account-b');
    expect(storage.token, 'session-account-b');
    expect(accounts, {'account-b'});
    expect(calls.where((method) => method == 'createMultipleAccountPca'),
        hasLength(1));
    expect(calls, isNot(contains('signOut')));
  });

  test('repeated cache cleanup is idempotent and remains app scoped', () async {
    await model.signInWithMicrosoft();
    await repository.logout();
    await repository.logout();
    await service.clearAppSession();

    expect(storage.token, isNull);
    expect(accounts, isEmpty);
    expect(calls.where((method) => method == 'removeAccount'), hasLength(1));
    expect(calls, isNot(contains('signOut')));
  });

  test('cache failure preserves app logout and blocks unsafe reuse until retry',
      () async {
    await model.signInWithMicrosoft();
    removalSucceeds = false;

    await repository.logout();

    expect(storage.token, isNull);
    expect(accounts, {'account-a'});
    await model.signInWithMicrosoft();
    expect(model.isSigningIn, isFalse);
    expect(model.signedInUser, isNull);
    expect(calls.where((method) => method == 'acquireToken'), hasLength(1));
    expect(model.errorMessage, isNot(contains('account-a')));

    removalSucceeds = true;
    await model.signInWithMicrosoft();
    expect(model.signedInUser?.id, 'account-b');
    expect(accounts, {'account-b'});
  });

  test(
      'timed out cleanup cannot remove a later login or launch an abandoned picker',
      () async {
    service = MicrosoftSignInServiceImpl(
        cleanupTimeout: const Duration(milliseconds: 15));
    accounts.add('old-account');
    removal = Completer<bool>();

    await expectLater(service.clearAppSession(),
        throwsA(isA<MicrosoftSessionCleanupException>()));
    await expectLater(service.acquireAccessToken(),
        throwsA(isA<MicrosoftSessionCleanupException>()));
    expect(calls, isNot(contains('acquireToken')));
    removal!.complete(true);
    removal = null;

    expect(await service.acquireAccessToken(), 'access-account-a');
    expect(accounts, {'account-a'});
    expect(calls.where((method) => method == 'acquireToken'), hasLength(1));
    expect(calls, isNot(contains('signOut')));
  });

  test('native shared-device rejection never falls back to global sign-out',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(
          code: 'CLIENT_ERROR', message: 'Private native diagnostic');
    });

    await model.signInWithMicrosoft();
    await service.clearAppSession().catchError((Object _) {});

    expect(model.isSigningIn, isFalse);
    expect(model.errorMessage, isNot(contains('Private native diagnostic')));
    expect(
        calls.every((method) => method == 'createMultipleAccountPca'), isTrue);
  });
}
