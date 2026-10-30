import 'dart:async';

import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// Plugin interfaces exercise the real dispatch paths without native dialogs.
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart'
    show SharePlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/settings_page.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/util/others.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const _macStore = 'https://apps.apple.com/app/id1487971887';
const _storeError = 'Could not open the App Store. Please try again.';
const _shareError = 'Could not share the app. Please try again.';

class _Launcher extends UrlLauncherPlatform {
  final calls = <(String, LaunchOptions)>[];
  bool result = true;
  bool fail = false;
  Completer<bool>? pending;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url, options));
    if (fail) throw PlatformException(code: 'launch-unavailable');
    if (pending != null) return pending!.future;
    return result;
  }
}

class _Share extends SharePlatform {
  final calls = <ShareParams>[];
  bool fail = false;
  Completer<ShareResult>? pending;

  void reset() {
    calls.clear();
    fail = false;
    pending = null;
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    if (fail) throw PlatformException(code: 'share-unavailable');
    if (pending != null) return pending!.future;
    return const ShareResult('', ShareResultStatus.dismissed);
  }
}

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (value) {
      context = value;
      return const Scaffold(body: Text('Share source'));
    }),
  ));
  return context;
}

Future<void> _settings(WidgetTester tester, SettingsViewModel model) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsViewModel>.value(value: model),
      ChangeNotifierProvider(create: (_) => UnitSettings()),
    ],
    child: const MaterialApp(home: SettingsPage()),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tapSupport(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(target, 250,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final share = _Share();
  late SharePlatform previousShare;
  late UrlLauncherPlatform previousLauncher;
  late _Launcher launcher;
  late FeatureFlagProvider flags;
  late SettingsViewModel model;

  setUpAll(() {
    previousShare = SharePlatform.instance;
    SharePlatform.instance = share;
  });
  tearDownAll(() => SharePlatform.instance = previousShare);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    PackageInfo.setMockInitialValues(
      appName: 'CompositesAI',
      packageName: 'example.mac',
      version: '7.13.0',
      buildNumber: '2026100105',
      buildSignature: '',
    );
    previousLauncher = UrlLauncherPlatform.instance;
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    share.reset();
    flags = FeatureFlagProvider();
    await flags.loadFeatureFlags();
    model = SettingsViewModel(
      authUseCase: MockAuthUseCase(),
      userUserCase: MockUserUseCase(),
      featureFlagProvider: flags,
    );
    await model.fetchAuthSessionNew();
  });
  tearDown(() {
    model.dispose();
    flags.dispose();
    UrlLauncherPlatform.instance = previousLauncher;
  });

  for (final (platform, url) in [
    (TargetPlatform.macOS, _macStore),
    (TargetPlatform.iOS, 'https://apps.apple.com/app/id1297825946'),
    (
      TargetPlatform.android,
      'https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp'
    ),
  ]) {
    testWidgets('$platform Rate opens its own external store listing',
        (tester) async {
      expect(await model.rateApp(), isTrue);
      expect(launcher.calls.single.$1, url);
      expect(launcher.calls.single.$2.mode,
          PreferredLaunchMode.externalApplication);
    }, variant: TargetPlatformVariant.only(platform), skip: kIsWeb);
  }

  testWidgets('Mac Rate handles a false launch, thrown failure, then retry',
      (tester) async {
    launcher.result = false;
    expect(await model.rateApp(), isFalse);
    launcher.fail = true;
    expect(await model.rateApp(), isFalse);
    launcher.fail = false;
    launcher.result = true;
    expect(await model.rateApp(), isTrue);
    expect(launcher.calls.map((call) => call.$1),
        [_macStore, _macStore, _macStore]);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  for (final (platform, url) in [
    (TargetPlatform.macOS, _macStore),
    (TargetPlatform.iOS, 'http://itunes.apple.com/app/id1297825946'),
    (
      TargetPlatform.android,
      'https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp'
    ),
  ]) {
    testWidgets('$platform Share dispatches its link without claiming a save',
        (tester) async {
      final context = await _context(tester);
      expect(await model.shareApp(context), isTrue);
      final params = share.calls.single;
      expect(params.text, url);
      expect(params.subject, 'CompositesAI');
      expect(params.files, isNull);
      if (platform == TargetPlatform.android) {
        expect(params.sharePositionOrigin, isNull);
      } else {
        expect(params.sharePositionOrigin!.width, greaterThan(0));
        expect(params.sharePositionOrigin!.height, greaterThan(0));
      }
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform), skip: kIsWeb);
  }

  testWidgets('Mac Share handles missing plugin and permits another attempt',
      (tester) async {
    final context = await _context(tester);
    share.fail = true;
    expect(await model.shareApp(context), isFalse);
    share.fail = false;
    expect(await model.shareApp(context), isTrue);
    expect(share.calls, hasLength(2));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('detached Share source does not launch a native sheet',
      (tester) async {
    final context = await _context(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(await model.shareApp(context), isFalse);
    expect(share.calls, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('website sharing fallback reports clipboard failure and retries',
      (tester) async {
    final context = await _context(tester);
    final copied = <String>[];
    var fail = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        if (fail) throw PlatformException(code: 'clipboard-unavailable');
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    try {
      expect(await model.shareApp(context), isFalse);
      fail = false;
      expect(await model.shareApp(context), isTrue);
      expect(copied, ['https://compositesai.com']);
      expect(share.calls, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('Mac Settings exposes launch failure and keeps Rate retryable',
      (tester) async {
    launcher.result = false;
    await _settings(tester, model);
    await _tapSupport(tester, 'Rate this App');
    await tester.pumpAndSettle();
    expect(find.text(_storeError), findsOneWidget);
    launcher.result = true;
    await _tapSupport(tester, 'Rate this App');
    expect(launcher.calls, hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets(
      'Mac Settings guards duplicate Share and shows only actual failure',
      (tester) async {
    share.pending = Completer<ShareResult>();
    await _settings(tester, model);
    await _tapSupport(tester, 'Share this App');
    await tester.tap(find.text('Share this App'));
    await tester.pump();
    expect(share.calls, hasLength(1));
    share.pending!.completeError(MissingPluginException('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text(_shareError), findsOneWidget);
    share.pending = null;
    await _tapSupport(tester, 'Share this App');
    await tester.pumpAndSettle();
    expect(share.calls, hasLength(2));
    expect(find.textContaining('copied to Clipboard'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  testWidgets('late Rate failure after Settings closes has no stale feedback',
      (tester) async {
    launcher.pending = Completer<bool>();
    await _settings(tester, model);
    await _tapSupport(tester, 'Rate this App');
    expect(launcher.calls, hasLength(1));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: Text('Elsewhere'))));
    launcher.pending!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Elsewhere'), findsOneWidget);
    expect(find.text(_storeError), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);
}
