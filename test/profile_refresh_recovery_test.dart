import 'dart:async';
import 'dart:io';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/settings/viewModels/user_profile_view_model.dart';

class _Auth extends Fake implements AuthUseCase {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _Users extends Fake implements UserUseCase {
  int profileCalls = 0;
  int deleteCalls = 0;
  Future<User> Function()? profile;

  @override
  Future<User> fetchMe() {
    profileCalls++;
    return profile!();
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
  }
}

class _UnmountedContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}

void main() {
  const transientError = 'Could not refresh your profile. Please try again.';
  const expiredError = 'Your session has expired. Please sign in again.';
  late _Auth auth;
  late _Users users;
  late User cached;
  UserProfileViewModel? model;
  var disposed = false;

  User refreshed() => User(
        id: 'account-a',
        email: 'person@example.test',
        name: 'Fresh name',
        avatarUrl: '/fresh-avatar.png',
      );

  UserProfileViewModel createModel({
    bool withCachedUser = true,
    bool Function()? isCurrentSession,
  }) {
    final value = UserProfileViewModel(
      authUseCase: auth,
      userUseCase: users,
      user: withCachedUser ? cached : null,
      isCurrentSession: isCurrentSession,
    );
    model = value;
    return value;
  }

  void expectCached(UserProfileViewModel value) {
    expect(value.user, same(cached));
    expect(value.user!.name, 'Cached name');
    expect(value.user!.email, 'person@example.test');
    expect(value.user!.avatarUrl, '/cached-avatar.png');
    expect(value.isSignedIn, isTrue);
    expect(value.isSessionExpired, isFalse);
  }

  setUp(() {
    auth = _Auth();
    users = _Users();
    cached = User(
      id: 'account-a',
      email: 'person@example.test',
      name: 'Cached name',
      avatarUrl: '/cached-avatar.png',
    );
    model = null;
    disposed = false;
  });

  tearDown(() {
    if (!disposed) model?.dispose();
  });

  final transientFailures = <String, Object>{
    'timeout': TimeoutException('Private profile diagnostic'),
    'network': const SocketException('Private profile diagnostic'),
    'server': InternalServerErrorException('Private profile diagnostic'),
    'unexpected': StateError('Private profile diagnostic'),
  };

  for (final failure in transientFailures.entries) {
    test('${failure.key} refresh failure preserves all cached account details',
        () async {
      users.profile = () => Future<User>.error(failure.value);
      final value = createModel();

      await value.fetchUser();

      expectCached(value);
      expect(value.isRefreshingProfile, isFalse);
      expect(value.isLoading, isFalse);
      expect(value.profileRefreshError, transientError);
      expect(value.profileRefreshError, isNot(contains('Private')));
      expect(users.profileCalls, 1);
      expect(auth.logoutCalls, 0);
    });
  }

  test(
      'Retry clears the transient error while pending and publishes fresh data',
      () async {
    users.profile = () => Future<User>.error(TimeoutException('Test timeout'));
    final value = createModel();
    await value.fetchUser();
    expect(value.profileRefreshError, transientError);
    final response = Completer<User>();
    users.profile = () => response.future;

    final retry = value.fetchUser();

    expect(value.isRefreshingProfile, isTrue);
    expect(value.isLoading, isFalse);
    expect(value.profileRefreshError, isNull);
    expectCached(value);
    final fresh = refreshed();
    response.complete(fresh);
    await retry;

    expect(value.user, same(fresh));
    expect(value.isSignedIn, isTrue);
    expect(value.isRefreshingProfile, isFalse);
    expect(value.profileRefreshError, isNull);
    expect(value.isSessionExpired, isFalse);
    expect(users.profileCalls, 2);
  });

  test('Retry failure restores the safe error without discarding the cache',
      () async {
    users.profile = () => Future<User>.error(TimeoutException('Test timeout'));
    final value = createModel();
    await value.fetchUser();
    final response = Completer<User>();
    users.profile = () => response.future;

    final retry = value.fetchUser();
    expect(value.profileRefreshError, isNull);
    response
        .completeError(InternalServerErrorException('Private server detail'));
    await retry;

    expectCached(value);
    expect(value.isRefreshingProfile, isFalse);
    expect(value.profileRefreshError, transientError);
    expect(users.profileCalls, 2);
  });

  test('repeated refresh requests share one pending lookup', () async {
    final response = Completer<User>();
    users.profile = () => response.future;
    final value = createModel();

    final pending = value.fetchUser();
    final duplicate = value.fetchUser();
    final another = value.fetchUser();

    expect(users.profileCalls, 1);
    expect(value.isRefreshingProfile, isTrue);
    expectCached(value);
    response.complete(refreshed());
    await Future.wait([pending, duplicate, another]);

    expect(users.profileCalls, 1);
    expect(value.isRefreshingProfile, isFalse);
    expect(value.profileRefreshError, isNull);
  });

  test('a first lookup failure has no fabricated profile and Retry can recover',
      () async {
    users.profile = () => Future<User>.error(TimeoutException('Test timeout'));
    final value = createModel(withCachedUser: false);

    await value.fetchUser();

    expect(value.user, isNull);
    expect(value.isSignedIn, isFalse);
    expect(value.isSessionExpired, isFalse);
    expect(value.profileRefreshError, transientError);
    final fresh = refreshed();
    users.profile = () async => fresh;

    await value.fetchUser();

    expect(value.user, same(fresh));
    expect(value.isSignedIn, isTrue);
    expect(value.profileRefreshError, isNull);
    expect(value.isRefreshingProfile, isFalse);
  });

  for (final withCache in [false, true]) {
    test(
        'unauthorized lookup clears ${withCache ? 'cached' : 'empty'} session and disables Retry',
        () async {
      users.profile = () => Future<User>.error(
            UnauthorizedException('Private server detail'),
          );
      final value = createModel(withCachedUser: withCache);

      await value.fetchUser();

      expect(value.user, isNull);
      expect(value.isSignedIn, isFalse);
      expect(value.isSessionExpired, isTrue);
      expect(value.profileRefreshError, expiredError);
      expect(value.isRefreshingProfile, isFalse);

      users.profile = () async => refreshed();
      await value.fetchUser();

      expect(users.profileCalls, 1);
      expect(value.user, isNull);
      expect(value.profileRefreshError, expiredError);
      expect(auth.logoutCalls, 0);
    });
  }

  for (final fails in [false, true]) {
    test('disposal ignores a late profile ${fails ? 'error' : 'success'}',
        () async {
      final response = Completer<User>();
      users.profile = () => response.future;
      final value = createModel();
      final pending = value.fetchUser();
      var notifications = 0;
      value.addListener(() => notifications++);
      value.dispose();
      disposed = true;

      if (fails) {
        response.completeError(UnauthorizedException('Private server detail'));
      } else {
        response.complete(refreshed());
      }
      await pending;
      await value.fetchUser();

      expect(value.user, same(cached));
      expect(cached.name, 'Cached name');
      expect(notifications, 0);
      expect(users.profileCalls, 1);
    });
  }

  test('confirmed name clears an earlier refresh error without another request',
      () async {
    users.profile = () => Future<User>.error(TimeoutException('Test timeout'));
    final value = createModel();
    await value.fetchUser();

    value.applyConfirmedName(' Confirmed name ');

    expect(value.user, same(cached));
    expect(value.user!.name, 'Confirmed name');
    expect(value.user!.email, 'person@example.test');
    expect(value.user!.avatarUrl, '/cached-avatar.png');
    expect(value.profileRefreshError, isNull);
    expect(value.isRefreshingProfile, isFalse);
    expect(users.profileCalls, 1);
  });

  for (final fails in [false, true]) {
    test(
        'confirmed name invalidates a pending ${fails ? 'error' : 'success'} result',
        () async {
      final oldResponse = Completer<User>();
      final newResponse = Completer<User>();
      users.profile = () => oldResponse.future;
      final value = createModel();
      final oldLookup = value.fetchUser();

      value.applyConfirmedName('Confirmed name');
      expect(value.isRefreshingProfile, isFalse);
      expect(value.profileRefreshError, isNull);
      users.profile = () => newResponse.future;
      final newLookup = value.fetchUser();
      expect(users.profileCalls, 2);
      expect(value.isRefreshingProfile, isTrue);

      if (fails) {
        oldResponse
            .completeError(UnauthorizedException('Private server detail'));
      } else {
        oldResponse.complete(refreshed());
      }
      await oldLookup;

      expect(value.user!.name, 'Confirmed name');
      expect(value.isSignedIn, isTrue);
      expect(value.isSessionExpired, isFalse);
      expect(value.isRefreshingProfile, isTrue);
      expect(value.profileRefreshError, isNull);

      final fresh = refreshed();
      newResponse.complete(fresh);
      await newLookup;
      expect(value.user, same(fresh));
      expect(value.isRefreshingProfile, isFalse);
    });
  }

  for (final action in ['logout', 'delete']) {
    test('$action invalidates a pending lookup without restoring cached data',
        () async {
      final response = Completer<User>();
      users.profile = () => response.future;
      final value = createModel();
      final pending = value.fetchUser();

      final successful = action == 'logout'
          ? await value.logoutUser(_UnmountedContext())
          : await value.deleteUser();

      expect(successful, isTrue);
      expect(value.user, isNull);
      expect(value.isSignedIn, isFalse);
      expect(value.isRefreshingProfile, isFalse);
      expect(value.profileRefreshError, isNull);
      response.complete(refreshed());
      await pending;

      expect(value.user, isNull);
      expect(value.isSignedIn, isFalse);
      expect(value.isRefreshingProfile, isFalse);
      expect(value.profileRefreshError, isNull);
      expect(auth.logoutCalls, action == 'logout' ? 1 : 0);
      expect(users.deleteCalls, action == 'delete' ? 1 : 0);
    });
  }

  test('a stale page session is cleared before any profile lookup', () async {
    users.profile = () async => refreshed();
    final value = createModel(isCurrentSession: () => false);

    await value.fetchUser();

    expect(users.profileCalls, 0);
    expect(value.user, isNull);
    expect(value.isSignedIn, isFalse);
    expect(value.isRefreshingProfile, isFalse);
    expect(auth.logoutCalls, 0);
    expect(users.deleteCalls, 0);
  });

  for (final hasId in [false, true]) {
    test(
        'a different account ${hasId ? 'ID' : 'email'} expires only the page cache',
        () async {
      users.profile = () async => User(
            id: hasId ? 'account-b' : null,
            // A changed stable ID takes precedence even if email matches.
            email: hasId ? cached.email : 'other@example.test',
            name: 'Other account name',
          );
      final value = createModel();

      await value.fetchUser();

      expect(value.user, isNull);
      expect(value.isSignedIn, isFalse);
      expect(value.isSessionExpired, isTrue);
      expect(value.profileRefreshError, expiredError);
      expect(value.isRefreshingProfile, isFalse);
      expect(cached.name, 'Cached name');
      expect(auth.logoutCalls, 0);
      expect(users.deleteCalls, 0);
    });
  }

  test('a profile without an ID can match the cached normalized email',
      () async {
    final fresh = User(email: ' PERSON@EXAMPLE.TEST ', name: 'Fresh name');
    users.profile = () async => fresh;
    final value = createModel();

    await value.fetchUser();

    expect(value.user, same(fresh));
    expect(value.isSignedIn, isTrue);
    expect(value.isSessionExpired, isFalse);
    expect(value.profileRefreshError, isNull);
  });

  for (final unauthorized in [false, true]) {
    test(
        'account switch ignores old profile ${unauthorized ? '401' : 'success'} and clears only page cache',
        () async {
      var currentSession = true;
      final response = Completer<User>();
      users.profile = () => response.future;
      final value = createModel(isCurrentSession: () => currentSession);
      final pending = value.fetchUser();

      currentSession = false;
      if (unauthorized) {
        response.completeError(UnauthorizedException('Private server detail'));
      } else {
        response.complete(refreshed());
      }
      await pending;
      await value.fetchUser();

      expect(value.user, isNull);
      expect(value.isSignedIn, isFalse);
      expect(value.isRefreshingProfile, isFalse);
      expect(users.profileCalls, 1);
      expect(auth.logoutCalls, 0);
      expect(users.deleteCalls, 0);
    });
  }
}
