import 'package:domain/auth/entities/auth_session.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
// The native boundary confirms configuration is checked before invoking an SDK.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/app/services/mac_oauth_configuration.dart';
import 'package:swiftcomp/app/services/microsoft_sign_in_service.dart';
import 'package:swiftcomp/presentation/auth/login_page.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';

class _GooglePlatform extends GoogleSignInPlatform {
  final initializations = <InitParameters>[];
  int authentications = 0;

  @override
  Future<void> init(InitParameters params) async {
    initializations.add(params);
  }

  @override
  Future<AuthenticationResults> authenticate(
      AuthenticateParameters params) async {
    authentications++;
    return const AuthenticationResults(
      user: GoogleSignInUserData(email: 'mac@example.test', id: 'google-user'),
      authenticationTokens: AuthenticationTokenData(idToken: 'test-token'),
    );
  }

  @override
  bool supportsAuthenticate() => true;
  @override
  bool authorizationRequiresUserInteraction() => false;
  @override
  Future<AuthenticationResults?> attemptLightweightAuthentication(
          AttemptLightweightAuthenticationParameters params) async =>
      null;
  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters params) async =>
      null;
  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
          ServerAuthorizationTokensForScopesParameters params) async =>
      null;
  @override
  Future<void> signOut(SignOutParams params) async {}
  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

class _Auth extends MockAuthUseCase {
  final exchanged = <String>[];

  @override
  Future<AuthSession> validateGoogleToken(String token) async {
    exchanged.add(token);
    return AuthSession(
      token: 'test-session',
      user: User(id: 'user', email: 'mac@example.test'),
    );
  }
}

class _Google extends GoogleSignInService {
  final clientIds = <String?>[];
  final serverClientIds = <String?>[];

  @override
  Future<GoogleSignInUser?> signIn({
    List<String> scopes = const [],
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) async {
    clientIds.add(clientId);
    serverClientIds.add(serverClientId);
    return GoogleSignInUser(email: 'mac@example.test', idToken: 'id-token');
  }
}

const _genericConfiguration = 'GOOGLE_SIGNIN_CLIENT_ID_IOS=ios-test-client\n'
    'GOOGLE_SIGNIN_CLIENT_ID_ANDROID=android-test-client\n'
    'GOOGLE_SIGNIN_CLIENT_ID_WEB=web-test-client\n'
    'MICROSOFT_CLIENT_ID=microsoft-test-client';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GoogleSignInPlatform previousGoogle;
  final googlePlatform = _GooglePlatform();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const microsoftChannel = MethodChannel('msal_auth');
  late _Auth auth;
  late _Google google;

  LoginViewModel createModel() => LoginViewModel(
        authUseCase: auth,
        appleSignInService: MockAppleSignInService(),
        googleSignInService: google,
      );

  setUpAll(() {
    previousGoogle = GoogleSignInPlatform.instance;
    GoogleSignInPlatform.instance = googlePlatform;
  });
  tearDownAll(() => GoogleSignInPlatform.instance = previousGoogle);
  setUp(() async {
    dotenv.loadFromString(envString: _genericConfiguration);
    auth = _Auth();
    google = _Google();
    await sl.reset();
    sl.registerFactory<LoginViewModel>(createModel);
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(microsoftChannel, null);
    await sl.reset();
    dotenv.clean();
  });

  for (final extra in [
    '',
    '\nGOOGLE_SIGNIN_CLIENT_ID_MACOS="   "\nMICROSOFT_MACOS_AUTH_ENABLED=false'
  ]) {
    testWidgets(
        'Mac generic provider settings do not expose unconfigured login ($extra)',
        (tester) async {
      dotenv.loadFromString(envString: '$_genericConfiguration$extra');
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_google')), findsNothing);
      expect(find.byKey(const Key('login_microsoft')), findsNothing);
      expect(find.byKey(const Key('login_apple')), findsOneWidget);
      expect(find.byKey(const Key('login_github')), findsOneWidget);
      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);
  }

  testWidgets(
      'Mac providers become visible only for their explicit configuration',
      (tester) async {
    dotenv.loadFromString(
        envString:
            '$_genericConfiguration\nGOOGLE_SIGNIN_CLIENT_ID_MACOS=mac-test-client');
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_google')), findsOneWidget);
    expect(find.byKey(const Key('login_microsoft')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    dotenv.loadFromString(
        envString: '$_genericConfiguration\nMICROSOFT_MACOS_AUTH_ENABLED=true');
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_google')), findsNothing);
    expect(find.byKey(const Key('login_microsoft')), findsOneWidget);
    expect(find.byKey(const Key('login_apple')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('Mac direct Google service cannot use another platform client ID',
      (tester) async {
    final service = GoogleSignInServiceImpl(
        macOSClientId: () => MacOAuthConfiguration.googleClientId);
    await expectLater(
        service.signIn(clientId: 'ios-test-client'), throwsStateError);
    expect(googlePlatform.initializations, isEmpty);
    expect(googlePlatform.authentications, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('Mac configured Google service passes the Mac client to the SDK',
      (tester) async {
    dotenv.loadFromString(
        envString:
            '$_genericConfiguration\nGOOGLE_SIGNIN_CLIENT_ID_MACOS=mac-test-client');
    final service = GoogleSignInServiceImpl(
        macOSClientId: () => MacOAuthConfiguration.googleClientId);
    final result = await service.signIn(clientId: 'ios-test-client');
    expect(googlePlatform.initializations.single.clientId, 'mac-test-client');
    expect(googlePlatform.authentications, 1);
    expect(result!.email, 'mac@example.test');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets(
      'Mac direct Google model skips SDK and backend without Mac config',
      (tester) async {
    final model = createModel();
    addTearDown(model.dispose);
    await model.signInWithGoogle();
    expect(google.clientIds, isEmpty);
    expect(auth.exchanged, isEmpty);
    expect(model.isLoading, isFalse);
    expect(model.isSigningIn, isFalse);
    expect(model.errorMessage, isNotNull);
    dotenv.loadFromString(
        envString:
            '$_genericConfiguration\nGOOGLE_SIGNIN_CLIENT_ID_MACOS=mac-test-client');
    await model.signInWithGoogle();
    expect(google.clientIds, ['mac-test-client']);
    expect(google.serverClientIds, ['web-test-client']);
    expect(auth.exchanged, ['id-token']);
    expect(model.isSigningIn, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  for (final flag in ['', 'false', '1']) {
    testWidgets('Mac Microsoft service rejects missing/disabled opt-in ($flag)',
        (tester) async {
      dotenv.loadFromString(
          envString:
              '$_genericConfiguration\nMICROSOFT_MACOS_AUTH_ENABLED=$flag');
      final calls = <String>[];
      messenger.setMockMethodCallHandler(microsoftChannel, (call) async {
        calls.add(call.method);
        throw MissingPluginException('should not reach native SDK');
      });
      await expectLater(MicrosoftSignInServiceImpl().acquireAccessToken(),
          throwsA(isA<MicrosoftSignInConfigurationException>()));
      expect(calls, isEmpty);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);
  }

  testWidgets('Mac Microsoft opt-in enables the configured native login path',
      (tester) async {
    dotenv.loadFromString(
        envString: '$_genericConfiguration\nMICROSOFT_MACOS_AUTH_ENABLED=true');
    final calls = <String>[];
    messenger.setMockMethodCallHandler(microsoftChannel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: 'USER_CANCEL');
    });
    expect(await MicrosoftSignInServiceImpl().acquireAccessToken(), isNull);
    expect(calls, ['createMultipleAccountPca']);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform Google arguments remain independent of Mac config',
        (tester) async {
      final model = createModel();
      addTearDown(model.dispose);
      await model.signInWithGoogle();
      expect(google.clientIds, [null]);
      expect(google.serverClientIds, ['web-test-client']);
      expect(auth.exchanged, ['id-token']);
    }, variant: TargetPlatformVariant.only(platform), skip: kIsWeb);
  }
}
