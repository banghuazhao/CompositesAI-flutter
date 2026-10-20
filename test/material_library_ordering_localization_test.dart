import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_library_export.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_sheet.dart';
import 'package:swiftcomp/util/others.dart';

const _storageKey = 'Custom_Materials_v1';
const _searchKey = ValueKey('material-library-search');
const _orderKey = ValueKey('material-library-order');

LibraryMaterial _entry(String name, {String? id, double e1 = 150}) =>
    LibraryMaterial(
      id: id ?? 'id-$name',
      name: name,
      kind: MaterialKind.lamina,
      source: 'Original supplier source / Lab batch α',
      isCustom: true,
      e1: e1,
      nu12: 0.3,
    );

Finder get _sheet => find.byType(DraggableScrollableSheet);
Finder get _search => find.byKey(_searchKey);

S _strings(WidgetTester tester) =>
    S.of(tester.element(find.byType(MaterialLibraryButton)));

Finder _nameField(S strings) => find.byWidgetPredicate((widget) =>
    widget is TextField &&
    widget.decoration?.labelText == strings.Calculator_material_name);

MaterialLocalizations _materialStrings(WidgetTester tester) =>
    MaterialLocalizations.of(
        tester.element(find.byType(MaterialLibraryButton)));

Finder _sheetScroll() =>
    find.descendant(of: _sheet, matching: find.byType(Scrollable)).first;

Future<void> _show(WidgetTester tester, Finder finder,
    {bool towardStart = false}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, towardStart ? -250 : 250,
        scrollable: _sheetScroll());
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder,
    {bool towardStart = false}) async {
  await _show(tester, finder, towardStart: towardStart);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _sort(WidgetTester tester, String label) async {
  await _tap(tester, find.byKey(_orderKey), towardStart: true);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String query) async {
  await _show(tester, _search, towardStart: true);
  await tester.enterText(_search, query);
  await tester.pumpAndSettle();
}

// The ListView delegate contains the entire configured row order, including
// rows outside the current viewport. Interactions below still use actual taps.
List<String> _names(WidgetTester tester) {
  final list = tester.widget<ListView>(
      find.descendant(of: _sheet, matching: find.byType(ListView)));
  final children = (list.childrenDelegate as SliverChildListDelegate).children;
  return [
    for (final child in children)
      if (child is Card && child.child is ListTile)
        ((child.child! as ListTile).title! as Text).data!,
  ];
}

Future<void> _saveAs(WidgetTester tester, String name) async {
  final strings = _strings(tester);
  await _tap(tester, find.text(strings.Calculator_save_current_material),
      towardStart: true);
  await tester.enterText(_nameField(strings), name);
  await _tap(
      tester,
      find.widgetWithText(
          TextButton, _materialStrings(tester).saveButtonLabel));
}

Future<void> _clearFeedback(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(MaterialLibraryButton)))
      .clearSnackBars();
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester, {
  MaterialFromInputs? saveCurrent,
  ValueChanged<LibraryMaterial>? onSelected,
  Locale locale = const Locale('en'),
  Size size = const Size(1000, 1800),
  double scale = 1,
}) async {
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
        child: child!,
      ),
      home: Scaffold(
        body: MaterialLibraryButton(
          kind: MaterialKind.lamina,
          saveCurrent: saveCurrent,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await _tap(tester, find.text(_strings(tester).Calculator_library));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences previousStorage;
  late _Preferences storage;

  void seed(List<LibraryMaterial> materials) {
    storage.values[_storageKey] =
        jsonEncode(materials.map((material) => material.toJson()).toList());
    MaterialLibrary.instance.resetForTest();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    previousStorage = SharedPreferencesHelper.localStorage;
    storage = _Preferences();
    SharedPreferencesHelper.localStorage = storage;
    MaterialLibrary.instance.resetForTest();
  });
  tearDown(() {
    SharedPreferencesHelper.localStorage = previousStorage;
    MaterialLibrary.instance.resetForTest();
  });

  testWidgets(
      'A–Z sorts copies within sections and keeps normalized ties stable',
      (tester) async {
    // Legacy data can contain equal names; their original relative order is
    // preserved rather than depending on List.sort's unspecified stability.
    final custom = [
      _entry('Zulu'),
      _entry(' alpha ', id: 'first-alpha'),
      _entry('ALPHA', id: 'second-alpha'),
      _entry('Beta'),
    ];
    seed(custom);
    final before = Map.of(storage.values);
    final exportBefore =
        MaterialLibraryExport.toJson(MaterialLibrary.instance.customMaterials);
    final originalBuiltIn = builtInMaterials
        .where((material) => material.kind == MaterialKind.lamina)
        .map((material) => material.name)
        .toList();
    await _open(tester);
    final strings = _strings(tester);
    expect(_names(tester),
        [...custom.map((material) => material.name), ...originalBuiltIn]);
    await _sort(tester, strings.Calculator_material_alphabetical_order);
    expect(_names(tester), [
      ' alpha ',
      'ALPHA',
      'Beta',
      'Zulu',
      'AS4/3501-6 carbon/epoxy',
      'Boron/5505 epoxy',
      'E-glass/epoxy (Scotchply 1002)',
      'E-glass/LY556 epoxy',
      'IM7/8552 carbon/epoxy',
      'Kevlar 49/epoxy',
      'T300/5208 carbon/epoxy',
      'T300/BSL914C carbon/epoxy',
    ]);
    await _query(tester, '  LAB BATCH  ');
    expect(_names(tester), [' alpha ', 'ALPHA', 'Beta', 'Zulu']);
    await _query(tester, '');
    await _sort(tester, strings.Calculator_material_original_order);
    expect(_names(tester),
        [...custom.map((material) => material.name), ...originalBuiltIn]);
    expect(
        MaterialLibrary.instance.customMaterials.map((material) => material.id),
        custom.map((material) => material.id));
    expect(
        MaterialLibraryExport.toJson(MaterialLibrary.instance.customMaterials),
        exportBefore);
    expect(storage.values, before);
    expect(storage.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sorted search follows save/delete and selection without persisting order',
      (tester) async {
    final custom = [_entry('Zulu'), _entry('Alpha')];
    seed(custom);
    LibraryMaterial? selected;
    await _open(tester,
        saveCurrent: (name) => _entry(name),
        onSelected: (material) => selected = material);
    final strings = _strings(tester);
    await _sort(tester, strings.Calculator_material_alphabetical_order);
    await _query(tester, 'lab batch');
    await _saveAs(tester, 'Beta');
    expect(_names(tester), ['Alpha', 'Beta', 'Zulu']);
    expect(tester.widget<TextField>(_search).controller!.text, 'lab batch');
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Beta', 'Zulu', 'Alpha']);
    final delete = strings.Calculator_delete_material_tooltip('Alpha');
    await _tap(tester, find.byTooltip(delete));
    await _tap(
        tester,
        find.widgetWithText(
            TextButton, _materialStrings(tester).deleteButtonTooltip));
    expect(_names(tester), ['Beta', 'Zulu']);
    await _tap(tester, find.widgetWithText(ListTile, 'Zulu'));
    expect(selected?.id, custom.first.id);
    expect(_sheet, findsNothing);
    final writesBeforeReopen = storage.writes.length;
    await _tap(tester, find.text(strings.Calculator_library));
    expect(_names(tester).take(2), ['Beta', 'Zulu']);
    expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
    expect(
        find.text(strings.Calculator_material_original_order), findsOneWidget);
    expect(storage.writes, hasLength(writesBeforeReopen));
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale localizes library controls and narrow dialogs at 2x',
        (tester) async {
      final original = _entry('Original supplier name');
      seed([original]);
      await _open(tester,
          locale: locale,
          size: const Size(320, 740),
          scale: 2,
          saveCurrent: (name) => _entry(name));
      final strings = _strings(tester);
      expect(
          find.text(strings.Calculator_material_library_title(
              strings.Calculator_material_kind_lamina)),
          findsOneWidget);
      expect(
          find.text(strings.Calculator_material_library_help(Units.si.summary)),
          findsOneWidget);
      await _show(tester, _search);
      expect(tester.widget<TextField>(_search).decoration!.hintText,
          strings.Calculator_search_materials);
      await _sort(tester, strings.Calculator_material_alphabetical_order);
      await _query(tester, 'no-matching-material-xyz');
      await _show(tester, find.text(strings.Calculator_no_material_matches));
      expect(find.text(strings.Calculator_no_material_matches).hitTestable(),
          findsOneWidget);
      await _query(tester, 'lab batch');
      expect(_names(tester), [original.name]);
      await _tap(tester, find.text(strings.Calculator_save_current_material));
      expect(find.text(strings.Calculator_save_material_title), findsOneWidget);
      expect(_nameField(strings), findsOneWidget);
      await _tap(
          tester,
          find.widgetWithText(
              TextButton, _materialStrings(tester).cancelButtonLabel));
      await _tap(
          tester,
          find.byTooltip(
              strings.Calculator_delete_material_tooltip(original.name)));
      expect(
          find.text(strings.Calculator_delete_material_title), findsOneWidget);
      expect(
          find.text(strings.Calculator_delete_material_message(original.name)),
          findsOneWidget);
      await _tap(
          tester,
          find.widgetWithText(
              TextButton, _materialStrings(tester).cancelButtonLabel));
      expect(MaterialLibrary.instance.customMaterials.single.toJson(),
          original.toJson());
      expect(storage.writes, isEmpty);
      if (locale.languageCode != 'en') {
        expect(strings.Calculator_library, isNot('Library'));
        expect(strings.Calculator_search_materials, isNot('Search materials'));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$locale translates save, replacement, missing and failure feedback',
        (tester) async {
      final original = _entry('Existing', id: 'keep-this-id');
      seed([original]);
      await _open(tester, locale: locale, saveCurrent: (name) {
        if (name == 'Missing') return null;
        return _entry(name, e1: name == 'Invalid' ? double.infinity : 240);
      });
      final strings = _strings(tester);
      await _saveAs(tester, 'Existing');
      expect(
          find.text(strings.Calculator_replace_material_title), findsOneWidget);
      expect(find.text(strings.Calculator_replace_material_message('Existing')),
          findsOneWidget);
      await _tap(tester, find.text(strings.Calculator_choose_another_name));
      expect(tester.widget<TextField>(_nameField(strings)).controller!.text,
          'Existing');
      await _tap(
          tester,
          find.widgetWithText(
              TextButton, _materialStrings(tester).cancelButtonLabel));
      expect(MaterialLibrary.instance.customMaterials.single.e1, 150);
      await _saveAs(tester, 'Existing');
      await _tap(tester, find.text(strings.Calculator_replace_material));
      expect(MaterialLibrary.instance.customMaterials.single.id, original.id);
      expect(MaterialLibrary.instance.customMaterials.single.e1, 240);
      expect(find.text(strings.Calculator_material_saved('Existing')),
          findsOneWidget);
      await _clearFeedback(tester);
      await _saveAs(tester, 'Missing');
      expect(find.text(strings.Calculator_material_elastic_required),
          findsOneWidget);
      await _clearFeedback(tester);
      await _saveAs(tester, 'Invalid');
      expect(
          find.text(strings.Calculator_material_save_failed), findsOneWidget);
      expect(MaterialLibrary.instance.customMaterials, hasLength(1));
      await _clearFeedback(tester);
      await _saveAs(tester, 'New saved material');
      expect(find.text(strings.Calculator_material_saved('New saved material')),
          findsOneWidget);
      expect(MaterialLibrary.instance.customMaterials, hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$locale delete failure keeps data and permits translated retry',
        (tester) async {
      final original = _entry('Saved');
      seed([original]);
      final before = storage.values[_storageKey];
      await _open(tester, locale: locale);
      final strings = _strings(tester);
      final delete = find
          .byTooltip(strings.Calculator_delete_material_tooltip(original.name));
      await _tap(tester, delete);
      storage.failNext = true;
      await _tap(
          tester,
          find.widgetWithText(
              TextButton, _materialStrings(tester).deleteButtonTooltip));
      expect(
          find.text(strings.Calculator_material_delete_failed), findsOneWidget);
      expect(storage.values[_storageKey], before);
      expect(
          MaterialLibrary.instance.customMaterials.single.name, original.name);
      await _clearFeedback(tester);
      await _tap(tester, delete);
      await _tap(
          tester,
          find.widgetWithText(
              TextButton, _materialStrings(tester).deleteButtonTooltip));
      expect(MaterialLibrary.instance.customMaterials, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'dismissed name/delete/replacement callbacks cannot pop the sheet',
      (tester) async {
    seed([_entry('Existing')]);
    await _open(tester, saveCurrent: (name) => _entry(name, e1: 240));
    final strings = _strings(tester);
    final materialStrings = _materialStrings(tester);
    await _tap(tester, find.text(strings.Calculator_save_current_material));
    await tester.enterText(_nameField(strings), 'Should not be saved');
    final save = tester
        .widget<TextButton>(
            find.widgetWithText(TextButton, materialStrings.saveButtonLabel))
        .onPressed!;
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    save();
    expect(_sheet, findsOneWidget);
    await _tap(tester,
        find.byTooltip(strings.Calculator_delete_material_tooltip('Existing')));
    final remove = tester
        .widget<TextButton>(find.widgetWithText(
            TextButton, materialStrings.deleteButtonTooltip))
        .onPressed!;
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    remove();
    expect(_sheet, findsOneWidget);
    await _saveAs(tester, 'Existing');
    final replace = tester
        .widget<TextButton>(find.widgetWithText(
            TextButton, strings.Calculator_replace_material))
        .onPressed!;
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    replace();
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(MaterialLibrary.instance.customMaterials.single.e1, 150);
    expect(storage.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _Preferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  final writes = <String>[];
  bool failNext = false;

  @override
  Object? get(String key) => values[key];

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    writes.add(key);
    if (failNext) {
      failNext = false;
      throw StateError('Write unavailable');
    }
    return true;
  }
}
