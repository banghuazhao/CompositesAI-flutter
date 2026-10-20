import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_sheet.dart';
import 'package:swiftcomp/util/others.dart';

const _storageKey = 'Custom_Materials_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  test('duplicate names require exact approval, preserving ID and order',
      () async {
    final first = _entry('  Saved laminate  ', id: 'first');
    final other = _entry('Another laminate', id: 'other');
    await MaterialLibrary.instance.save(first);
    await MaterialLibrary.instance.save(other);
    final before = SharedPreferencesHelper.localStorage.getString(_storageKey);
    final replacement = _entry('sAvEd LaMiNaTe', id: 'incoming', e1: 240);
    await expectLater(
        MaterialLibrary.instance.save(replacement),
        throwsA(isA<MaterialNameConflict>()
            .having((error) => error.existing, 'existing', same(first))));
    expect(SharedPreferencesHelper.localStorage.getString(_storageKey), before);
    expect(MaterialLibrary.instance.customMaterials, [other, first]);

    await MaterialLibrary.instance.save(replacement, replaceExisting: first);
    final saved = MaterialLibrary.instance.customMaterials;
    expect(saved.map((material) => material.id), ['other', 'first']);
    expect(saved.last.e1, 240);
    await expectLater(
      MaterialLibrary.instance
          .save(_entry('Saved laminate', e1: 300), replaceExisting: first),
      throwsA(isA<MaterialNameConflict>()),
    );
    expect(MaterialLibrary.instance.customMaterials.last.e1, 240);
  });

  test('built-in names and names of another kind do not conflict', () async {
    final builtIn = builtInMaterials.first;
    await MaterialLibrary.instance.save(_entry(builtIn.name));
    await MaterialLibrary.instance.save(
        _entry('  ${builtIn.name.toUpperCase()}  ', kind: MaterialKind.matrix));
    expect(MaterialLibrary.instance.customMaterials, hasLength(2));
  });

  test('concurrent new saves recheck the name at commit', () async {
    final one = MaterialLibrary.instance.save(_entry('Concurrent', id: 'one'));
    final two =
        MaterialLibrary.instance.save(_entry(' concurrent ', id: 'two'));
    final conflict = expectLater(two, throwsA(isA<MaterialNameConflict>()));
    await one;
    await conflict;
    expect(MaterialLibrary.instance.customMaterials.single.id, 'one');
  });

  for (final returnsFalse in [false, true]) {
    test(
        'failed persistence keeps records and cached preferences ($returnsFalse)',
        () async {
      final storage = _useControlledStorage();
      final original = _entry('Saved laminate', id: 'kept');
      await MaterialLibrary.instance.save(original);
      final before = storage.getString(_storageKey);
      var notifications = 0;
      void listener() => notifications++;
      MaterialLibrary.instance.addListener(listener);
      addTearDown(() => MaterialLibrary.instance.removeListener(listener));
      storage.failNext = true;
      storage.returnFalse = returnsFalse;
      await expectLater(
        MaterialLibrary.instance
            .save(_entry('Saved laminate', e1: 240), replaceExisting: original),
        throwsA(anything),
      );
      expect(MaterialLibrary.instance.customMaterials.single, same(original));
      expect(storage.getString(_storageKey), before);
      expect(notifications, 0);
      await MaterialLibrary.instance
          .save(_entry('Saved laminate', e1: 240), replaceExisting: original);
      expect(MaterialLibrary.instance.customMaterials.single.e1, 240);
      expect(notifications, 1);
    });
  }

  test('save and delete commits cannot lose one another', () async {
    final storage = _useControlledStorage();
    final existing = _entry('Existing', id: 'existing');
    await MaterialLibrary.instance.save(existing);
    final gate = Completer<void>();
    storage.nextWriteGate = gate;
    storage.writeStarted = Completer<void>();
    final save = MaterialLibrary.instance.save(_entry('New', id: 'new'));
    Future<void>? remove;
    try {
      await storage.writeStarted!.future;
      remove = MaterialLibrary.instance.remove(existing);
      expect(MaterialLibrary.instance.customMaterials, [existing]);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await save;
      if (remove != null) await remove;
    }
    expect(MaterialLibrary.instance.customMaterials.single.id, 'new');
  });

  test('a valid save recovers a corrupt preference type', () async {
    await SharedPreferencesHelper.localStorage.setInt(_storageKey, 42);
    await MaterialLibrary.instance.save(_entry('Recovered'));
    expect(MaterialLibrary.instance.customMaterials.single.name, 'Recovered');
    expect(SharedPreferencesHelper.localStorage.getString(_storageKey),
        contains('Recovered'));
  });

  for (final previous in <Object>[
    true,
    42,
    3.5,
    <String>['legacy']
  ]) {
    test(
        'failed write restores corrupt preference type ${previous.runtimeType}',
        () async {
      final storage = _useControlledStorage();
      storage.values[_storageKey] = previous;
      storage.failNext = true;
      await expectLater(
          MaterialLibrary.instance.save(_entry('Rejected')), throwsA(anything));
      expect(MaterialLibrary.instance.customMaterials, isEmpty);
      expect(storage.get(_storageKey), previous);
      await MaterialLibrary.instance.save(_entry('Recovered'));
      expect(MaterialLibrary.instance.customMaterials.single.name, 'Recovered');
    });
  }

  testWidgets('cancel retains saved values and unlocks the save action',
      (tester) async {
    final original = _entry('Saved laminate', id: 'kept');
    await MaterialLibrary.instance.save(original);
    await _open(tester);
    await _saveName(tester, ' saved LAMINATE ');
    expect(find.text(_strings(tester).Calculator_replace_material_title),
        findsOneWidget);
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    await _tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    expect(tester.widget<TextButton>(_saveAction).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'another name preserves entered text and creates a separate record',
      (tester) async {
    final original = _entry('Saved laminate', id: 'kept');
    await MaterialLibrary.instance.save(original);
    await _open(tester);
    const entered = '  saved LAMINATE  ';
    await _saveName(tester, entered);
    await _tap(
        tester, find.text(_strings(tester).Calculator_choose_another_name));
    expect(tester.widget<TextField>(_nameField).controller!.text, entered);
    await tester.enterText(_nameField, 'New laminate');
    await _tap(tester, find.widgetWithText(TextButton, 'Save'));
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['New laminate', 'Saved laminate']);
    expect(MaterialLibrary.instance.customMaterials.last, same(original));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'replace rechecks changed saved values and requests fresh approval',
      (tester) async {
    final original = _entry('Saved laminate', id: 'kept');
    await MaterialLibrary.instance.save(original);
    await _open(tester);
    await _saveName(tester, 'Saved laminate');
    await MaterialLibrary.instance
        .save(_entry('Saved laminate', e1: 190), replaceExisting: original);
    await _tap(tester, find.text(_strings(tester).Calculator_replace_material));
    expect(find.text(_strings(tester).Calculator_replace_material_title),
        findsOneWidget);
    expect(MaterialLibrary.instance.customMaterials.single.e1, 190);
    await _tap(tester, find.text(_strings(tester).Calculator_replace_material));
    expect(find.byType(AlertDialog), findsNothing);
    expect(MaterialLibrary.instance.customMaterials.single.id, 'kept');
    expect(MaterialLibrary.instance.customMaterials.single.e1, 240);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacement write failure retains old values and allows retry',
      (tester) async {
    final storage = _useControlledStorage();
    final original = _entry('Saved laminate', id: 'kept');
    await MaterialLibrary.instance.save(original);
    await _open(tester);
    await _saveName(tester, 'Saved laminate');
    storage.failNext = true;
    await _tap(tester, find.text(_strings(tester).Calculator_replace_material));
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    expect(
        find.text(
            'Could not save this material. Check its values and try again.'),
        findsOneWidget);
    await _saveName(tester, 'Saved laminate');
    await _tap(tester, find.text(_strings(tester).Calculator_replace_material));
    expect(MaterialLibrary.instance.customMaterials.single.id, 'kept');
    expect(MaterialLibrary.instance.customMaterials.single.e1, 240);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed deletion keeps the row and supports a double-tap-safe retry',
      (tester) async {
    final storage = _useControlledStorage();
    final original = _entry('Saved laminate', id: 'kept');
    await MaterialLibrary.instance.save(original);
    final before = storage.getString(_storageKey);
    await _open(tester);
    final delete = _iconWithTooltip('Delete Saved laminate');
    final request = tester.widget<IconButton>(delete).onPressed!;
    request();
    request();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    storage.failNext = true;
    storage.returnFalse = true;
    final confirm = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Delete'))
        .onPressed!;
    confirm();
    confirm();
    await tester.pumpAndSettle();
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    expect(storage.getString(_storageKey), before);
    expect(find.text(_strings(tester).Calculator_material_delete_failed),
        findsOneWidget);
    expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
    expect(tester.takeException(), isNull);

    await _tap(tester, delete);
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
    expect(delete, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during a pending deletion does not update disposed UI',
      (tester) async {
    final storage = _useControlledStorage();
    await MaterialLibrary.instance.save(_entry('Saved laminate', id: 'kept'));
    await _open(tester);
    await _tap(tester, find.byTooltip('Delete Saved laminate'));
    final gate = Completer<void>();
    storage.nextWriteGate = gate;
    try {
      await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
      expect(
          tester
              .widget<IconButton>(_iconWithTooltip('Delete Saved laminate'))
              .onPressed,
          isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      if (!gate.isCompleted) gate.complete();
      await tester.pumpAndSettle();
    }
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('replacement actions fit narrow large-text dialogs in $locale',
        (tester) async {
      await MaterialLibrary.instance.save(_entry('Saved laminate'));
      await _open(tester, size: const Size(360, 800), scale: 2, locale: locale);
      await _saveName(tester, 'Saved laminate');
      final strings = _strings(tester);
      expect(
          find.text(strings.Calculator_replace_material_title), findsOneWidget);
      await _tap(tester, find.text(strings.Calculator_choose_another_name));
      expect(tester.widget<TextField>(_nameField).controller!.text,
          'Saved laminate');
      final cancel = MaterialLocalizations.of(tester.element(_nameField))
          .cancelButtonLabel;
      await _tap(tester, find.widgetWithText(TextButton, cancel));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rapid save callbacks open one dialog and disposal is safe',
      (tester) async {
    await MaterialLibrary.instance.save(_entry('Saved laminate'));
    await _open(tester);
    final onSave = tester.widget<TextButton>(_saveAction).onPressed!;
    onSave();
    onSave();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(_nameField, 'Saved laminate');
    final submit = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
        .onPressed!;
    submit();
    submit();
    await tester.pumpAndSettle();
    expect(find.text(_strings(tester).Calculator_replace_material_title),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(MaterialLibrary.instance.customMaterials.single.e1, 150);
    expect(tester.takeException(), isNull);
  });
}

LibraryMaterial _entry(String name,
        {String? id,
        double e1 = 150,
        MaterialKind kind = MaterialKind.lamina}) =>
    LibraryMaterial(
      id: id ?? 'incoming-$name',
      name: name,
      kind: kind,
      isCustom: true,
      source: 'Test supplier',
      e1: e1,
      e2: 10,
      g12: 5,
      nu12: 0.3,
    );

Finder get _saveAction => find.ancestor(
      of: find.byIcon(Icons.bookmark_add_outlined),
      matching: find.byType(TextButton),
    );
Finder get _nameField => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
Finder _iconWithTooltip(String tooltip) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip);
S _strings(WidgetTester tester) =>
    S.of(tester.element(find.byType(MaterialLibraryButton)));

Future<void> _open(WidgetTester tester,
    {Size size = const Size(1000, 1800),
    double scale = 1,
    Locale locale = const Locale('en')}) async {
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
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
          body: MaterialLibraryButton(
        kind: MaterialKind.lamina,
        onSelected: (_) {},
        saveCurrent: (name) => _entry(name, e1: 240),
      )),
    ),
  ));
  await tester.pumpAndSettle();
  await _tap(tester, find.text(_strings(tester).Calculator_library));
}

Future<void> _saveName(WidgetTester tester, String name) async {
  await _tap(tester, _saveAction);
  await tester.enterText(_nameField, name);
  final save =
      MaterialLocalizations.of(tester.element(_nameField)).saveButtonLabel;
  await _tap(tester, find.widgetWithText(TextButton, save));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final sheetScroll = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byWidgetPredicate((widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down),
    );
    await tester.scrollUntilVisible(finder, 200,
        scrollable: sheetScroll.first, maxScrolls: 20);
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

_ControlledPreferences _useControlledStorage() {
  final previous = SharedPreferencesHelper.localStorage;
  final storage = _ControlledPreferences();
  SharedPreferencesHelper.localStorage = storage;
  addTearDown(() {
    SharedPreferencesHelper.localStorage = previous;
  });
  return storage;
}

class _ControlledPreferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  bool failNext = false;
  bool returnFalse = false;
  Completer<void>? nextWriteGate;
  Completer<void>? writeStarted;

  @override
  Object? get(String key) => values[key];

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    final gate = nextWriteGate;
    nextWriteGate = null;
    if (gate != null) {
      writeStarted?.complete();
      await gate.future;
    }
    if (failNext) {
      failNext = false;
      if (returnFalse) return false;
      throw StateError('Storage unavailable');
    }
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    values[key] = List.of(value);
    return true;
  }
}
