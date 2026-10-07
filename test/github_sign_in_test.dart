import 'dart:async';

import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

class _GithubTestModel extends LoginViewModel {
  _GithubTestModel(MockAuthUseCase authUseCase, this.respond)
      : super(
          authUseCase: authUseCase,
          appleSignInService: MockAppleSignInService(),
          googleSignInService: MockGoogleSignInService(),
        );

  final Future<Map<String, dynamic>> Function(Uri, Map<String, String>) respond;

  @override
  Future<Map<String, dynamic>> httpPostForm(
          Uri uri, Map<String, String> body) =>
      respond(uri, body);
}

Map<String, dynamic> _device(String number, {int interval = 5}) => {
      'verification_uri': 'https://github.com/login/device',
      'user_code': 'code-$number',
      'device_code': 'device-$number',
      'expires_in': 900,
      'interval': interval,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MockAuthUseCase auth;

  setUp(() {
    dotenv.loadFromString(envString: 'GITHUB_CLIENT_ID=test-client');
    auth = MockAuthUseCase();
    messenger.setMockMethodCallHandler(launcherChannel, (_) async => true);
  });

  tearDown(() {
    dotenv.clean();
    messenger.setMockMethodCallHandler(launcherChannel, null);
  });

  test('cancel during device request stops before opening authorization',
      () async {
    final response = Completer<Map<String, dynamic>>();
    var launches = 0;
    messenger.setMockMethodCallHandler(launcherChannel, (_) async {
      launches++;
      return true;
    });
    final model = _GithubTestModel(auth, (_, __) => response.future);
    final signIn = model.signInWithGithub();

    model.cancelGithubSignIn();
    response.complete(_device('1'));
    await signIn;

    expect(launches, 0);
    expect(model.isSigningIn, isFalse);
    expect(model.errorMessage, isNull);
    model.dispose();
  });

  test('cancel while a token poll is in flight never exchanges its token',
      () async {
    final pollStarted = Completer<void>();
    final poll = Completer<Map<String, dynamic>>();
    final model = _GithubTestModel(auth, (uri, _) async {
      if (uri.path.endsWith('/device/code')) return _device('1');
      pollStarted.complete();
      return poll.future;
    });
    final signIn = model.signInWithGithub();
    await pollStarted.future;

    model.cancelGithubSignIn();
    poll.complete({'access_token': 'cancelled-access-token'});
    await signIn;

    verifyNever(auth.validateGithubAccessToken('cancelled-access-token'));
    expect(model.isSigningIn, isFalse);
    expect(model.signedInUser, isNull);
    expect(model.errorMessage, isNull);
    expect(model.githubUserCode, isNull);
    model.dispose();
  });

  test('an immediate retry cannot revive the previous cancelled attempt',
      () async {
    final pollsStarted = [Completer<void>(), Completer<void>()];
    final polls = [
      Completer<Map<String, dynamic>>(),
      Completer<Map<String, dynamic>>(),
    ];
    var deviceRequests = 0;
    final user = User(email: 'github@example.com');
    when(auth.validateGithubAccessToken('retry-token')).thenAnswer(
        (_) async => AuthSession(token: 'session-token', user: user));
    final model = _GithubTestModel(auth, (uri, body) async {
      if (uri.path.endsWith('/device/code')) {
        deviceRequests++;
        return _device('$deviceRequests');
      }
      final index = body['device_code'] == 'device-1' ? 0 : 1;
      pollsStarted[index].complete();
      return polls[index].future;
    });
    final first = model.signInWithGithub();
    await pollsStarted[0].future;
    model.cancelGithubSignIn();
    final retry = model.signInWithGithub();
    await pollsStarted[1].future;

    polls[0].complete({'access_token': 'old-token'});
    await first;
    expect(model.githubUserCode, 'code-2');
    expect(model.isSigningIn, isFalse);
    verifyNever(auth.validateGithubAccessToken('old-token'));

    polls[1].complete({'access_token': 'retry-token'});
    await retry;
    expect(model.signedInUser, same(user));
    expect(model.isSigningIn, isTrue);
    verify(auth.validateGithubAccessToken('retry-token')).called(1);
    model.cancelGithubSignIn();
    expect(model.isSigningIn, isTrue);
    model.dispose();
  });

  test('cancel interrupts the polling interval immediately', () async {
    final pollStarted = Completer<void>();
    final model = _GithubTestModel(auth, (uri, _) async {
      if (uri.path.endsWith('/device/code')) {
        return _device('1', interval: 60);
      }
      pollStarted.complete();
      return {'error': 'authorization_pending'};
    });
    final signIn = model.signInWithGithub();
    await pollStarted.future;
    await Future<void>.delayed(Duration.zero);

    model.cancelGithubSignIn();
    await signIn.timeout(const Duration(seconds: 1));

    expect(model.errorMessage, isNull);
    expect(model.isSigningIn, isFalse);
    model.dispose();
  });

  test('final session exchange completes once and clears finalizing state',
      () async {
    final exchangeStarted = Completer<void>();
    final exchange = Completer<AuthSession>();
    final user = User(email: 'github@example.com');
    when(auth.validateGithubAccessToken('accepted-token')).thenAnswer((_) {
      exchangeStarted.complete();
      return exchange.future;
    });
    var deviceRequests = 0;
    final model = _GithubTestModel(auth, (uri, _) async {
      if (uri.path.endsWith('/device/code')) {
        deviceRequests++;
        return _device('1');
      }
      return {'access_token': 'accepted-token'};
    });
    final signIn = model.signInWithGithub();
    await exchangeStarted.future;
    expect(model.isGithubFinalizing, isTrue);

    // The exchange saves a session, so it cannot be cancelled or duplicated.
    model.cancelGithubSignIn();
    await model.signInWithGithub();
    expect(deviceRequests, 1);
    exchange.complete(AuthSession(token: 'session-token', user: user));
    await signIn;

    expect(model.isGithubFinalizing, isFalse);
    expect(model.isSigningIn, isTrue);
    expect(model.signedInUser, same(user));
    verify(auth.validateGithubAccessToken('accepted-token')).called(1);
    model.dispose();
  });

  test('failed final session exchange restores cancellable retry state',
      () async {
    final exchangeStarted = Completer<void>();
    final exchange = Completer<AuthSession>();
    when(auth.validateGithubAccessToken('accepted-token')).thenAnswer((_) {
      exchangeStarted.complete();
      return exchange.future;
    });
    final model = _GithubTestModel(auth, (uri, _) async {
      if (uri.path.endsWith('/device/code')) return _device('1');
      return {'access_token': 'accepted-token'};
    });
    final signIn = model.signInWithGithub();
    await exchangeStarted.future;
    expect(model.isGithubFinalizing, isTrue);
    exchange.completeError(Exception('Network connection failed'));
    await signIn;

    expect(model.isGithubFinalizing, isFalse);
    expect(model.isSigningIn, isFalse);
    expect(model.errorMessage, 'Network error. Please check your connection.');
    model.dispose();
  });

  test('disposal cancels a pending poll without notifying disposed listeners',
      () async {
    final pollStarted = Completer<void>();
    final poll = Completer<Map<String, dynamic>>();
    final model = _GithubTestModel(auth, (uri, _) async {
      if (uri.path.endsWith('/device/code')) return _device('1');
      pollStarted.complete();
      return poll.future;
    });
    final signIn = model.signInWithGithub();
    await pollStarted.future;
    model.dispose();
    poll.complete({'access_token': 'late-token'});

    await expectLater(signIn, completes);
    verifyNever(auth.validateGithubAccessToken('late-token'));
  });

  test('leaving login before password response does not notify after disposal',
      () async {
    final response = Completer<User>();
    when(auth.login('person@example.com', 'example-password'))
        .thenAnswer((_) => response.future);
    final model = LoginViewModel(
      authUseCase: auth,
      appleSignInService: MockAppleSignInService(),
      googleSignInService: MockGoogleSignInService(),
    );
    final login = model.login('person@example.com', 'example-password');
    model.dispose();
    response.complete(User(email: 'person@example.com'));

    await expectLater(login, completes);
  });

  for (final response in [
    http.Response('Private upstream diagnostic', 503),
    http.Response('Private upstream diagnostic', 200),
    http.Response('["Private upstream diagnostic"]', 200),
  ]) {
    test('GitHub HTTP ${response.statusCode} hides raw response diagnostics',
        () async {
      final model = LoginViewModel(
        authUseCase: auth,
        appleSignInService: MockAppleSignInService(),
        googleSignInService: MockGoogleSignInService(),
      );
      await http.runWithClient(
        () async {
          await expectLater(
            model.httpPostForm(Uri.parse('https://github.com/test'), {}),
            throwsA(predicate<Object>((error) =>
                !error.toString().contains('Private upstream diagnostic') &&
                error.toString().contains('GitHub sign-in'))),
          );
        },
        () => MockClient((_) async => response),
      );
      model.dispose();
    });
  }
}
