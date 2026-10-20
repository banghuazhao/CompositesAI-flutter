import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart'
    show SharePlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_sheet.dart';
import 'package:swiftcomp/util/others.dart';

const _material = LibraryMaterial(
  id: 'details-prepreg',
  name: 'Preview prepreg',
  kind: MaterialKind.lamina,
  isCustom: true,
  source: 'Supplier source',
  e1: 150.12345678901235,
  nu12: 0.3,
);

Future<void> _open(WidgetTester tester,
    {ValueChanged<LibraryMaterial>? onSelected,
    Locale locale = const Locale('en'),
    double scale = 1,
    Size size = const Size(800, 1100)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => UnitSettings(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Library host')),
                        body: Center(
                          child: MaterialLibraryButton(
                            kind: MaterialKind.lamina,
                            onSelected: onSelected ?? (_) {},
                          ),
                        ),
                      ))),
              child: const Text('Open host'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open host'));
  await tester.pumpAndSettle();
  final strings = S.of(tester.element(find.byType(MaterialLibraryButton)));
  await tester.tap(find.text(strings.Calculator_library));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find
            .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable))
            .first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final share = _ShareCapture();
  late SharePlatform previousShare;

  setUpAll(() {
    previousShare = SharePlatform.instance;
    SharePlatform.instance = share;
  });
  tearDownAll(() => SharePlatform.instance = previousShare);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
    share.calls.clear();
    share.fail = false;
    await MaterialLibrary.instance.save(_material);
  });
  tearDown(MaterialLibrary.instance.resetForTest);

  testWidgets('details cancel preserves inputs and Apply selects only once',
      (tester) async {
    final target = TransverselyIsotropicMaterial()
      ..e1 = 72
      ..e2 = 6
      ..g12 = 4
      ..nu12 = 0.25;
    final selected = <LibraryMaterial>[];
    await _open(tester, onSelected: (material) {
      selected.add(material);
      material.applyToLamina(target, Units.si);
    });
    final stored =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    final details =
        find.byKey(const ValueKey('material-details-details-prepreg'));
    await _tap(tester, details);
    expect(find.byKey(const Key('material-details-dialog')), findsOneWidget);
    expect(target.e1, 72);
    expect(selected, isEmpty);
    await _tap(tester, find.byKey(const Key('material-details-cancel')));
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(target.e1, 72);
    expect(selected, isEmpty);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
    await _tap(tester, details);
    final apply = tester
        .widget<ButtonStyleButton>(
            find.byKey(const Key('material-details-apply')))
        .onPressed!;
    apply();
    apply();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('material-details-dialog')), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.text('Library host'), findsOneWidget);
    expect(selected, [_material]);
    expect(target.e1, _material.e1);
    expect(target.e2, 6,
        reason: 'Preview does not change missing-value policy.');
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'direct selection remains available and duplicate taps stay local',
      (tester) async {
    final selected = <LibraryMaterial>[];
    await _open(tester, onSelected: selected.add);
    final tile = find.widgetWithText(ListTile, _material.name);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    final select = tester.widget<ListTile>(tile).onTap!;
    select();
    select();
    await tester.pumpAndSettle();
    expect(selected, [_material]);
    expect(find.text('Library host'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byKey(const Key('material-details-dialog')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale tile actions cannot replace an open details route',
      (tester) async {
    final selected = <LibraryMaterial>[];
    await _open(tester, onSelected: selected.add);
    final tile = find.widgetWithText(ListTile, _material.name);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    final select = tester.widget<ListTile>(tile).onTap!;
    final details =
        find.byKey(const ValueKey('material-details-details-prepreg'));
    final preview = tester.widget<IconButton>(details).onPressed!;
    await _tap(tester, details);
    select();
    preview();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('material-details-dialog')), findsOneWidget);
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.byKey(const Key('material-details-cancel')));
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Library host'), findsOneWidget);
  });

  testWidgets('stale tile actions during sheet dismissal leave the host intact',
      (tester) async {
    final selected = <LibraryMaterial>[];
    await _open(tester, onSelected: selected.add);
    final tile = find.widgetWithText(ListTile, _material.name);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    final select = tester.widget<ListTile>(tile).onTap!;
    final preview = tester
        .widget<IconButton>(
            find.byKey(const ValueKey('material-details-details-prepreg')))
        .onPressed!;
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    select();
    preview();
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byKey(const Key('material-details-dialog')), findsNothing);
    expect(find.text('Library host'), findsOneWidget);
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export from a searched lamina library includes every saved kind',
      (tester) async {
    const matrix = LibraryMaterial(
      id: 'matrix-export',
      name: 'Other saved matrix',
      kind: MaterialKind.matrix,
      isCustom: true,
      e1: 3.5,
      nu12: 0.35,
    );
    await MaterialLibrary.instance.save(matrix);
    final before =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    await _open(tester);
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search materials'),
        'Preview');
    await tester.pumpAndSettle();
    expect(find.text(matrix.name), findsNothing);
    expect(find.text('T300/5208 carbon/epoxy'), findsNothing);
    await _tap(tester, find.byKey(const Key('material-library-export-button')));
    expect(share.calls, hasLength(1));
    // Browser Blob reads need real async I/O rather than the widget fake clock.
    final exported = await tester.runAsync(() async =>
        utf8.decode(await share.calls.single.files!.single.readAsBytes()));
    final data = jsonDecode(exported!) as Map;
    final records = data['materials'] as List;
    expect(records.map((record) => (record as Map)['id']),
        [matrix.id, _material.id]);
    expect((records.last as Map)['e1'], _material.e1);
    expect(data['unitSystem'], 'SI');
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        before);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('sheet details/actions fit narrow large text in $locale',
        (tester) async {
      await _open(tester, locale: locale, scale: 2, size: const Size(360, 740));
      await _tap(tester,
          find.byKey(const ValueKey('material-details-details-prepreg')));
      await _tap(tester, find.byKey(const Key('material-details-cancel')));
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('export failure is visible above the sheet and can be retried',
      (tester) async {
    final stored =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    share.fail = true;
    await _open(tester);
    final export = find.byKey(const Key('material-library-export-button'));
    await _tap(tester, export);
    final error =
        find.text('Could not export saved materials. Please try again.');
    expect(error, findsOneWidget);
    await tester.ensureVisible(error);
    await tester.pumpAndSettle();
    expect(error.hitTestable(), findsOneWidget,
        reason: 'Export errors must be visible inside the modal sheet.');
    share.fail = false;
    await _tap(tester, export);
    expect(share.calls, hasLength(2));
    expect(error, findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
    expect(tester.takeException(), isNull);
  });
}

class _ShareCapture extends SharePlatform {
  final calls = <ShareParams>[];
  bool fail = false;

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    if (fail) throw StateError('Share unavailable');
    return const ShareResult('', ShareResultStatus.dismissed);
  }
}
