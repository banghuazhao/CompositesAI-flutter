import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/in_app_reviewer_helper.dart';
// Plugin interfaces exercise review failures and actual preference persistence.
// ignore: depend_on_referenced_packages
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _countKey = 'flutter.openCount';

class _Reviews extends InAppReviewPlatform {
  int availabilityChecks = 0;
  int requests = 0;
  bool available = true;
  bool failAvailability = false;
  bool failRequest = false;
  Completer<void>? pending;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    if (failAvailability) throw MissingPluginException('unavailable');
    return available;
  }

  @override
  Future<void> requestReview() async {
    requests++;
    if (failRequest) throw PlatformException(code: 'no-view-controller');
    await pending?.future;
  }
}

class _Preferences extends InMemorySharedPreferencesStore {
  _Preferences([Object? count])
      : super.withData({if (count != null) _countKey: count});

  final writes = <(String, Object)>[];
  bool failRead = false;
  bool failWrite = false;
  bool writeSucceeds = true;
  Completer<bool>? pendingWrite;

  @override
  Future<Map<String, Object>> getAll() async {
    if (failRead) throw PlatformException(code: 'preferences-unavailable');
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add((key, value));
    if (failWrite) throw PlatformException(code: 'preferences-write-failed');
    final success =
        pendingWrite == null ? writeSucceeds : await pendingWrite!.future;
    if (!success) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InAppReviewPlatform previousReviews;
  late SharedPreferencesStorePlatform previousPreferences;
  late String previousKey;
  late _Reviews reviews;
  late _Preferences preferences;

  void seed([Object? count]) {
    SharedPreferences.setMockInitialValues({});
    preferences = _Preferences(count);
    SharedPreferencesStorePlatform.instance = preferences;
  }

  setUp(() {
    previousReviews = InAppReviewPlatform.instance;
    previousPreferences = SharedPreferencesStorePlatform.instance;
    previousKey = InAppReviewHelper.openCount;
    InAppReviewHelper.openCount = 'openCount';
    reviews = _Reviews();
    InAppReviewPlatform.instance = reviews;
    seed();
  });
  tearDown(() {
    InAppReviewPlatform.instance = previousReviews;
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = previousPreferences;
    InAppReviewHelper.openCount = previousKey;
  });

  for (final count in [3, 15, 100]) {
    test('launch $count persists its count and requests an available review',
        () async {
      seed(count - 1);
      await InAppReviewHelper.checkAndAskForReview();
      expect(preferences.writes, [(_countKey, count)]);
      expect((await preferences.getAll())[_countKey], count);
      expect(reviews.availabilityChecks, 1);
      expect(reviews.requests, 1);
    });
  }

  test('first launch and launches outside the thresholds do not ask for review',
      () async {
    for (final count in <int?>[null, 1, 3, 13, 15, 98, 100]) {
      seed(count);
      await InAppReviewHelper.checkAndAskForReview();
      expect((await preferences.getAll())[_countKey], (count ?? 0) + 1);
    }
    expect(reviews.availabilityChecks, 0);
    expect(reviews.requests, 0);
  });

  test('unavailable review support preserves the count without a request',
      () async {
    seed(2);
    reviews.available = false;
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect((await preferences.getAll())[_countKey], 3);
    expect(reviews.availabilityChecks, 1);
    expect(reviews.requests, 0);
  });

  test('availability failure is best effort and never escapes startup',
      () async {
    seed(2);
    reviews.failAvailability = true;
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect((await preferences.getAll())[_countKey], 3);
    expect(reviews.requests, 0);
  });

  test(
      'native request failure is best effort and a later threshold still works',
      () async {
    seed(2);
    reviews.failRequest = true;
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect(reviews.requests, 1);
    expect((await preferences.getAll())[_countKey], 3);
    seed(14);
    reviews.failRequest = false;
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect(reviews.requests, 2);
    expect((await preferences.getAll())[_countKey], 15);
  });

  testWidgets('late no-window failure is awaited and cannot become unhandled',
      (tester) async {
    seed(2);
    reviews.pending = Completer<void>();
    var completed = false;
    final check =
        InAppReviewHelper.checkAndAskForReview().then((_) => completed = true);
    await tester.pump();
    expect(reviews.requests, 1);
    expect(completed, isFalse);
    reviews.pending!
        .completeError(PlatformException(code: 'no-view-controller'));
    await check;
    await tester.pump();
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('preferences loading failure does not escape or request a review',
      () async {
    preferences.failRead = true;
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect(preferences.writes, isEmpty);
    expect(reviews.availabilityChecks, 0);
  });

  test('wrong-type stored count does not escape or overwrite existing data',
      () async {
    seed('invalid count');
    await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
    expect((await preferences.getAll())[_countKey], 'invalid count');
    expect(preferences.writes, isEmpty);
    expect(reviews.availabilityChecks, 0);
  });

  for (final throwing in [false, true]) {
    test('failed count persistence is best effort, throwing=$throwing',
        () async {
      seed(2);
      preferences.failWrite = throwing;
      preferences.writeSucceeds = false;
      await expectLater(InAppReviewHelper.checkAndAskForReview(), completes);
      expect((await preferences.getAll())[_countKey], 2);
      expect(reviews.availabilityChecks, 0);
      expect(reviews.requests, 0);
    });
  }

  testWidgets('review eligibility waits for the count write to finish',
      (tester) async {
    seed(2);
    preferences.pendingWrite = Completer<bool>();
    final check = InAppReviewHelper.checkAndAskForReview();
    await tester.pump();
    expect(preferences.writes, [(_countKey, 3)]);
    expect(reviews.availabilityChecks, 0);
    preferences.pendingWrite!.complete(true);
    await check;
    expect((await preferences.getAll())[_countKey], 3);
    expect(reviews.requests, 1);
  });
}
