import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';
import 'package:swiftcomp/presentation/tools/widget/material_library_sheet.dart';
import 'package:swiftcomp/presentation/tools/widget/unit_system_picker.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

// Run on iOS or Android to exercise the real platform clipboard. The calculator
// opens directly, without app startup, authentication or backend requests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final system in UnitSystem.values) {
    final units = Units.of(system);

    testWidgets('${units.name} calculator inputs and native clipboard smoke',
        (tester) async {
      expect(kIsWeb, isFalse,
          reason: 'Run this smoke target on iOS or Android.');
      expect(
        defaultTargetPlatform,
        anyOf(TargetPlatform.iOS, TargetPlatform.android),
        reason: 'This target verifies a native clipboard, without a mock.',
      );

      // Isolate settings and the material library from the installed app's
      // saved preferences, while keeping the real platform clipboard.
      SharedPreferences.setMockInitialValues({
        'Calculator_Unit_System': system.name,
      });
      await SharedPreferencesHelper.init();
      MaterialLibrary.instance.resetForTest();
      addTearDown(MaterialLibrary.instance.resetForTest);

      await tester.pumpWidget(_calculatorApp());
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Library'));
      final search = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search materials');
      await _enterText(tester, search, '  kAw  ');
      expect(find.text('T300/5208 carbon/epoxy'), findsOneWidget);
      expect(find.text('IM7/8552 carbon/epoxy'), findsNothing);
      final clearSearch =
          MaterialLocalizations.of(tester.element(search)).clearButtonTooltip;
      await _tap(tester, find.byTooltip(clearSearch));
      expect(_enteredText(tester, search), isEmpty);
      expect(find.byTooltip(clearSearch), findsNothing);
      await _tap(tester, find.text('T300/5208 carbon/epoxy'));
      expect(find.text('E1 (${units.modulus})'), findsOneWidget);

      final thickness = units.lengthFromMm(0.125);
      await _enterText(
        tester,
        _fieldWithLabel('Thickness (${units.length})'),
        thickness.toString(),
      );
      final layup = _fieldWithLabel('[xx/xx/xx/xx]msn');

      if (system == UnitSystem.si) {
        // A previously valid layup must stop calculating as soon as Clear is
        // pressed. Material and thickness are already valid to isolate layup.
        await _enterText(tester, layup, '[0/90]s');
        await _tap(
          tester,
          find.descendant(
            of: find.byType(LayupSequenceRow),
            matching: find.byIcon(Icons.cancel),
          ),
        );
        expect(tester.widget<TextField>(layup).controller!.text, isEmpty);
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
        await _show(tester, layup);
        expect(find.text('Wrong layup sequence'), findsOneWidget);

        // Reject the repetition before allocating the expanded laminate. The
        // following interactions also prove the input screen stays responsive.
        await _enterText(tester, layup, '[0/90]1000001');
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
        await _show(tester, layup);
        expect(find.text('Too many layers'), findsOneWidget);
      }

      // Build an explicitly symmetric layup with every helper button. Closing
      // the bracket is the final edit, so a helper that fails to update the
      // calculation model cannot be masked by a later keyboard edit.
      await _enterText(tester, layup, '');
      await _tap(tester, _layupButton('['));
      await _enterText(tester, layup, '[0');
      await _tap(tester, _layupButton('/'));
      expect(tester.widget<TextField>(layup).controller!.text, '[0/');
      await _enterText(tester, layup, '[0/90/90/0');
      await _tap(tester, _layupButton(']'));
      const sequence = '[0/90/90/0]';
      expect(tester.widget<TextField>(layup).controller!.text, sequence);

      await _show(tester, find.byKey(const ValueKey('layup-ply-count')));
      expect(find.text('4 plies'), findsOneWidget);
      expect(
          find.text(
              'Total thickness: ${system == UnitSystem.si ? '0.5 mm' : '0.019685 in'}'),
          findsOneWidget);

      if (system == UnitSystem.si) {
        final thicknessField = _fieldWithLabel('Thickness (mm)');
        for (final invalid in ['0', '-1', 'NaN', 'Infinity']) {
          await _enterText(tester, thicknessField, invalid);
          await _tap(tester, find.text('Calculate'));
          expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
          await _show(tester, thicknessField);
          expect(
              find.text(invalid == '0' || invalid == '-1'
                  ? 'Thickness must be greater than zero'
                  : 'Enter a finite number'),
              findsOneWidget);
          expect(find.byKey(const ValueKey('layup-total-thickness')),
              findsNothing);
        }
        await _enterText(tester, thicknessField, '0.25');
        expect(find.text('Total thickness: 1 mm'), findsOneWidget);
        await _enterText(tester, thicknessField, thickness.toString());
        expect(find.text('Total thickness: 0.5 mm'), findsOneWidget);
      }

      await _tap(tester, find.text('Calculate'));
      expect(find.byType(LaminatePlatePropertiesResultPage), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('A Matrix (${units.aMatrix})'), findsOneWidget);

      await _tap(tester, find.byTooltip('Export results'));
      expect(find.text('Share as CSV'), findsOneWidget);
      expect(find.text('Share as PDF'), findsOneWidget);
      await _tap(tester, find.text('Copy results'));
      await _waitFor(tester, find.text('Results copied to clipboard'));
      expect(find.text('Results copied to clipboard'), findsOneWidget);

      // Deliberately use the real Clipboard API: no platform-channel handler
      // is installed by this target.
      final copied = await Clipboard.getData(Clipboard.kTextPlain);
      expect(copied?.text, isNotNull);
      final text = copied!.text!;
      expect(text, startsWith('Laminate Plate Properties\r\n'));
      expect(text, contains('Units\t${units.name} (${units.summary})\r\n'));
      expect(text, contains('Layup sequence\t$sequence\t\r\n'));
      expect(text, contains('Ply thickness\t$thickness\t${units.length}\r\n'));
      expect(text, contains('Result: A Matrix\r\nUnit\t${units.aMatrix}'));
      expect(text, contains('Result: B Matrix\r\nUnit\t${units.bMatrix}'));
      expect(text, contains('Result: D Matrix\r\nUnit\t${units.dMatrix}'));
      expect(text, isNot(contains('NaN')));
      expect(text, isNot(contains('Infinity')));

      final rows = text.split('\r\n');
      final matrixStart = rows.indexOf('Result: A Matrix');
      expect(matrixStart, greaterThanOrEqualTo(0));
      for (var row = 0; row < 3; row++) {
        final cells = rows[matrixStart + 2 + row].split('\t');
        expect(cells, hasLength(3));
        final values = cells.map(double.parse).toList();
        expect(values.every((value) => value.isFinite), isTrue);
        expect(values[row], greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('${units.name} native chart inspection retains vertical scroll',
        (tester) async {
      await _isolatedPreferences(system);
      const scrollKey = ValueKey('native-chart-smoke-scroll');
      await tester.pumpWidget(_calculatorApp(
        home: Scaffold(
          appBar: AppBar(title: Text('${units.name} chart smoke')),
          body: SingleChildScrollView(
            key: scrollKey,
            child: Column(
              children: [
                const SizedBox(height: 80),
                LaminarStressStrainLineChat(
                  title: 'Stress through the thickness',
                  component: 'σ11',
                  depthUnit: units.length,
                  valueUnit: units.stress,
                  data: [
                    FlSpot(units.lengthFromMm(-0.125), units.stressFromMPa(10)),
                    FlSpot(0, units.stressFromMPa(20)),
                    FlSpot(0, units.stressFromMPa(40)),
                    FlSpot(units.lengthFromMm(0.125), units.stressFromMPa(50)),
                  ],
                ),
                const SizedBox(height: 1400),
                const Text('End of chart scroll smoke'),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await _show(tester, find.byType(LineChart));

      var chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.chartRendererKey, isNotNull);
      final plot = find.byKey(chart.chartRendererKey!);
      final plotRect = tester.getRect(plot);
      await tester.tapAt(plotRect.center);
      await tester.pumpAndSettle();

      chart = tester.widget<LineChart>(find.byType(LineChart));
      final indicators = chart.data.showingTooltipIndicators;
      expect(indicators, hasLength(1));
      expect(chart.data.lineBarsData.single.showingIndicators, hasLength(2));
      final tooltip = chart.data.lineTouchData.touchTooltipData
          .getTooltipItems(indicators.single.showingSpots)
          .single;
      expect(tooltip, isNotNull);
      expect(tooltip!.text, contains('Depth: 0 ${units.length}'));
      expect(tooltip.text, contains('Ply 1 · Top'));
      expect(tooltip.text, contains('Ply 2 · Bottom'));
      expect(tooltip.text.split(' ${units.stress}'), hasLength(3));

      final scrollable = find.descendant(
        of: find.byKey(scrollKey),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable.first).position;
      final before = position.pixels;
      await tester.dragFrom(plotRect.center, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(before + 20),
          reason: 'Dragging the plot must scroll the surrounding result page.');
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }

  testWidgets('native lamina finite angle and stress validation recovers',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    await tester.pumpWidget(_calculatorApp(home: LaminaStressStrainPage()));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    await _tap(tester, find.text('T300/5208 carbon/epoxy'));
    final angle = _fieldWithLabel('(-90 <= Angle <= 90)');
    final stress = _fieldWithLabel('σ11 (MPa)');
    await _enterText(tester, angle, '0');
    await _enterText(tester, stress, '100');
    await _enterText(tester, _fieldWithLabel('σ22 (MPa)'), '0');
    await _enterText(tester, _fieldWithLabel('σ12 (MPa)'), '0');

    for (final invalid in ['NaN', 'Infinity']) {
      await _enterText(tester, angle, invalid);
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(LaminaStressStrainResult), findsNothing);
      expect(tester.widget<TextField>(angle).decoration!.errorText,
          'Enter a finite number');
      expect(tester.takeException(), isNull);
    }
    await _enterText(tester, angle, '0');
    for (final invalid in ['NaN', 'Infinity']) {
      await _enterText(tester, stress, invalid);
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(LaminaStressStrainResult), findsNothing);
      expect(tester.widget<TextField>(stress).decoration!.errorText,
          'Enter a finite number');
      expect(tester.takeException(), isNull);
    }
    await _enterText(tester, stress, '100');
    await _tap(tester, find.text('Calculate'));
    expect(find.byType(LaminaStressStrainResult), findsOneWidget);
    final result = tester.widget<LaminaStressStrainResult>(
        find.byType(LaminaStressStrainResult));
    expect(result.output.epsilon11, greaterThan(0));
    expect(
        result.output.Q.expand((row) => row).every((value) => value.isFinite),
        isTrue);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
      'release precision controls, failure pagination and complete clipboard',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si,
        extra: {'Number_Precision': 1000});
    final result = _releaseFailureResult();
    await tester.pumpWidget(
        _calculatorApp(home: LaminateFailureResultPage(result: result)));
    await tester.pumpAndSettle();

    final add = find.widgetWithIcon(IconButton, Icons.add);
    final remove = find.widgetWithIcon(IconButton, Icons.remove);
    await _tap(tester, find.byTooltip('Result precision'));
    expect(find.byType(ResultPrecisionPage), findsOneWidget);
    expect(tester.widget<IconButton>(add).onPressed, isNull);
    expect(find.text(123456789.toStringAsExponential(9)), findsOneWidget);
    for (var step = 0; step < 8; step++) {
      await _tap(tester, remove);
    }
    expect(tester.widget<IconButton>(remove).onPressed, isNull);
    expect(find.text(123456789.toStringAsExponential(1)), findsOneWidget);
    await _tap(tester, find.byType(BackButton));
    expect(
        find.text(
            'R = ${CalcReport.formatNumber(_releaseRatio, precision: 1)}'),
        findsNWidgets(4));

    await _tap(tester, find.byTooltip('Result precision'));
    for (var step = 0; step < 8; step++) {
      await _tap(tester, add);
    }
    expect(tester.widget<IconButton>(add).onPressed, isNull);
    expect(SharedPreferencesHelper.localStorage.getInt('Number_Precision'), 9);
    await _tap(tester, find.byType(BackButton));
    expect(
        find.text(
            'R = ${CalcReport.formatNumber(_releaseRatio, precision: 9)}'),
        findsNWidgets(4));

    final tableFinder = find.byType(DataTable);
    if (tableFinder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(tableFinder, 300,
          scrollable: find.byType(Scrollable).first);
    }
    await _show(tester, tableFinder);
    DataTable table() => tester.widget<DataTable>(tableFinder);
    expect(table().rows, hasLength(20));
    expect((table().rows.first.cells[2].child as Text).data,
        CalcReport.formatNumber(_releaseStress, precision: 9));
    final first = find.byKey(const ValueKey('failure-table-first-page'));
    final last = find.byKey(const ValueKey('failure-table-last-page'));
    final range = find.byKey(const ValueKey('failure-table-range'));
    expect(tester.widget<IconButton>(first).onPressed, isNull);
    await _tap(tester, last);
    expect(tester.widget<Text>(range).data, '21–24 of 24');
    expect(table().rows, hasLength(4));
    expect((table().rows.first.cells.first.child as Text).data, '11 (0°)');
    expect((table().rows.last.cells.first.child as Text).data, '12 (0°)');
    expect((table().rows.last.cells[1].child as Text).data, 'Top');
    expect(tester.widget<IconButton>(last).onPressed, isNull);
    await _tap(tester, first);
    expect(tester.widget<Text>(range).data, '1–20 of 24');
    expect(table().rows, hasLength(20));

    await _tap(tester, find.byTooltip('Export results'));
    await _tap(tester, find.text('Copy results'));
    await _waitFor(tester, find.text('Results copied to clipboard'));
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final rows = clipboard!.text!.split('\r\n');
    final section = rows
        .indexOf('Result: Ply stresses (material axes) and failure indices');
    expect(section, greaterThanOrEqualTo(0));
    final copiedPoints = rows
        .skip(section + 2)
        .takeWhile((row) => row.isNotEmpty)
        .map((row) => row.split('\t'))
        .toList();
    expect(copiedPoints, hasLength(24),
        reason:
            'Copy exports every surface, independently of the visible page.');
    expect(copiedPoints.first[0], '1');
    expect(copiedPoints.first[2], 'Bottom');
    expect(copiedPoints.last[0], '12');
    expect(copiedPoints.last[2], 'Top');
    expect(copiedPoints.first[4], _releaseStress.toString(),
        reason: 'Clipboard keeps full precision beyond the display setting.');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
      'release material replacement cancel preserves data and replace commits',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    final original =
        _releaseMaterial('Release prepreg', id: 'release-original');
    await MaterialLibrary.instance.save(original);
    final before =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    LibraryMaterial? selected;
    await tester.pumpWidget(_calculatorApp(
      home: Scaffold(
        body: Center(
          child: MaterialLibraryButton(
            kind: MaterialKind.lamina,
            onSelected: (material) => selected = material,
            saveCurrent: (name) =>
                _releaseMaterial(name, id: 'release-incoming', e1: 240),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));

    Future<void> saveDuplicate() async {
      await _tap(tester, find.text('Save current inputs as a material'));
      await _enterText(
          tester, _fieldWithLabel('Material name'), '  release PREPREG  ');
      await _tap(tester, find.widgetWithText(TextButton, 'Save'));
      expect(find.text('Replace saved material?'), findsOneWidget);
    }

    await saveDuplicate();
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    await _tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(MaterialLibrary.instance.customMaterials.single, same(original));
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        before);

    await saveDuplicate();
    await _tap(tester, find.widgetWithText(TextButton, 'Replace'));
    expect(find.byType(AlertDialog), findsNothing);
    final replacement = MaterialLibrary.instance.customMaterials.single;
    expect(replacement.id, original.id);
    expect(replacement.e1, 240);
    expect(replacement.name.toLowerCase(), original.name.toLowerCase());
    MaterialLibrary.instance.resetForTest();
    final reloaded = MaterialLibrary.instance.customMaterials.single;
    expect(reloaded.id, original.id);
    expect(reloaded.e1, 240);
    await _tap(tester, find.widgetWithText(ListTile, replacement.name));
    expect(selected?.id, original.id);
    expect(selected?.e1, 240);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
  testWidgets(
      'recovery release keeps valid materials and backs up damaged data',
      (tester) async {
    final original = _releaseMaterial('Recovered prepreg', id: 'recovered');
    final damaged = jsonEncode([
      original.toJson(),
      {'name': 'Damaged record', 'e1': 'not-a-number', 'nu12': 0.3},
    ]);
    await _isolatedPreferences(UnitSystem.si,
        extra: {'Custom_Materials_v1': damaged});
    expect(MaterialLibrary.instance.customMaterials.single.id, original.id);
    LibraryMaterial? selected;
    await tester.pumpWidget(_calculatorApp(
      home: Scaffold(
        body: Center(
          child: MaterialLibraryButton(
            kind: MaterialKind.lamina,
            onSelected: (material) => selected = material,
            saveCurrent: (name) => _releaseMaterial(name, id: 'new-recovered'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    await _tap(tester, find.text(original.name));
    expect(selected?.id, original.id);
    await _tap(tester, find.text('Library'));
    await _tap(tester, find.text('Save current inputs as a material'));
    await _enterText(tester, _fieldWithLabel('Material name'), 'New prepreg');
    await _tap(tester, find.widgetWithText(TextButton, 'Save'));
    expect(MaterialLibrary.instance.customMaterials, hasLength(2));
    final storage = SharedPreferencesHelper.localStorage;
    final backup =
        jsonDecode(storage.getString('Custom_Materials_Recovery_v1')!) as Map;
    expect(backup['value'], damaged);
    MaterialLibrary.instance.resetForTest();
    expect(
        MaterialLibrary.instance.customMaterials.map((material) => material.id),
        containsAll(['recovered', 'new-recovered']));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('recovery release unit picker survives a failed preference write',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    final original = SharedPreferencesHelper.localStorage;
    SharedPreferencesHelper.localStorage = _FailingUnitPreferences(original);
    addTearDown(() => SharedPreferencesHelper.localStorage = original);
    await tester.pumpWidget(_calculatorApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(actions: const [UnitSystemButton()]),
          body:
              Center(child: Text(context.watch<UnitSettings>().units.summary)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(TextButton, 'SI'));
    await _tap(tester, find.text('US customary'));
    expect(find.text(Units.us.summary), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'US'), findsOneWidget);
    expect(original.getString('Calculator_Unit_System'), 'si');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('recovery release lamina keeps separate stress and strain drafts',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    await tester.pumpWidget(_calculatorApp(home: LaminaStressStrainPage()));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    await _tap(tester, find.text('T300/5208 carbon/epoxy'));
    await _enterText(tester, _fieldWithLabel('(-90 <= Angle <= 90)'), '0');
    await _enterText(tester, _fieldWithLabel('σ11 (MPa)'), '100.00');
    await _enterText(tester, _fieldWithLabel('σ22 (MPa)'), '0');
    await _enterText(tester, _fieldWithLabel('σ12 (MPa)'), '0');
    await _selectTensorMode(tester, 'Strain');
    expect(_enteredText(tester, _fieldWithLabel('ε11')), isEmpty);
    await _enterText(tester, _fieldWithLabel('ε11'), '0.0010');
    await _enterText(tester, _fieldWithLabel('ε22'), '0');
    await _enterText(tester, _fieldWithLabel('γ12 (2ε12)'), '0');
    await _selectTensorMode(tester, 'Stress');
    expect(_enteredText(tester, _fieldWithLabel('σ11 (MPa)')), '100.00');
    await _selectTensorMode(tester, 'Strain');
    expect(_enteredText(tester, _fieldWithLabel('ε11')), '0.0010');
    await _tap(tester, find.text('Calculate'));
    final result = tester.widget<LaminaStressStrainResult>(
        find.byType(LaminaStressStrainResult));
    expect(result.output.tensorType.name, 'stress');
    expect(
        result.inputs
            .whereType<ValuesSection>()
            .expand((section) => section.entries)
            .singleWhere((entry) => entry.label == 'ε11')
            .value,
        0.001);
    expect(result.output.sigma11, greaterThan(100));
    await _tap(
        tester, find.widgetWithIcon(IconButton, Icons.arrow_back_ios_outlined));
    expect(_enteredText(tester, _fieldWithLabel('ε11')), '0.0010');
    await _selectTensorMode(tester, 'Stress');
    expect(_enteredText(tester, _fieldWithLabel('σ11 (MPa)')), '100.00');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('recovery release laminate keeps separate load and strain drafts',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    await tester
        .pumpWidget(_calculatorApp(home: const LaminateStressStrainPage()));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    await _tap(tester, find.text('T300/5208 carbon/epoxy'));
    await _enterText(tester, _fieldWithLabel('[xx/xx/xx/xx]msn'), '[0/90]s');
    await _enterText(tester, _fieldWithLabel('Thickness (mm)'), '0.125');
    for (final label in [
      'N11 (N/mm)',
      'N22 (N/mm)',
      'N12 (N/mm)',
      'M11 (N·mm/mm)',
      'M22 (N·mm/mm)',
      'M12 (N·mm/mm)'
    ]) {
      await _enterText(tester, _fieldWithLabel(label),
          label.startsWith('N11') ? '100.00' : '0');
    }
    await _selectTensorMode(tester, 'Plate Strains/Curvatures');
    expect(_enteredText(tester, _fieldWithLabel('ϵ11')), isEmpty);
    for (final label in [
      'ϵ11',
      'ϵ22',
      'ϵ12',
      '𝞳11 (1/mm)',
      '𝞳22 (1/mm)',
      '𝞳12 (1/mm)'
    ]) {
      await _enterText(
          tester, _fieldWithLabel(label), label == 'ϵ11' ? '0.0010' : '0');
    }
    await _selectTensorMode(tester, 'Stress Resultants');
    expect(_enteredText(tester, _fieldWithLabel('N11 (N/mm)')), '100.00');
    await _selectTensorMode(tester, 'Plate Strains/Curvatures');
    expect(_enteredText(tester, _fieldWithLabel('ϵ11')), '0.0010');
    await _tap(tester, find.text('Calculate'));
    final result = tester.widget<LaminateStressStrainResultPage>(
        find.byType(LaminateStressStrainResultPage));
    expect(result.inputTensor, isA<LaminateStrain>());
    expect((result.inputTensor as LaminateStrain).epsilon11, 0.001);
    await _tap(
        tester, find.widgetWithIcon(IconButton, Icons.arrow_back_ios_outlined));
    expect(_enteredText(tester, _fieldWithLabel('ϵ11')), '0.0010');
    await _selectTensorMode(tester, 'Stress Resultants');
    expect(_enteredText(tester, _fieldWithLabel('N11 (N/mm)')), '100.00');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
  testWidgets('material tools native details cancel and apply safely',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    final material = _releaseMaterial('Preview prepreg', id: 'preview-native');
    await MaterialLibrary.instance.save(material);
    final stored =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    LibraryMaterial? selected;
    await tester.pumpWidget(_calculatorApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Material preview smoke')),
        body: Center(
          child: MaterialLibraryButton(
            kind: MaterialKind.lamina,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    final details =
        find.byKey(const ValueKey('material-details-preview-native'));
    await _tap(tester, details);
    expect(find.byKey(const Key('material-details-dialog')), findsOneWidget);
    expect(selected, isNull);
    await _tap(tester, find.byKey(const Key('material-details-cancel')));
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(selected, isNull);
    await _tap(tester, details);
    await _tap(tester, find.byKey(const Key('material-details-apply')));
    expect(selected, same(material));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.text('Material preview smoke'), findsOneWidget);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('material tools native JSON includes saved kinds outside search',
      (tester) async {
    await _isolatedPreferences(UnitSystem.us);
    final material = _releaseMaterial('Native export prepreg',
        id: 'native-export-lamina', e1: 150.12345678901235);
    const matrix = LibraryMaterial(
      id: 'native-export-matrix',
      name: 'Native export matrix',
      kind: MaterialKind.matrix,
      isCustom: true,
      e1: 3.5,
      nu12: 0.35,
    );
    await MaterialLibrary.instance.save(material);
    await MaterialLibrary.instance.save(matrix);
    final stored =
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final shareCalls = <MethodCall>[];
    // Intercept only the final native handoff. SharePlus keeps its real
    // platform singleton and writes the generated XFile to a device temp file.
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return ''; // The native share sheet was dismissed.
    });
    addTearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));
    await tester.pumpWidget(_calculatorApp(
      home: Scaffold(
        body: Center(
          child: MaterialLibraryButton(
            kind: MaterialKind.lamina,
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Library'));
    await _enterText(
        tester,
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search materials'),
        'Native export prepreg');
    expect(find.text(matrix.name), findsNothing);
    await _tap(tester, find.byKey(const Key('material-library-export-button')));
    final call = shareCalls.single;
    expect(call.method, 'share');
    final request = call.arguments as Map;
    final file = File((request['paths'] as List).single as String);
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });
    expect(file.uri.pathSegments.last, 'CompositesAI_materials.json');
    expect(request['mimeTypes'], ['application/json']);
    expect(request['originWidth'], greaterThan(0));
    expect(request['originHeight'], greaterThan(0));
    final data = jsonDecode(utf8.decode(await file.readAsBytes())) as Map;
    expect(data['version'], 1);
    expect(data['unitSystem'], 'SI');
    final records = data['materials'] as List;
    expect(records.map((record) => (record as Map)['id']),
        [matrix.id, material.id]);
    expect((records.last as Map)['e1'], material.e1);
    expect(
        SharedPreferencesHelper.localStorage.getString('Custom_Materials_v1'),
        stored);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('material tools native failure filters keep complete clipboard',
      (tester) async {
    await _isolatedPreferences(UnitSystem.si);
    await tester.pumpWidget(_calculatorApp(
        home: LaminateFailureResultPage(result: _filterFailureResult())));
    await tester.pumpAndSettle();
    await _tap(
        tester, find.byKey(const ValueKey('failure-only-failed-filter')));

    Future<void> select(FailureCriterion criterion) async {
      await _tap(
          tester, find.byKey(const ValueKey('failure-criterion-filter')));
      await _tap(tester, find.text(criterion.label).last);
    }

    DataTable table() => tester.widget<DataTable>(find.byType(DataTable));
    await select(FailureCriterion.maxStress);
    expect(table().rows, hasLength(20));
    expect(table().columns, hasLength(6));
    await _tap(tester, find.byKey(const ValueKey('failure-table-last-page')));
    expect(table().rows.map((row) => row.key), [
      const ValueKey('failure-point-40'),
      const ValueKey('failure-point-42'),
      const ValueKey('failure-point-44'),
    ]);
    await select(FailureCriterion.tsaiWu);
    expect(table().rows, isEmpty);
    expect(find.byKey(const ValueKey('failure-empty-state')), findsOneWidget);
    await select(FailureCriterion.hashin);
    expect(table().rows.single.key, const ValueKey('failure-point-45'));
    await _tap(tester, find.byTooltip('Export results'));
    await _tap(tester, find.text('Copy results'));
    await _waitFor(tester, find.text('Results copied to clipboard'));
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final rows = clipboard!.text!.split('\r\n');
    final section = rows
        .indexOf('Result: Ply stresses (material axes) and failure indices');
    expect(section, greaterThanOrEqualTo(0));
    final surfaces = rows
        .skip(section + 2)
        .takeWhile((row) => row.isNotEmpty)
        .map((row) => row.split('\t'))
        .toList();
    expect(surfaces, hasLength(46));
    expect(surfaces.every((row) => row.length == 11), isTrue);
    expect(surfaces.first[0], '1');
    expect(surfaces.last[0], '23');
    expect(surfaces.last[2], 'Top');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

LaminateFailureResult _filterFailureResult() => LaminateFailureResult(
      points: [
        for (var row = 0; row < 46; row++)
          PlyStressPoint(
            ply: row ~/ 2 + 1,
            angle: 0,
            isTop: row.isOdd,
            z: row * 0.125,
            globalStress: [_releaseStress, 0, 0],
            materialStress: [_releaseStress, 0, 0],
            results: {
              FailureCriterion.maxStress:
                  CriterionResult(row.isEven ? 1 : 2, 'Fiber tension'),
              FailureCriterion.tsaiHill:
                  CriterionResult(row % 3 == 0 ? 0.5 : 2, 'Fiber tension'),
              FailureCriterion.tsaiWu:
                  const CriterionResult(double.infinity, 'Unloaded'),
              FailureCriterion.hashin:
                  CriterionResult(row == 45 ? 0.25 : 2, 'Fiber tension'),
            },
          ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );

class _FailingUnitPreferences extends Fake implements SharedPreferences {
  _FailingUnitPreferences(this.backing);

  final SharedPreferences backing;

  @override
  Object? get(String key) => backing.get(key);

  @override
  String? getString(String key) => backing.getString(key);

  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'Calculator_Unit_System') {
      throw StateError('Simulated write failure');
    }
    return backing.setString(key, value);
  }
}

Future<void> _selectTensorMode(WidgetTester tester, String label) async {
  await _tap(tester, find.byType(DropdownButton<String>));
  await _tap(tester, find.text(label).last);
}

Future<void> _isolatedPreferences(UnitSystem system,
    {Map<String, Object> extra = const {}}) async {
  expect(kIsWeb, isFalse, reason: 'Run this smoke target on iOS or Android.');
  expect(
      defaultTargetPlatform, anyOf(TargetPlatform.iOS, TargetPlatform.android));
  SharedPreferences.setMockInitialValues({
    'Calculator_Unit_System': system.name,
    ...extra,
  });
  await SharedPreferencesHelper.init();
  MaterialLibrary.instance.resetForTest();
  addTearDown(MaterialLibrary.instance.resetForTest);
}

const _releaseRatio = 1.23456789123;
const _releaseStress = 12.3456789123;

LaminateFailureResult _releaseFailureResult() => LaminateFailureResult(
      points: [
        for (var row = 0; row < 24; row++)
          PlyStressPoint(
            ply: row ~/ 2 + 1,
            angle: 0,
            isTop: row.isOdd,
            z: -0.75 + (row ~/ 2 + (row.isOdd ? 1 : 0)) * 0.125,
            globalStress: [_releaseStress, -0.123456789123, 0],
            materialStress: [_releaseStress, -0.123456789123, 0],
            results: {
              for (final criterion in FailureCriterion.values)
                criterion:
                    const CriterionResult(_releaseRatio, 'Fiber tension'),
            },
          ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );

LibraryMaterial _releaseMaterial(String name,
        {required String id, double e1 = 150}) =>
    LibraryMaterial(
      id: id,
      name: name,
      kind: MaterialKind.lamina,
      isCustom: true,
      source: 'Native release smoke fixture',
      e1: e1,
      e2: 10,
      g12: 5,
      nu12: 0.3,
    );

Widget _calculatorApp({Widget home = const LaminatePlatePropertiesPage()}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NumberPrecisionHelper()),
        ChangeNotifierProvider(create: (_) => UnitSettings()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

Finder _layupButton(String symbol) => find.descendant(
      of: find.byType(LayupSequenceRow),
      matching: find.widgetWithText(ElevatedButton, symbol),
    );

Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await _hideKeyboard(tester);
  expect(finder, findsOneWidget);
  // The calculator uses a scroll view on phones. Dismiss the native keyboard
  // before revealing a control so it cannot obscure the intended tap target.
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterText(
    WidgetTester tester, Finder finder, String value) async {
  await _show(tester, finder);
  // The integration binding keeps its last focusedEditable after unfocusing.
  // showKeyboard (called by enterText) only requests focus when that reference
  // changes, so explicitly tap to reopen the native connection for repeated
  // edits to the same field.
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pump();
  expect(
    _enteredText(tester, finder),
    value,
    reason: 'Text entry must reach the field before keyboard dismissal.',
  );
  await _hideKeyboard(tester);
  expect(
    _enteredText(tester, finder),
    value,
    reason: 'Keyboard dismissal must preserve the entered text.',
  );
}

String _enteredText(WidgetTester tester, Finder finder) => tester
    .widget<EditableText>(find.descendant(
      of: finder,
      matching: find.byType(EditableText),
    ))
    .controller
    .text;

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final watch = Stopwatch()..start();
  while (finder.evaluate().isEmpty &&
      watch.elapsed < const Duration(seconds: 10)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
