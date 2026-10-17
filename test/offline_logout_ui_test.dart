import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/user_profile_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';

class _GlobalChat extends ChangeNotifier implements ChatViewModel {
  bool privateStatePresent = true;
  int clearCalls = 0;
  Completer<void>? transportCleanup;

  @override
  Future<void> clearChatStateOnLogout() {
    clearCalls++;
    privateStatePresent = false;
    notifyListeners();
    return transportCleanup?.future ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GlobalSettings extends ChangeNotifier implements SettingsViewModel {
  bool privateStatePresent = true;
  int clearCalls = 0;

  @override
  void clearSession() {
    clearCalls++;
    privateStatePresent = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigation extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

void main() {
  late MockAuthUseCase auth;
  late MockUserUseCase users;
  late Completer<void> logout;
  late _GlobalChat chat;
  late _GlobalSettings settings;
  late GlobalKey<NavigatorState> navigator;
  late _Navigation navigation;
  final originalUser = User(id: 'test-user', email: 'user@example.test');

  setUp(() async {
    await sl.reset();
    auth = MockAuthUseCase();
    users = MockUserUseCase();
    when(auth.logout()).thenAnswer((_) => logout.future);
    sl.registerSingleton<AuthUseCase>(auth);
    sl.registerSingleton<UserUseCase>(users);
    chat = _GlobalChat();
    settings = _GlobalSettings();
    navigator = GlobalKey<NavigatorState>();
    navigation = _Navigation();
  });

  tearDown(() async => sl.reset());

  Future<UserProfileViewModel> openProfile(WidgetTester tester) async {
    // Create async UI fixtures in testWidgets' fake-async zone so pump flushes
    // their continuations instead of leaving them on setUp's outer zone.
    logout = Completer<void>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      chat.dispose();
      settings.dispose();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatViewModel>.value(value: chat),
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [navigation],
        home: const Scaffold(body: Text('Root page')),
      ),
    ));
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Account page')),
    )));
    await tester.pumpAndSettle();
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
      builder: (_) => UserProfilePage(user: originalUser),
    )));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Consumer<UserProfileViewModel>));
    final profile = context.read<UserProfileViewModel>();
    profile.isSignedIn = true;
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    return profile;
  }

  testWidgets(
      'pending logout clears global state after Back without another pop',
      (tester) async {
    final profile = await openProfile(tester);
    var notifications = 0;
    profile.addListener(() => notifications++);
    await tester.tap(find.text('Sign Out'));
    await tester.pump();
    expect(profile.isLoading, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(UserProfilePage), findsNothing);
    expect(find.text('Account page'), findsOneWidget);
    final notificationsAfterUnmount = notifications;
    expect(navigation.pops, 1);

    logout.complete();
    await tester.pumpAndSettle();

    expect(profile.user, isNull);
    expect(profile.isSignedIn, isFalse);
    expect(profile.isLoading, isFalse);
    expect(notifications, notificationsAfterUnmount);
    expect(chat.privateStatePresent, isFalse);
    expect(settings.privateStatePresent, isFalse);
    expect(chat.clearCalls, 1);
    expect(settings.clearCalls, 1);
    expect(navigation.pops, 1);
    expect(find.text('Account page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'an old profile response cannot restore a locally logged-out user',
      (tester) async {
    final profile = await openProfile(tester);
    final pendingProfile = Completer<User>();
    when(users.fetchMe()).thenAnswer((_) => pendingProfile.future);
    final fetching = profile.fetchUser();
    await tester.tap(find.text('Sign Out'));
    await tester.pump();
    // Keep the profile mounted beneath another route to exercise request
    // invalidation independently of the disposed-notifier guard.
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('New route')),
    )));
    await tester.pumpAndSettle();

    logout.complete();
    await tester.pumpAndSettle();
    expect(profile.user, isNull);
    expect(chat.privateStatePresent, isFalse);
    expect(settings.privateStatePresent, isFalse);
    expect(find.text('New route'), findsOneWidget);
    expect(navigation.pops, 0);

    pendingProfile.complete(originalUser);
    await fetching;
    await tester.pump();

    expect(profile.user, isNull);
    expect(profile.isSignedIn, isFalse);
    expect(find.text('New route'), findsOneWidget);
    expect(navigation.pops, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local logout failure retains state and presents a safe error',
      (tester) async {
    final profile = await openProfile(tester);
    await tester.tap(find.text('Sign Out'));
    await tester.pump();

    logout.completeError(StateError('Private storage diagnostic'));
    await tester.pumpAndSettle();

    expect(profile.user, same(originalUser));
    expect(profile.isSignedIn, isTrue);
    expect(profile.isLoading, isFalse);
    expect(chat.privateStatePresent, isTrue);
    expect(settings.privateStatePresent, isTrue);
    expect(chat.clearCalls, 0);
    expect(settings.clearCalls, 0);
    expect(navigation.pops, 0);
    expect(find.byType(UserProfilePage), findsOneWidget);
    expect(find.text('Logout failed. Please try again.'), findsOneWidget);
    expect(find.textContaining('Private storage diagnostic'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'duplicate logout taps and direct requests reach the use case once',
      (tester) async {
    final profile = await openProfile(tester);
    final context = tester.element(find.byType(Consumer<UserProfileViewModel>));
    final row = find.ancestor(
      of: find.text('Sign Out'),
      matching: find.byType(InkWell),
    );
    final onTap = tester.widget<InkWell>(row).onTap!;
    await tester.tap(find.text('Sign Out'));
    onTap();
    expect(await profile.logoutUser(context), isFalse);
    await tester.pump();
    verify(auth.logout()).called(1);

    logout.complete();
    await tester.pumpAndSettle();

    expect(chat.clearCalls, 1);
    expect(settings.clearCalls, 1);
    expect(navigation.pops, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'completed local logout does not await slow chat transport cleanup',
      (tester) async {
    await openProfile(tester);
    chat.transportCleanup = Completer<void>();
    await tester.tap(find.text('Sign Out'));
    await tester.pump();

    logout.complete();
    await tester.pumpAndSettle();

    expect(find.byType(UserProfilePage), findsNothing);
    expect(find.text('Account page'), findsOneWidget);
    expect(chat.privateStatePresent, isFalse);
    expect(settings.privateStatePresent, isFalse);
    expect(navigation.pops, 1);
    chat.transportCleanup!
        .completeError(StateError('Private cleanup diagnostic'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
