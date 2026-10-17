import 'dart:async';

import 'package:domain/auth/entities/expert_upgrade_request.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';

class _Auth extends Fake implements AuthUseCase {
  Future<bool> Function()? checkSession;
  Future<void> Function()? signOut;
  int logoutCalls = 0;

  @override
  Future<bool> isLoggedIn() async =>
      checkSession == null ? false : await checkSession!();

  @override
  Future<void> logout() async {
    logoutCalls++;
    await signOut?.call();
  }
}

class _Users extends Fake implements UserUseCase {
  Future<User> Function()? loadProfile;
  Future<List<ExpertUpgradeRequest>> Function()? loadPendingRequests;
  Future<ExpertUpgradeRequest?> Function(String)? loadPersonalRequest;
  Future<ExpertUpgradeRequest> Function()? submitRequest;
  Future<void> Function()? updateName;
  Future<void> Function()? approveRequest;
  int profileCalls = 0;

  @override
  Future<User> fetchMe() {
    profileCalls++;
    return loadProfile!();
  }

  @override
  Future<List<ExpertUpgradeRequest>> fetchPendingExpertRequests() async =>
      loadPendingRequests == null ? [] : await loadPendingRequests!();

  @override
  Future<ExpertUpgradeRequest?> fetchExpertRequestForUser(
          String userId) async =>
      loadPersonalRequest == null ? null : await loadPersonalRequest!(userId);

  @override
  Future<ExpertUpgradeRequest> requestExpertUpgrade(
    String userId,
    String requesterNotes,
  ) =>
      submitRequest!();

  @override
  Future<void> updateMe(String newName) async => await updateName?.call();

  @override
  Future<void> approveExpertRequest(ExpertUpgradeRequest request) async =>
      await approveRequest?.call();
}

ExpertUpgradeRequest _request(String owner) => ExpertUpgradeRequest(
      id: 'request-$owner',
      userId: owner,
      requestedLevel: 'expert',
      status: 'pending',
      requesterNotes: 'Review request',
      createdAt: 1,
      updatedAt: 1,
    );

void _expectSignedOut(SettingsViewModel model) {
  expect(model.user, isNull);
  expect(model.isLoggedIn, isFalse);
  expect(model.isExpert, isFalse);
  expect(model.isAdmin, isFalse);
  expect(model.pendingExpertRequestCount, 0);
  expect(model.currentExpertRequest, isNull);
  expect(model.isLoadingExpertRequestMetadata, isFalse);
  expect(model.submission, isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Auth auth;
  late _Users users;
  late FeatureFlagProvider featureFlags;
  SettingsViewModel? model;
  final accountA = User(
    id: 'account-a',
    email: 'a@example.test',
    isAdmin: true,
    isCompositeExpert: true,
  );
  final accountB = User(id: 'account-b', email: 'b@example.test');

  SettingsViewModel createModel() => model = SettingsViewModel(
        authUseCase: auth,
        userUserCase: users,
        featureFlagProvider: featureFlags,
      );

  Future<SettingsViewModel> signedIn(User user) async {
    final value = createModel();
    await value.fetchAuthSessionNew();
    value.updateUser(user);
    return value;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({'Chat': true});
    PackageInfo.setMockInitialValues(
      appName: 'Test App',
      packageName: 'example.test',
      version: '1.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
    auth = _Auth();
    users = _Users();
    featureFlags = FeatureFlagProvider();
    model = null;
  });

  tearDown(() {
    model?.dispose();
    featureFlags.dispose();
  });

  test(
      'clearSession synchronously clears account data and preserves preferences',
      () async {
    final value = await signedIn(accountA);
    value.pendingExpertRequestCount = 4;
    value.currentExpertRequest = _request('account-a');
    value.isLoadingExpertRequestMetadata = true;
    value.isLoading = true;
    value.submission = 'success';
    final version = value.version;

    value.clearSession();

    _expectSignedOut(value);
    expect(value.isLoading, isFalse);
    expect(value.version, version);
    expect(value.featureFlagProvider.getFeatureFlag('Chat'), isTrue);
  });

  test('a pending session check cannot restore the account after local clear',
      () async {
    final session = Completer<bool>();
    auth.checkSession = () => session.future;
    final value = createModel();

    value.clearSession();
    session.complete(true);
    await Future<void>.delayed(Duration.zero);

    _expectSignedOut(value);
    expect(users.profileCalls, 0);
  });

  test('a stale signed-out check cannot clear a newly supplied account',
      () async {
    final session = Completer<bool>();
    auth.checkSession = () => session.future;
    final value = createModel();

    value.updateUser(accountB);
    session.complete(false);
    await Future<void>.delayed(Duration.zero);

    expect(value.user, same(accountB));
    expect(value.isLoggedIn, isTrue);
  });

  test('profile success after logout cannot restore user or role flags',
      () async {
    final value = await signedIn(accountA);
    final response = Completer<User>();
    users.loadProfile = () => response.future;
    final lookup = value.fetchUser();

    value.clearSession();
    response.complete(accountA);
    await lookup;

    _expectSignedOut(value);
  });

  for (final unauthorized in [false, true]) {
    test('old profile ${unauthorized ? '401' : 'success'} preserves account B',
        () async {
      final value = await signedIn(accountA);
      final response = Completer<User>();
      users.loadProfile = () => response.future;
      final lookup = value.fetchUser();

      value.updateUser(accountB);
      if (unauthorized) {
        response.completeError(UnauthorizedException());
      } else {
        response.complete(accountA);
      }
      await lookup;

      expect(value.user, same(accountB));
      expect(value.isLoggedIn, isTrue);
      expect(value.isAdmin, isFalse);
      expect(value.isExpert, isFalse);
    });
  }

  test('pending administrator metadata cannot return after logout', () async {
    final value = await signedIn(accountA);
    final response = Completer<List<ExpertUpgradeRequest>>();
    users.loadPendingRequests = () => response.future;
    final lookup = value.refreshExpertRequestMetadata();
    expect(value.isLoadingExpertRequestMetadata, isTrue);

    value.clearSession();
    response.complete([_request('account-a')]);
    await lookup;

    _expectSignedOut(value);
  });

  test('old metadata cannot replace B data or clear B loading state', () async {
    final personalA = User(id: 'account-a', email: 'a@example.test');
    final value = await signedIn(personalA);
    final responseA = Completer<ExpertUpgradeRequest?>();
    final responseB = Completer<ExpertUpgradeRequest?>();
    users.loadPersonalRequest =
        (owner) => owner == 'account-a' ? responseA.future : responseB.future;
    final lookupA = value.refreshExpertRequestMetadata();

    value.updateUser(accountB);
    final lookupB = value.refreshExpertRequestMetadata();
    responseA.complete(_request('account-a'));
    await lookupA;

    expect(value.user, same(accountB));
    expect(value.currentExpertRequest, isNull);
    expect(value.isLoadingExpertRequestMetadata, isTrue);
    responseB.complete(_request('account-b'));
    await lookupB;
    expect(value.currentExpertRequest?.userId, 'account-b');
    expect(value.isLoadingExpertRequestMetadata, isFalse);
  });

  test('old metadata unauthorized response does not log out B', () async {
    final value = await signedIn(accountA);
    final response = Completer<List<ExpertUpgradeRequest>>();
    users.loadPendingRequests = () => response.future;
    final lookup = value.refreshExpertRequestMetadata();

    value.updateUser(accountB);
    response.completeError(UnauthorizedException());
    await lookup;

    expect(value.user, same(accountB));
    expect(value.isLoggedIn, isTrue);
    expect(value.pendingExpertRequestCount, 0);
  });

  test('transient profile failure preserves the current verified account',
      () async {
    final value = await signedIn(accountA);
    value.pendingExpertRequestCount = 2;
    users.loadProfile =
        () => Future<User>.error(TimeoutException('Test timeout'));

    await value.fetchUser();

    expect(value.user, same(accountA));
    expect(value.isLoggedIn, isTrue);
    expect(value.isAdmin, isTrue);
    expect(value.isExpert, isTrue);
    expect(value.pendingExpertRequestCount, 2);
  });

  test('confirmed unauthorized profile clears all local account state',
      () async {
    final value = await signedIn(accountA);
    value.pendingExpertRequestCount = 2;
    users.loadProfile = () => Future<User>.error(UnauthorizedException());

    await value.fetchUser();

    _expectSignedOut(value);
  });

  test('a session check failure preserves a verified profile', () async {
    final value = await signedIn(accountA);
    auth.checkSession =
        () => Future<bool>.error(TimeoutException('Test timeout'));

    await value.fetchAuthSessionNew();

    expect(value.user, same(accountA));
    expect(value.isLoggedIn, isTrue);
    expect(value.isAdmin, isTrue);
  });

  test('a first profile timeout does not publish a signed-in empty profile',
      () async {
    final value = createModel();
    await value.fetchAuthSessionNew();
    auth.checkSession = () async => true;
    users.loadProfile =
        () => Future<User>.error(TimeoutException('Test timeout'));

    await value.fetchAuthSessionNew();

    _expectSignedOut(value);
  });

  test(
      'late name, request and review completions cannot modify another account',
      () async {
    final value = await signedIn(accountA);
    final name = Completer<void>();
    final submission = Completer<ExpertUpgradeRequest>();
    final approval = Completer<void>();
    users.updateName = () => name.future;
    users.submitRequest = () => submission.future;
    users.approveRequest = () => approval.future;
    final rename = value.updateUserName('Old account name');
    final submit = value.submitExpertRequest('Test reason', '');
    final approve = value.approveExpertRequest(_request('account-a'));

    value.updateUser(accountB);
    value.pendingExpertRequestCount = 5;
    final previousName = accountB.name;
    name.complete();
    submission.complete(_request('account-a'));
    approval.complete();
    await Future.wait([rename, submit, approve]);

    expect(value.user, same(accountB));
    expect(accountB.name, previousName);
    expect(value.currentExpertRequest, isNull);
    expect(value.pendingExpertRequestCount, 5);
  });

  testWidgets('successful legacy logout clears even after its context unmounts',
      (tester) async {
    final value = await signedIn(accountA);
    final completion = Completer<void>();
    auth.signOut = () => completion.future;
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold();
    })));
    final logout = value.newLogout(context);
    final duplicate = value.newLogout(context);
    await tester.pumpWidget(const SizedBox());
    completion.complete();
    await Future.wait([logout, duplicate]);

    _expectSignedOut(value);
    expect(auth.logoutCalls, 1);
  });

  testWidgets('legacy logout failure preserves account state', (tester) async {
    final value = await signedIn(accountA);
    auth.signOut = () => Future<void>.error(StateError('Test storage failure'));
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold();
    })));

    await value.newLogout(context);
    await tester.pump();

    expect(value.user, same(accountA));
    expect(value.isLoggedIn, isTrue);
    expect(find.text('Failed to log out. Please try again.'), findsOneWidget);
  });
}
