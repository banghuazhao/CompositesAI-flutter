import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/thermal_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_sheet.dart';
import 'package:swiftcomp/util/others.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  test('saving factories keep null optional fields and finite CTEs valid', () {
    for (final units in [Units.si, Units.us]) {
      final partial = LibraryMaterial.fromLaminaInputs(
        name: 'Partial material',
        units: units,
        material: _partialLamina(),
        cte: TransverselyIsotropicCTE(),
        strengths: LaminaStrengths(),
      );
      expect(partial, isNotNull);
      expect(partial!.e2, isNull);
      expect(partial.alpha11, isNull);
      for (final alpha in [0.0, -2e-6]) {
        final matrix = LibraryMaterial.fromIsotropicInputs(
          name: 'Matrix',
          units: units,
          material: IsotropicMaterial()
            ..e = 3.5
            ..nu = 0.35,
          cte: IsotropicCTE()..alpha = alpha,
        );
        expect(matrix, isNotNull);
        expect(matrix!.alpha11, units.cteToPerC(alpha));
      }
    }
  });

  test('saving factories reject every nonfinite provided input', () {
    for (final invalid in [
      double.nan,
      double.infinity,
      double.negativeInfinity
    ]) {
      final fields = <void Function(TransverselyIsotropicMaterial)>[
        (material) => material.e1 = invalid,
        (material) => material.e2 = invalid,
        (material) => material.g12 = invalid,
        (material) => material.nu12 = invalid,
        (material) => material.nu23 = invalid,
      ];
      for (final update in fields) {
        final material = _partialLamina();
        update(material);
        expect(
            LibraryMaterial.fromLaminaInputs(
              name: 'Nonfinite lamina',
              units: Units.si,
              material: material,
            ),
            isNull);
      }
      for (final update in <void Function(TransverselyIsotropicCTE)>[
        (cte) => cte.alpha11 = invalid,
        (cte) => cte.alpha22 = invalid,
        (cte) => cte.alpha12 = invalid,
      ]) {
        final cte = TransverselyIsotropicCTE();
        update(cte);
        expect(
            LibraryMaterial.fromLaminaInputs(
              name: 'Nonfinite CTE',
              units: Units.si,
              material: _partialLamina(),
              cte: cte,
            ),
            isNull);
      }
      expect(
          LibraryMaterial.fromLaminaInputs(
            name: 'Nonfinite strength',
            units: Units.si,
            material: _partialLamina(),
            strengths: LaminaStrengths(xt: invalid),
          ),
          isNull);

      for (final material in [
        IsotropicMaterial()
          ..e = invalid
          ..nu = 0.35,
        IsotropicMaterial()
          ..e = 3.5
          ..nu = invalid,
      ]) {
        expect(
            LibraryMaterial.fromIsotropicInputs(
              name: 'Nonfinite matrix',
              units: Units.si,
              material: material,
            ),
            isNull);
      }
      expect(
          LibraryMaterial.fromIsotropicInputs(
            name: 'Nonfinite matrix CTE',
            units: Units.si,
            material: IsotropicMaterial()
              ..e = 3.5
              ..nu = 0.35,
            cte: IsotropicCTE()..alpha = invalid,
          ),
          isNull);
    }
  });

  test('saving rejects unit-conversion overflow before JSON serialization', () {
    expect(
        LibraryMaterial.fromLaminaInputs(
          name: 'Overflow lamina',
          units: Units.us,
          material: _partialLamina()..e1 = 1e308,
        ),
        isNull);
    expect(
        LibraryMaterial.fromIsotropicInputs(
          name: 'Overflow matrix',
          units: Units.us,
          material: IsotropicMaterial()
            ..e = 1e308
            ..nu = 0.35,
        ),
        isNull);
    expect(
        LibraryMaterial.fromLaminaInputs(
          name: 'Overflow CTE',
          units: Units.us,
          material: _partialLamina(),
          cte: TransverselyIsotropicCTE()..alpha11 = 1e308,
        ),
        isNull);
  });

  test('rejected direct entries do not replace saved material data', () async {
    await MaterialLibrary.instance.save(_custom('Kept material'));
    final stored =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    await expectLater(
      MaterialLibrary.instance
          .save(_custom('Kept material', e1: double.infinity)),
      throwsArgumentError,
    );
    expect(MaterialLibrary.instance.customMaterials.single.e1, 150);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
  });

  testWidgets(
      'search matches trimmed names or sources without case sensitivity',
      (tester) async {
    await _open(tester);

    await _searchFor(tester, '  t300/5208  ');
    expect(find.text('T300/5208 carbon/epoxy'), findsOneWidget);
    expect(find.text('IM7/8552 carbon/epoxy'), findsNothing);

    await _searchFor(tester, '  CAMANHO  ');
    expect(find.text('IM7/8552 carbon/epoxy'), findsOneWidget);
    expect(find.text('T300/5208 carbon/epoxy'), findsNothing);
    expect(find.text('Built-in'), findsOneWidget);
    expect(find.text('No materials match your search.'), findsNothing);

    await _searchFor(tester, '   ');
    expect(find.text('T300/5208 carbon/epoxy'), findsOneWidget);
    expect(find.text('IM7/8552 carbon/epoxy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'custom-only source matches show their section and remain selectable',
      (tester) async {
    final custom = _custom('My prepreg');
    await MaterialLibrary.instance.save(custom);
    LibraryMaterial? selected;
    await _open(tester, onSelected: (material) => selected = material);

    await _searchFor(tester, '  SuPpLiEr CaRd  ');
    expect(find.text(custom.name), findsOneWidget);
    expect(find.text('My materials'), findsOneWidget);
    expect(find.text('Built-in'), findsNothing);
    expect(find.text('No materials match your search.'), findsNothing);

    await _tap(tester, find.text(custom.name));
    expect(selected?.id, custom.id);
    expect(_search, findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('clear search is accessible and restores results in $locale',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final custom = _custom('My prepreg');
        await MaterialLibrary.instance.save(custom);
        await _open(tester, locale: locale);

        await _searchFor(tester, 'unmatched-material-xyz');
        expect(find.text('No materials match your search.'), findsOneWidget);
        expect(find.text('My materials'), findsNothing);
        expect(find.text('Built-in'), findsNothing);
        final clearLabel = MaterialLocalizations.of(tester.element(_search))
            .clearButtonTooltip;
        if (locale.languageCode != 'en') {
          expect(clearLabel, isNot('Clear text'));
        }
        final clearButton = find.byTooltip(clearLabel);
        expect(clearButton, findsOneWidget);
        expect(tester.getSemantics(clearButton).getSemanticsData().tooltip,
            clearLabel);

        await _tap(tester, clearButton);
        expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
        expect(find.text(custom.name), findsOneWidget);
        expect(find.text('T300/5208 carbon/epoxy'), findsOneWidget);
        expect(find.text('No materials match your search.'), findsNothing);
        expect(find.byTooltip(clearLabel), findsNothing);

        // Closing and opening the sheet creates a fresh controller/query.
        await _tap(tester, find.text('T300/5208 carbon/epoxy'));
        await _tap(tester, find.text('Library'));
        expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
        expect(find.byTooltip(clearLabel), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('deleting a searched custom material updates the empty state',
      (tester) async {
    final custom = _custom('My prepreg');
    await MaterialLibrary.instance.save(custom);
    await _open(tester);
    await _searchFor(tester, 'supplier card');

    await _tap(tester, find.byTooltip('Delete ${custom.name}'));
    await _tap(tester, find.text('Delete'));
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
    expect(find.text(custom.name), findsNothing);
    expect(find.text('No materials match your search.'), findsOneWidget);
    expect(find.text('Built-in'), findsNothing);
    expect(tester.widget<TextField>(_search).controller!.text, 'supplier card');

    final clearLabel =
        MaterialLocalizations.of(tester.element(_search)).clearButtonTooltip;
    await _tap(tester, find.byTooltip(clearLabel));
    expect(find.text('Built-in'), findsOneWidget);
    expect(find.text('T300/5208 carbon/epoxy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'saving current inputs adds a matching custom result without clearing search',
      (tester) async {
    String? savedName;
    LibraryMaterial? selected;
    await _open(
      tester,
      onSelected: (material) => selected = material,
      saveCurrent: (name) {
        savedName = name;
        return _custom(name);
      },
    );
    const name = 'New lab prepreg';
    await _searchFor(tester, name);
    expect(find.text('No materials match your search.'), findsOneWidget);

    await _tap(tester, find.text('Save current inputs as a material'));
    final nameField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Material name');
    await tester.enterText(nameField, name);
    await _tap(tester, find.text('Save'));

    expect(savedName, name);
    final savedTile = find.widgetWithText(ListTile, name);
    expect(savedTile, findsOneWidget);
    expect(find.text('My materials'), findsOneWidget);
    expect(find.text('Built-in'), findsNothing);
    expect(find.text('No materials match your search.'), findsNothing);
    expect(tester.widget<TextField>(_search).controller!.text, name);
    await _tap(tester, savedTile);
    expect(selected?.name, name);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save failure stays recoverable and allows a corrected retry',
      (tester) async {
    var attempts = 0;
    await _open(tester,
        saveCurrent: (name) =>
            _custom(name, e1: ++attempts == 1 ? double.infinity : 150));
    const name = 'Repairable prepreg';
    await _saveAs(tester, name);
    expect(
        find.text(
            'Could not save this material. Check its values and try again.'),
        findsOneWidget);
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
    expect(_search, findsOneWidget);
    expect(tester.takeException(), isNull);

    await _saveAs(tester, name);
    expect(attempts, 2);
    expect(MaterialLibrary.instance.customMaterials.single.name, name);
    expect(find.widgetWithText(ListTile, name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TransverselyIsotropicMaterial _partialLamina() =>
    TransverselyIsotropicMaterial()
      ..e1 = 150
      ..nu12 = 0.3;

LibraryMaterial _custom(String name, {double e1 = 150}) => LibraryMaterial(
      id: 'custom-test-$name',
      name: name,
      kind: MaterialKind.lamina,
      source: 'Internal supplier card, revision B',
      isCustom: true,
      e1: e1,
      e2: 10,
      g12: 5,
      nu12: 0.3,
    );

Finder get _search => find.byWidgetPredicate((widget) =>
    widget is TextField && widget.decoration?.hintText == 'Search materials');

Future<void> _open(
  WidgetTester tester, {
  ValueChanged<LibraryMaterial>? onSelected,
  MaterialFromInputs? saveCurrent,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => UnitSettings(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh', 'HK')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: MaterialLibraryButton(
          kind: MaterialKind.lamina,
          onSelected: onSelected ?? (_) {},
          saveCurrent: saveCurrent,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Library'));
}

Future<void> _searchFor(WidgetTester tester, String query) async {
  await _tap(tester, _search);
  await tester.enterText(_search, query);
  await tester.pumpAndSettle();
}

Future<void> _saveAs(WidgetTester tester, String name) async {
  await _tap(tester, find.text('Save current inputs as a material'));
  final nameField = find.byWidgetPredicate((widget) =>
      widget is TextField && widget.decoration?.labelText == 'Material name');
  await tester.enterText(nameField, name);
  await _tap(tester, find.text('Save'));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
