import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';

class _Auth extends Fake implements AuthUseCase {
  @override
  Future<bool> isLoggedIn() async => false;
}

class _Users extends Fake implements UserUseCase {
  final updatedNames = <String>[];
  Future<void> Function()? save;
  Future<User> Function()? profile;

  @override
  Future<void> updateMe(String name) async {
    updatedNames.add(name);
    await save?.call();
  }

  @override
  Future<User> fetchMe() => profile!();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Users users;
  late FeatureFlagProvider flags;
  SettingsViewModel? model;
  var disposed = false;

  User account(String suffix, {String name = 'Current name'}) => User(
        id: 'account-$suffix',
        email: '$suffix@example.test',
        name: name,
      );

  Future<SettingsViewModel> createModel({bool signedIn = true}) async {
    final value = SettingsViewModel(
      authUseCase: _Auth(),
      userUserCase: users,
      featureFlagProvider: flags,
    );
    model = value;
    // Finish constructor-triggered signed-out lookup before injecting a user.
    await value.fetchAuthSessionNew();
    if (signedIn) value.updateUser(account('a'));
    return value;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Test App',
      packageName: 'example.test',
      version: '1.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
    users = _Users();
    flags = FeatureFlagProvider();
    model = null;
    disposed = false;
  });

  tearDown(() {
    if (!disposed) model?.dispose();
    flags.dispose();
  });

  test('blank names never reach the update use case', () async {
    final value = await createModel();

    expect(await value.updateUserName(' \n\t '), isFalse);
    expect(users.updatedNames, isEmpty);
    expect(value.user!.name, 'Current name');
  });

  test('missing or signed-out users cannot update a name', () async {
    final value = await createModel(signedIn: false);
    expect(await value.updateUserName('Updated name'), isFalse);

    value.isLoggedIn = true;
    expect(await value.updateUserName('Updated name'), isFalse);

    value.user = account('a');
    value.isLoggedIn = false;
    expect(await value.updateUserName('Updated name'), isFalse);
    expect(users.updatedNames, isEmpty);
  });

  test(
      'name changes only after confirmation and is trimmed once for the request',
      () async {
    final value = await createModel();
    final response = Completer<void>();
    users.save = () => response.future;
    final generation = value.sessionGeneration;
    final saving = value.updateUserName(
      '  Updated name  ',
      expectedSessionGeneration: generation,
    );

    expect(users.updatedNames, ['Updated name']);
    expect(value.user!.name, 'Current name');
    response.complete();
    expect(await saving, isTrue);
    expect(value.user!.name, 'Updated name');
    expect(value.sessionGeneration, generation);
    expect(value.isLoggedIn, isTrue);
  });

  test('failed update retains the current name and can be retried', () async {
    final value = await createModel();
    users.save = () async => throw StateError('Private update diagnostic');

    expect(await value.updateUserName('Updated name'), isFalse);
    expect(value.user!.name, 'Current name');
    expect(value.isLoggedIn, isTrue);

    users.save = () async {};
    expect(await value.updateUserName('Updated name'), isTrue);
    expect(value.user!.name, 'Updated name');
    expect(users.updatedNames, ['Updated name', 'Updated name']);
  });

  test('a form from a previous generation cannot rename the current account',
      () async {
    final value = await createModel();
    final openingGeneration = value.sessionGeneration;
    final next = account('b', name: 'Other account name');
    value.updateUser(next);

    expect(
      await value.updateUserName(
        'Old account draft',
        expectedSessionGeneration: openingGeneration,
      ),
      isFalse,
    );
    expect(users.updatedNames, isEmpty);
    expect(value.user, same(next));
    expect(next.name, 'Other account name');
  });

  test('a pending name update cannot change a later account', () async {
    final value = await createModel();
    final original = value.user!;
    final response = Completer<void>();
    users.save = () => response.future;
    final saving = value.updateUserName('Old account draft');
    final next = account('b', name: 'Other account name');
    value.updateUser(next);

    response.complete();

    expect(await saving, isFalse);
    expect(value.user, same(next));
    expect(next.name, 'Other account name');
    expect(original.name, 'Current name');
  });

  test('a pending name update cannot restore a logged-out account', () async {
    final value = await createModel();
    final response = Completer<void>();
    users.save = () => response.future;
    final saving = value.updateUserName('Updated name');
    value.clearSession();

    response.complete();

    expect(await saving, isFalse);
    expect(value.user, isNull);
    expect(value.isLoggedIn, isFalse);
  });

  test('disposing during save prevents user mutation or notification',
      () async {
    final value = await createModel();
    final original = value.user!;
    final response = Completer<void>();
    users.save = () => response.future;
    final saving = value.updateUserName('Updated name');
    var notifications = 0;
    value.addListener(() => notifications++);
    value.dispose();
    disposed = true;

    response.complete();

    expect(await saving, isFalse);
    expect(original.name, 'Current name');
    expect(notifications, 0);
    expect(await value.updateUserName('Another name'), isFalse);
    expect(users.updatedNames, ['Updated name']);
  });

  for (final unauthorized in [false, true]) {
    test(
        'profile ${unauthorized ? 'unauthorized' : 'success'} from before confirmed save cannot overwrite it',
        () async {
      final value = await createModel();
      final response = Completer<User>();
      users.profile = () => response.future;
      final fetching = value.fetchUser();
      final generation = value.sessionGeneration;

      expect(await value.updateUserName('Updated name'), isTrue);
      if (unauthorized) {
        response.completeError(UnauthorizedException());
      } else {
        response.complete(account('a', name: 'Stale name'));
      }
      await fetching;

      expect(value.user!.name, 'Updated name');
      expect(value.isLoggedIn, isTrue);
      expect(value.sessionGeneration, generation);
    });
  }
}
