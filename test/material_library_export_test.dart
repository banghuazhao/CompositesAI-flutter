import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
// The plugin's platform interface lets tests inspect in-memory file bytes.
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart'
    show SharePlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_library_export.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_export_button.dart';
import 'package:swiftcomp/util/others.dart';

const _storageKey = 'Custom_Materials_v1';
const _buttonKey = Key('material-library-export-button');
const _failedMessage = 'Could not export saved materials. Please try again.';

LibraryMaterial _entry(String name,
        {MaterialKind kind = MaterialKind.lamina, double? e1}) =>
    LibraryMaterial(
      id: 'id-$name',
      name: name,
      kind: kind,
      isCustom: true,
      source: '  供應商 α / supplier\nRev "B"  ',
      e1: e1 ?? 150.12345678901235,
      e2: 10.987654321098765,
      g12: 5.123456789012345,
      nu12: 0.31234567890123456,
      alpha11: -1.2345678901234567e-6,
      alpha22: 2.3456789012345678e-5,
      xt: 1500.1234567890124,
      xc: 1300.9876543210987,
      yt: 45.123456789012344,
      yc: 250.12345678901235,
      s12: 68.98765432109876,
    );

Map<String, dynamic> _decode(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

List<dynamic> _records(String text) => _decode(text)['materials'] as List;

Future<String> _sharedText(WidgetTester tester, ShareParams params) async {
  // Web XFiles read their Blob through browser I/O outside the fake clock.
  final text = await tester.runAsync(
      () async => utf8.decode(await params.files!.single.readAsBytes()));
  return text!;
}

Widget _host({Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: locale == null
          ? null
          : const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
      supportedLocales:
          locale == null ? const [Locale('en')] : S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data:
            MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.5)),
        child: child!,
      ),
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: MaterialLibraryExportButton(),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final share = _ShareCapture();
  late SharePlatform previousShare;
  late SharedPreferences previousStorage;
  late _Preferences storage;

  void seed(List<LibraryMaterial> materials) {
    storage.values[_storageKey] =
        jsonEncode(materials.map((material) => material.toJson()).toList());
    MaterialLibrary.instance.resetForTest();
  }

  setUpAll(() {
    previousShare = SharePlatform.instance;
    SharePlatform.instance = share;
  });
  tearDownAll(() => SharePlatform.instance = previousShare);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    previousStorage = SharedPreferencesHelper.localStorage;
    storage = _Preferences();
    SharedPreferencesHelper.localStorage = storage;
    MaterialLibrary.instance.resetForTest();
    share.reset();
  });
  tearDown(() {
    SharedPreferencesHelper.localStorage = previousStorage;
    MaterialLibrary.instance.resetForTest();
  });

  test('versioned SI JSON round-trips every value without display rounding',
      () {
    final material = _entry('自訂碳纖維 / Carbon α');
    final text = MaterialLibraryExport.toJson([material]);
    final document = _decode(text);
    expect(document['schema'], 'compositesai.custom-materials');
    expect(document['version'], 1);
    expect(document['unitSystem'], 'SI');
    expect(document['units'], {
      'e1': 'GPa',
      'e2': 'GPa',
      'g12': 'GPa',
      'nu12': 'unitless',
      'nu23': 'unitless',
      'alpha11': '1/°C',
      'alpha22': '1/°C',
      'xt': 'MPa',
      'xc': 'MPa',
      'yt': 'MPa',
      'yc': 'MPa',
      's12': 'MPa',
    });
    final record = _records(text).single as Map<String, dynamic>;
    expect(record, material.toJson());
    expect(record.containsKey('nu23'), isTrue);
    expect(record['nu23'], isNull);
    expect(LibraryMaterial.fromJson(record)!.toJson(), material.toJson());
    expect(text, contains(material.e1.toString()));
    expect(text, contains(material.alpha11.toString()));
    expect(record['source'], material.source);
    expect(record['name'], material.name);
    expect(storage.writes, isEmpty);
  });

  test('snapshot source includes every custom kind and excludes built-ins', () {
    final custom = [
      _entry('Matrix', kind: MaterialKind.matrix),
      _entry('Lamina'),
      _entry('Fiber', kind: MaterialKind.fiber),
    ];
    seed(custom);
    expect(MaterialLibrary.instance.materials(MaterialKind.lamina).length,
        greaterThan(1));
    final text =
        MaterialLibraryExport.toJson(MaterialLibrary.instance.customMaterials);
    expect(
        _records(text), custom.map((material) => material.toJson()).toList());
    expect(_records(text).map((record) => (record as Map)['kind']),
        ['matrix', 'lamina', 'fiber']);
    expect(storage.writes, isEmpty);
  });

  test('JSON is independent of selected SI/US display units', () async {
    seed([_entry('Original SI data')]);
    final settings = UnitSettings();
    final si =
        MaterialLibraryExport.toJson(MaterialLibrary.instance.customMaterials);
    await settings.setSystem(UnitSystem.us);
    expect(settings.system, UnitSystem.us);
    final writesBefore = storage.writes.length;
    expect(
        MaterialLibraryExport.toJson(MaterialLibrary.instance.customMaterials),
        si);
    expect(storage.writes, hasLength(writesBefore));
    settings.dispose();
  });

  test('empty snapshot remains an explicit empty export', () {
    expect(_records(MaterialLibraryExport.toJson([])), isEmpty);
    expect(storage.writes, isEmpty);
  });

  test('nonfinite values reject the whole snapshot, including optional values',
      () {
    for (final invalid in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final property in [
        'e1',
        'e2',
        'g12',
        'nu12',
        'nu23',
        'alpha11',
        'alpha22',
        'xt',
        'xc',
        'yt',
        'yc',
        's12',
      ]) {
        final bad = _SerializedMaterial(
            {..._entry('Invalid').toJson(), property: invalid});
        expect(() => MaterialLibraryExport.toJson([_entry('Kept'), bad]),
            throwsFormatException,
            reason: '$property = $invalid');
      }
    }
    expect(storage.writes, isEmpty);
  });

  test('malformed direct records are rejected rather than silently omitted',
      () {
    for (final replacement in [
      {'name': '  '},
      {'name': null},
      {'id': 42},
      {'kind': 'unknown'},
      {'source': 42},
      {'e1': null},
      {'nu12': '0.3'},
      {'alpha22': '0.00002'},
    ]) {
      final bad =
          _SerializedMaterial({..._entry('Invalid').toJson(), ...replacement});
      expect(() => MaterialLibraryExport.toJson([_entry('Kept'), bad]),
          throwsFormatException);
    }
    expect(storage.writes, isEmpty);
  });

  testWidgets('empty button explains why export is disabled and tracks saves',
      (tester) async {
    await tester.pumpWidget(_host());
    expect(tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNull);
    expect(find.text('Save a custom material to enable JSON export.'),
        findsOneWidget);
    await tester.tap(find.byKey(_buttonKey));
    expect(share.calls, isEmpty);
    await MaterialLibrary.instance.save(_entry('Saved'));
    await tester.pump();
    expect(
        tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNotNull);
    expect(
        find.textContaining('including materials outside the current search'),
        findsOneWidget);
    await MaterialLibrary.instance
        .remove(MaterialLibrary.instance.customMaterials.single);
    await tester.pump();
    expect(tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNull);
  });

  testWidgets(
      'share carries exact JSON bytes, filename, MIME and button anchor',
      (tester) async {
    final custom = [_entry('供應商', kind: MaterialKind.matrix), _entry('Lamina')];
    seed(custom);
    final before = Map.of(storage.values);
    await tester.pumpWidget(_host());
    final button = find.byKey(_buttonKey);
    final origin = tester.getRect(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(share.calls, hasLength(1));
    final params = share.calls.single;
    expect(params.files, hasLength(1));
    expect(params.files!.single.mimeType, 'application/json');
    expect(params.fileNameOverrides, ['CompositesAI_materials.json']);
    expect(params.downloadFallbackEnabled, isTrue);
    expect(params.sharePositionOrigin, origin);
    expect(params.sharePositionOrigin!.size.isEmpty, isFalse);
    expect(await _sharedText(tester, params),
        MaterialLibraryExport.toJson(custom));
    expect(storage.values, before);
    expect(storage.writes, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('pending share captures the tap snapshot and blocks double taps',
      (tester) async {
    final first = _entry('At tap');
    seed([first]);
    share.pending = Completer<ShareResult>();
    await tester.pumpWidget(_host());
    final action = tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed!;
    action();
    action();
    await tester.pump();
    expect(share.calls, hasLength(1));
    expect(tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNull);
    await MaterialLibrary.instance.save(_entry('Saved later'));
    await MaterialLibrary.instance.remove(first);
    await tester.pump();
    expect(_records(await _sharedText(tester, share.calls.single)),
        [first.toJson()]);
    share.pending!.complete(const ShareResult('', ShareResultStatus.dismissed));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNotNull);
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(share.calls, hasLength(2));
    expect(
        (_records(await _sharedText(tester, share.calls.last)).single
            as Map)['name'],
        'Saved later');
  });

  testWidgets('an uncommitted save is excluded from the tap snapshot',
      (tester) async {
    final committed = _entry('Committed');
    seed([committed]);
    // Load the committed model before SharedPreferences starts its cache write.
    expect(MaterialLibrary.instance.customMaterials.single.name, 'Committed');
    storage.gate = Completer<void>();
    storage.writeStarted = Completer<void>();
    final save = MaterialLibrary.instance.save(_entry('Not committed yet'));
    await storage.writeStarted!.future;
    try {
      await tester.pumpWidget(_host());
      await tester.tap(find.byKey(_buttonKey));
      await tester.pumpAndSettle();
      expect(_records(await _sharedText(tester, share.calls.single)),
          [committed.toJson()]);
    } finally {
      storage.gate!.complete();
      await save;
    }
  });

  testWidgets('share failure leaves export available for a corrected retry',
      (tester) async {
    seed([_entry('Saved')]);
    share.fail = true;
    await tester.pumpWidget(_host());
    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(find.text(_failedMessage), findsOneWidget);
    expect(
        find.byKey(const Key('material-library-export-error')), findsOneWidget);
    expect(find.text(_failedMessage).hitTestable(), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
        tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNotNull);
    share.fail = false;
    share.pending = Completer<ShareResult>();
    await tester.tap(find.byKey(_buttonKey));
    await tester.pump();
    expect(find.text(_failedMessage), findsNothing);
    expect(
        find.byKey(const Key('material-library-export-error')), findsNothing);
    expect(tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNull);
    share.pending!.complete(const ShareResult('', ShareResultStatus.dismissed));
    await tester.pumpAndSettle();
    expect(share.calls, hasLength(2));
    expect(find.text(_failedMessage), findsNothing);
    expect(storage.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed committed input fails without sharing and can recover',
      (tester) async {
    final malformed = _entry('   ');
    await MaterialLibrary.instance.save(malformed);
    final before = Map.of(storage.values);
    final writesBefore = storage.writes.length;
    await tester.pumpWidget(_host());
    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(find.text(_failedMessage), findsOneWidget);
    expect(share.calls, isEmpty);
    expect(storage.values, before);
    expect(storage.writes, hasLength(writesBefore));
    expect(
        tester.widget<TextButton>(find.byKey(_buttonKey)).onPressed, isNotNull);

    await MaterialLibrary.instance.remove(malformed);
    await MaterialLibrary.instance.save(_entry('Corrected'));
    await tester.pump();
    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(share.calls, hasLength(1));
    expect(
        (_records(await _sharedText(tester, share.calls.single)).single
            as Map)['name'],
        'Corrected');
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets('share completion after disposal is safe (failure $fails)',
        (tester) async {
      seed([_entry('Saved')]);
      share.pending = Completer<ShareResult>();
      await tester.pumpWidget(_host());
      await tester.tap(find.byKey(_buttonKey));
      await tester.pump();
      expect(share.calls, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      if (fails) {
        share.pending!.completeError(StateError('Share unavailable'));
      } else {
        share.pending!
            .complete(const ShareResult('', ShareResultStatus.dismissed));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('export wraps at narrow width with large text in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      seed([_entry('Saved')]);
      await tester.pumpWidget(_host(locale: locale));
      await tester.pumpAndSettle();
      final button = find.byKey(_buttonKey);
      expect(tester.getRect(button).width, lessThanOrEqualTo(288));
      expect(tester.getRect(button).height, greaterThanOrEqualTo(48));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(share.calls, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }
}

class _SerializedMaterial extends LibraryMaterial {
  const _SerializedMaterial(this.record)
      : super(
            id: 'bad',
            name: 'Invalid',
            kind: MaterialKind.lamina,
            e1: 150,
            nu12: 0.3,
            isCustom: true);

  final Map<String, dynamic> record;

  @override
  Map<String, dynamic> toJson() => record;
}

class _ShareCapture extends SharePlatform {
  final calls = <ShareParams>[];
  Completer<ShareResult>? pending;
  bool fail = false;

  void reset() {
    calls.clear();
    pending = null;
    fail = false;
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    if (fail) throw StateError('Share unavailable');
    final completion = pending;
    if (completion != null) return completion.future;
    return const ShareResult('', ShareResultStatus.dismissed);
  }
}

class _Preferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  final writes = <String>[];
  Completer<void>? gate;
  Completer<void>? writeStarted;

  @override
  Object? get(String key) => values[key];

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    writes.add(key);
    final pending = gate;
    if (pending != null) {
      writeStarted!.complete();
      await pending.future;
    }
    return true;
  }
}
