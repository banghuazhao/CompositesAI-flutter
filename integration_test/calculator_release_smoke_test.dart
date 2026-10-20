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
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';
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
}

Future<void> _isolatedPreferences(UnitSystem system) async {
  expect(kIsWeb, isFalse, reason: 'Run this smoke target on iOS or Android.');
  expect(
      defaultTargetPlatform, anyOf(TargetPlatform.iOS, TargetPlatform.android));
  SharedPreferences.setMockInitialValues({
    'Calculator_Unit_System': system.name,
  });
  await SharedPreferencesHelper.init();
  MaterialLibrary.instance.resetForTest();
  addTearDown(MaterialLibrary.instance.resetForTest);
}

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
