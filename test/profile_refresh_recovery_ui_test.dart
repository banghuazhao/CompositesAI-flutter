import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/user_profile_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';
import 'package:swiftcomp/util/app_theme.dart';

class _Settings extends ChangeNotifier implements SettingsViewModel {
  int _generation = 0;

  @override
  bool isLoggedIn = true;

  @override
  int get sessionGeneration => _generation;

  @override
  void clearSession() {
    _generation++;
    isLoggedIn = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chat extends ChangeNotifier implements ChatViewModel {
  @override
  Future<void> clearChatStateOnLogout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _error = 'Could not refresh your profile. Please try again.';
const _expired = 'Your session has expired. Please sign in again.';
final _retry = find.byKey(const ValueKey('profile_refresh_retry'));
final _banner = find.byKey(const ValueKey('profile_refresh_error'));
final _progress = find.byKey(const ValueKey('profile_refresh_progress'));

void main() {
  late MockAuthUseCase auth;
  late MockUserUseCase users;
  late GlobalKey<NavigatorState> navigator;
  late Completer<Object?> routeResult;
  late _Settings currentSettings;

  User cachedUser() => User(
      id: 'cached-account',
      email: 'cached@example.test',
      name: 'Cached Person');

  setUp(() async {
    await sl.reset();
    auth = MockAuthUseCase();
    users = MockUserUseCase();
    sl.registerSingleton<AuthUseCase>(auth);
    sl.registerSingleton<UserUseCase>(users);
    navigator = GlobalKey<NavigatorState>();
  });

  tearDown(() async => sl.reset());

  Future<UserProfileViewModel> openProfile(
    WidgetTester tester, {
    User? user,
    bool dark = false,
    double textScale = 1,
  }) async {
    routeResult = Completer<Object?>();
    final settings = currentSettings = _Settings();
    final chat = _Chat();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
      chat.dispose();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
        ChangeNotifierProvider<ChatViewModel>.value(value: chat),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const Scaffold(body: Text('Settings host')),
      ),
    ));
    unawaited(navigator.currentState!
        .push<Object?>(MaterialPageRoute<Object?>(
          builder: (_) => UserProfilePage(user: user),
        ))
        .then(routeResult.complete));
    await tester.pumpAndSettle();
    return tester
        .element(find.byType(Consumer<UserProfileViewModel>))
        .read<UserProfileViewModel>();
  }

  Future<void> Function() refreshAction(WidgetTester tester) =>
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh;

  ButtonStyleButton retryButton(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(_retry);

  testWidgets(
      'Cached profile is shown without fetching and supports pull refresh',
      (tester) async {
    await openProfile(tester, user: cachedUser());

    expect(find.text('Cached Person'), findsOneWidget);
    expect(find.text('cached@example.test'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    final list = tester
        .widget<ListView>(find.byKey(const ValueKey('profile_refresh_list')));
    expect(list.physics, isA<AlwaysScrollableScrollPhysics>());
    expect(_banner, findsNothing);
    expect(_progress, findsNothing);
    verifyZeroInteractions(users);
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Transient refresh keeps cached identity and Retry is singleflight',
      (tester) async {
    final failed = Completer<User>();
    final recovered = Completer<User>();
    var calls = 0;
    when(users.fetchMe()).thenAnswer((_) {
      calls++;
      return calls == 1 ? failed.future : recovered.future;
    });
    final profile = await openProfile(tester, user: cachedUser());
    final firstRefresh = refreshAction(tester)();
    await tester.pump();
    expect(profile.isRefreshingProfile, isTrue);
    expect(_progress, findsOneWidget);
    expect(tester.widget(_progress), isA<LinearProgressIndicator>());
    expect(find.text('Cached Person'), findsOneWidget);
    expect(find.text('cached@example.test'), findsOneWidget);
    failed.completeError(TimeoutException('Private transport diagnostic'));
    await firstRefresh;
    await tester.pumpAndSettle();

    expect(profile.user, isNotNull);
    expect(profile.isSessionExpired, isFalse);
    expect(profile.profileRefreshError, _error);
    expect(_banner, findsOneWidget);
    expect(find.text(_error), findsOneWidget);
    expect(find.textContaining('Private transport diagnostic'), findsNothing);
    expect(retryButton(tester).onPressed, isNotNull);
    final repeatTap = retryButton(tester).onPressed!;
    await tester.ensureVisible(_retry);
    await tester.pumpAndSettle();
    await tester.tap(_retry);
    repeatTap();
    final duplicatePull = refreshAction(tester)();
    await tester.pump();

    expect(profile.isRefreshingProfile, isTrue);
    expect(_retry, findsNothing);
    expect(_banner, findsNothing);
    expect(_progress, findsOneWidget);
    expect(find.text('Cached Person'), findsOneWidget);
    expect(find.text('cached@example.test'), findsOneWidget);
    expect(calls, 2);
    recovered.complete(User(
        id: 'cached-account',
        email: 'cached@example.test',
        name: 'Recovered Person'));
    await duplicatePull;
    await tester.pumpAndSettle();

    expect(profile.isRefreshingProfile, isFalse);
    expect(profile.profileRefreshError, isNull);
    expect(_banner, findsNothing);
    expect(_progress, findsNothing);
    expect(find.text('Recovered Person'), findsOneWidget);
    expect(find.text('Cached Person'), findsNothing);
    verify(users.fetchMe()).called(2);
    verifyNever(users.deleteAccount());
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expired session hides private content and returns to settings',
      (tester) async {
    final response = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => response.future);
    final profile = await openProfile(tester, user: cachedUser());
    final refreshing = refreshAction(tester)();
    await tester.pump();
    response
        .completeError(UnauthorizedException('Private authorization detail'));
    await refreshing;
    await tester.pumpAndSettle();

    expect(profile.isSessionExpired, isTrue);
    expect(profile.user, isNull);
    expect(find.text(_expired), findsOneWidget);
    expect(find.text('Cached Person'), findsNothing);
    expect(find.text('cached@example.test'), findsNothing);
    for (final action in [
      'Change Name',
      'Update Password',
      'Sign Out',
      'Delete Account'
    ]) {
      expect(find.text(action), findsNothing);
    }
    expect(find.textContaining('Private authorization detail'), findsNothing);
    final back = find.byKey(const ValueKey('profile_session_back'));
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(routeResult.isCompleted, isTrue);
    expect(await routeResult.future, isNull);
    expect(find.text('Settings host'), findsOneWidget);
    expect(find.byType(UserProfilePage), findsNothing);
    verifyNever(users.deleteAccount());
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing profile offers safe recovery before account actions',
      (tester) async {
    final response = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => response.future);
    final profile = await openProfile(tester);
    expect(profile.isSessionExpired, isFalse);
    expect(profile.user, isNull);
    expect(_retry, findsOneWidget);
    verifyZeroInteractions(users);
    for (final action in [
      'Change Name',
      'Update Password',
      'Sign Out',
      'Delete Account'
    ]) {
      expect(find.text(action), findsNothing);
    }
    await tester.tap(_retry);
    await tester.pump();
    expect(profile.isRefreshingProfile, isTrue);
    expect(retryButton(tester).onPressed, isNull);
    response.complete(cachedUser());
    await tester.pumpAndSettle();

    expect(profile.user, isNotNull);
    expect(find.text('Cached Person'), findsOneWidget);
    expect(find.text('cached@example.test'), findsOneWidget);
    expect(find.text('Change Name'), findsOneWidget);
    verify(users.fetchMe()).called(1);
    verifyNever(users.deleteAccount());
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry banner stays usable on a narrow dark screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final response = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => response.future);
    await openProfile(tester, user: cachedUser(), dark: true, textScale: 1.4);
    final refreshing = refreshAction(tester)();
    await tester.pump();
    response.completeError(TimeoutException('Private timeout detail'));
    await refreshing;
    await tester.pumpAndSettle();
    await tester.ensureVisible(_banner);
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(_banner)).brightness, Brightness.dark);
    expect(_retry.hitTestable(), findsOneWidget);
    expect(tester.getRect(_retry).right, lessThanOrEqualTo(320));
    expect(tester.getRect(_retry).left, greaterThanOrEqualTo(0));
    expect(find.text(_error), findsOneWidget);
    expect(find.textContaining('Private timeout detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Refresh completion after Back cannot restore the profile route',
      (tester) async {
    final response = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => response.future);
    await openProfile(tester, user: cachedUser());
    final refreshing = refreshAction(tester)();
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    response.completeError(TimeoutException('Private late response'));
    await refreshing;
    await tester.pumpAndSettle();

    expect(routeResult.isCompleted, isTrue);
    expect(await routeResult.future, isNull);
    expect(find.text('Settings host'), findsOneWidget);
    expect(find.byType(UserProfilePage), findsNothing);
    expect(find.text(_error), findsNothing);
    verify(users.fetchMe()).called(1);
    verifyNever(users.deleteAccount());
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Settings session changes hide cached details before refresh completes',
      (tester) async {
    final response = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => response.future);
    final profile = await openProfile(tester, user: cachedUser());
    final refreshing = refreshAction(tester)();
    await tester.pump();

    currentSettings.clearSession();
    await tester.pump();

    expect(find.text(_expired), findsOneWidget);
    expect(find.text('Cached Person'), findsNothing);
    expect(find.text('cached@example.test'), findsNothing);
    expect(find.text('Change Name'), findsNothing);
    expect(find.text('Update Password'), findsNothing);
    expect(_retry, findsNothing);
    response.complete(cachedUser());
    await refreshing;
    await tester.pumpAndSettle();

    expect(profile.user, isNull);
    expect(profile.isSessionExpired, isTrue);
    expect(find.text(_expired), findsOneWidget);
    expect(find.text('Cached Person'), findsNothing);
    verify(users.fetchMe()).called(1);
    verifyNever(users.deleteAccount());
    verifyZeroInteractions(auth);
    expect(tester.takeException(), isNull);
  });
}
