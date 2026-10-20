import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/widget/laminate_stress_strain_row.dart';
import 'package:swiftcomp/presentation/tools/widget/plane_stress_strain_row.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

const _stressText = ['1.00e2', '-20.50', '3e0', '-4.0', '5.00', '0'];
const _strainText = ['.0010', '-2.00e-3', '3e-4', '1.00e-5', '-2e-5', '0'];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  for (final laminate in [false, true]) {
    final name = laminate ? 'laminate' : 'lamina';
    final count = laminate ? 6 : 3;

    testWidgets(
        '$name retains every raw field across repeated mode round trips',
        (tester) async {
      await _open(tester, laminate);
      await _fill(tester, _stressLabels(laminate), _stressText.take(count));
      final stress = _tensor(tester, laminate);
      await _switch(tester, laminate, strain: true);
      _expectTexts(tester, _strainLabels(laminate), List.filled(count, ''));
      expect(_tensor(tester, laminate).isValid(), isFalse);
      await _fill(tester, _strainLabels(laminate), _strainText.take(count));
      final strain = _tensor(tester, laminate);
      expect(strain, isNot(same(stress)));

      for (var repeat = 0; repeat < 3; repeat++) {
        await _switch(tester, laminate, strain: false);
        _expectTexts(tester, _stressLabels(laminate), _stressText.take(count));
        expect(_tensor(tester, laminate), same(stress));
        await _switch(tester, laminate, strain: true);
        _expectTexts(tester, _strainLabels(laminate), _strainText.take(count));
        expect(_tensor(tester, laminate), same(strain));
      }
      final dropdown =
          tester.widget<DropdownButton<String>>(_dropdown(laminate));
      dropdown.onChanged!(null);
      dropdown.onChanged!(dropdown.value);
      await tester.pump();
      _expectTexts(tester, _strainLabels(laminate), _strainText.take(count));
      expect(_tensor(tester, laminate), same(strain));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$name retains partial invalid drafts and keeps their models invalid',
        (tester) async {
      await _open(tester, laminate);
      await _fill(tester, _stressLabels(laminate), List.filled(count, '0'));
      await _enter(tester, _stressLabels(laminate).first, '-');
      await _switch(tester, laminate, strain: true);
      await _fill(tester, _strainLabels(laminate), List.filled(count, '0'));
      await _enter(tester, _strainLabels(laminate).first, '1e-');
      for (var repeat = 0; repeat < 2; repeat++) {
        await _switch(tester, laminate, strain: false);
        expect(_text(tester, _stressLabels(laminate).first), '-');
        expect(_tensor(tester, laminate).isValid(), isFalse);
        await _switch(tester, laminate, strain: true);
        expect(_text(tester, _strainLabels(laminate).first), '1e-');
        expect(_tensor(tester, laminate).isValid(), isFalse);
      }
      await _enter(tester, _strainLabels(laminate).first, '.001');
      expect(_tensor(tester, laminate).isValid(), isTrue);
      await _switch(tester, laminate, strain: false);
      expect(_tensor(tester, laminate).isValid(), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$name unit changes keep both existing drafts without converting values',
        (tester) async {
      final settings = UnitSettings();
      addTearDown(settings.dispose);
      await _open(tester, laminate, settings: settings);
      await _fill(tester, _stressLabels(laminate), _stressText.take(count));
      await _switch(tester, laminate, strain: true);
      await _fill(tester, _strainLabels(laminate), _strainText.take(count));
      await settings.setSystem(UnitSystem.us);
      await tester.pumpAndSettle();
      _expectTexts(
          tester, _strainLabels(laminate, us: true), _strainText.take(count));
      await _switch(tester, laminate, strain: false);
      _expectTexts(
          tester, _stressLabels(laminate, us: true), _stressText.take(count));
      final active = _tensor(tester, laminate);
      expect(
          laminate
              ? (active as LaminateStress).N11
              : (active as PlaneStress).sigma11,
          100);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$name calculates the active draft and retains both after results/back',
        (tester) async {
      await _open(tester, laminate);
      await _prepareCalculation(tester, laminate);
      await _fill(tester, _stressLabels(laminate),
          ['100', ...List.filled(count - 1, '0')]);
      await _switch(tester, laminate, strain: true);
      await _fill(tester, _strainLabels(laminate),
          ['.001', ...List.filled(count - 1, '0')]);
      await _tap(tester, find.text('Calculate'));
      if (laminate) {
        final result = tester.widget<LaminateStressStrainResultPage>(
            find.byType(LaminateStressStrainResultPage));
        expect(result.inputTensor, isA<LaminateStrain>());
        expect(result.output.tensorType, TensorType.stress);
        expect(_reportValue(result.inputs, 'ε11'), .001);
      } else {
        final result = tester.widget<LaminaStressStrainResult>(
            find.byType(LaminaStressStrainResult));
        expect(result.output.tensorType, TensorType.stress);
        expect(result.output.sigma11, greaterThan(100));
        expect(_reportValue(result.inputs, 'ε11'), .001);
      }
      await _back(tester);
      expect(_text(tester, _strainLabels(laminate).first), '.001');
      await _switch(tester, laminate, strain: false);
      expect(_text(tester, _stressLabels(laminate).first), '100');
      await _tap(tester, find.text('Calculate'));
      if (laminate) {
        final result = tester.widget<LaminateStressStrainResultPage>(
            find.byType(LaminateStressStrainResultPage));
        expect(result.inputTensor, isA<LaminateStress>());
        expect(result.output.tensorType, TensorType.strain);
        expect(_reportValue(result.inputs, 'N11'), 100);
      } else {
        final result = tester.widget<LaminaStressStrainResult>(
            find.byType(LaminaStressStrainResult));
        expect(result.output.tensorType, TensorType.strain);
        expect(result.output.epsilon11, closeTo(100 / 181000, 1e-12));
        expect(_reportValue(result.inputs, 'σ11'), 100);
      }
      await _back(tester);
      await _switch(tester, laminate, strain: true);
      expect(_text(tester, _strainLabels(laminate).first), '.001');
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name starts a separate new screen with empty drafts',
        (tester) async {
      await _open(tester, laminate);
      await _enter(tester, _stressLabels(laminate).first, '99.0');
      await _switch(tester, laminate, strain: true);
      await _enter(tester, _strainLabels(laminate).first, '1e-');
      await _back(tester);
      await _tap(tester, find.text('Open calculator'));
      _expectTexts(tester, _stressLabels(laminate), List.filled(count, ''));
      await _switch(tester, laminate, strain: true);
      _expectTexts(tester, _strainLabels(laminate), List.filled(count, ''));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name modes fit a narrow screen with large text',
        (tester) async {
      await _open(tester, laminate, size: const Size(320, 700), scale: 2);
      await _enter(tester, _stressLabels(laminate).first, '100');
      await _switch(tester, laminate, strain: true);
      await _enter(tester, _strainLabels(laminate).first, '.001');
      await _switch(tester, laminate, strain: false);
      expect(_text(tester, _stressLabels(laminate).first), '100');
    });
  }

  testWidgets(
      'lamina analysis changes recreate the row without losing either draft',
      (tester) async {
    await _open(tester, false);
    await _fill(tester, _stressLabels(false), _stressText.take(3));
    await _switch(tester, false, strain: true);
    await _fill(tester, _strainLabels(false), _strainText.take(3));
    final oldRowState = tester.state(find.byType(PlaneStressStrainRow));
    await _tap(tester, find.byType(DropdownButton<AnalysisType>));
    await _tap(tester, find.text(AnalysisType.thermalElastic.name).last);
    expect(oldRowState.mounted, isFalse);
    _expectTexts(tester, _strainLabels(false), _strainText.take(3));
    await _switch(tester, false, strain: false);
    _expectTexts(tester, _stressLabels(false), _stressText.take(3));
    await _tap(tester, find.byType(DropdownButton<AnalysisType>));
    await _tap(tester, find.text(AnalysisType.elastic.name).last);
    _expectTexts(tester, _stressLabels(false), _stressText.take(3));
    await _switch(tester, false, strain: true);
    _expectTexts(tester, _strainLabels(false), _strainText.take(3));
    expect(tester.takeException(), isNull);
  });
}

List<String> _stressLabels(bool laminate, {bool us = false}) => laminate
    ? [
        for (final component in ['N11', 'N22', 'N12'])
          '$component (${us ? 'kip/in' : 'N/mm'})',
        for (final component in ['M11', 'M22', 'M12'])
          '$component (${us ? 'kip·in/in' : 'N·mm/mm'})'
      ]
    : [
        for (final component in ['σ11', 'σ22', 'σ12'])
          '$component (${us ? 'ksi' : 'MPa'})'
      ];

List<String> _strainLabels(bool laminate, {bool us = false}) => laminate
    ? [
        'ϵ11',
        'ϵ22',
        'ϵ12',
        for (final component in ['𝞳11', '𝞳22', '𝞳12'])
          '$component (${us ? '1/in' : '1/mm'})'
      ]
    : ['ε11', 'ε22', 'γ12 (2ε12)'];

Finder _field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);
Finder _row(bool laminate) =>
    find.byType(laminate ? LaminateStressStrainRow : PlaneStressStrainRow);
Finder _dropdown(bool laminate) => find.descendant(
    of: _row(laminate), matching: find.byType(DropdownButton<String>));
String _text(WidgetTester tester, String label) => tester
    .widget<EditableText>(
        find.descendant(of: _field(label), matching: find.byType(EditableText)))
    .controller
    .text;
MechanicalTensor _tensor(WidgetTester tester, bool laminate) => laminate
    ? tester.widget<LaminateStressStrainRow>(_row(true)).mechanicalTensor
    : tester.widget<PlaneStressStrainRow>(_row(false)).mechanicalTensor;

Object? _reportValue(List<ReportSection> sections, String label) => sections
    .whereType<ValuesSection>()
    .expand((section) => section.entries)
    .firstWhere((entry) => entry.label == label)
    .value;

Future<void> _open(WidgetTester tester, bool laminate,
    {UnitSettings? settings,
    Size size = const Size(1200, 2600),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => NumberPrecisionHelper()),
      if (settings == null)
        ChangeNotifierProvider(create: (_) => UnitSettings())
      else
        ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
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
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => laminate
                            ? const LaminateStressStrainPage()
                            : LaminaStressStrainPage())),
                child: const Text('Open calculator'),
              ))),
    ),
  ));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Open calculator'));
}

Future<void> _prepareCalculation(WidgetTester tester, bool laminate) async {
  await _tap(tester, find.text('Library'));
  await _tap(tester, find.text('T300/5208 carbon/epoxy'));
  if (laminate) {
    await _enter(tester, '[xx/xx/xx/xx]msn', '[0/90]s');
    await _enter(tester, 'Thickness (mm)', '0.125');
  } else {
    await _enter(tester, '(-90 <= Angle <= 90)', '0');
  }
}

Future<void> _fill(
    WidgetTester tester, List<String> labels, Iterable<String> values) async {
  final text = values.toList();
  for (var index = 0; index < labels.length; index++) {
    await _enter(tester, labels[index], text[index]);
  }
}

void _expectTexts(
    WidgetTester tester, List<String> labels, Iterable<String> values) {
  final text = values.toList();
  for (var index = 0; index < labels.length; index++) {
    expect(_text(tester, labels[index]), text[index], reason: labels[index]);
  }
}

Future<void> _switch(WidgetTester tester, bool laminate,
    {required bool strain}) async {
  await _tap(tester, _dropdown(laminate));
  await _tap(
      tester,
      find
          .text(laminate
              ? (strain ? 'Plate Strains/Curvatures' : 'Stress Resultants')
              : (strain ? 'Strain' : 'Stress'))
          .last);
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await _tap(tester, _field(label));
  await tester.enterText(_field(label), text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) =>
    _tap(tester, find.byIcon(Icons.arrow_back_ios_outlined));
Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
