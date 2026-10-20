import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/calculator_result_validation.dart';
import 'package:swiftcomp/presentation/tools/model/lamina_engineering_sweep.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/thermal_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_page.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_engineering_constants_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_engineering_constants_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/widget/result_3by3_matrix.dart';
import 'package:swiftcomp/presentation/tools/widget/transversely_thermal_constants_row.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

TransverselyIsotropicMaterial _material(Units units) =>
    TransverselyIsotropicMaterial()
      ..e1 = units.modulusFromGPa(181)
      ..e2 = units.modulusFromGPa(10.3)
      ..g12 = units.modulusFromGPa(7.17)
      ..nu12 = 0.28
      ..nu23 = 0.4;

TransverselyIsotropicCTE _cte(Units units) => TransverselyIsotropicCTE()
  ..alpha11 = units.cteFromPerC(-0.1e-6)
  ..alpha22 = units.cteFromPerC(30e-6)
  ..alpha12 = 0;

UDFRCRulesOfMixtureInput _mixture(Units units, AnalysisType analysisType) =>
    UDFRCRulesOfMixtureInput(
      analysisType: analysisType,
      E1_fiber: units.modulusFromGPa(230),
      E2_fiber: units.modulusFromGPa(15),
      G12_fiber: units.modulusFromGPa(15),
      nu12_fiber: 0.2,
      nu23_fiber: 0.25,
      E_matrix: units.modulusFromGPa(3.5),
      nu_matrix: 0.35,
      fiberVolumeFraction: 0.6,
      alpha11_fiber: units.cteFromPerC(-0.1e-6),
      alpha22_fiber: units.cteFromPerC(10e-6),
      alpha_matrix: units.cteFromPerC(-2e-6),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  for (final units in [Units.si, Units.us]) {
    for (final analysisType in [
      AnalysisType.elastic,
      AnalysisType.thermalElastic
    ]) {
      test('lamina guard accepts ${analysisType.name} ${units.name} outputs',
          () {
        for (final tensorType in [TensorType.stress, TensorType.strain]) {
          final input = LaminaStressStrainInput(
            analysisType: analysisType,
            E1: units.modulusFromGPa(181) * Units.modulusToStress,
            E2: units.modulusFromGPa(10.3) * Units.modulusToStress,
            G12: units.modulusFromGPa(7.17) * Units.modulusToStress,
            nu12: 0.28,
            layupAngle: 30,
            tensorType: tensorType,
            sigma11: units.stressFromMPa(100),
            epsilon11: 0.001,
            alpha11: units.cteFromPerC(-0.1e-6),
            alpha22: units.cteFromPerC(30e-6),
            alpha12: 0,
            deltaT: units.isSI ? -50 : -90,
          );
          final output = LaminaStressStrainCalculator.calculate(input);
          expect(CalculatorResultValidation.laminaStressStrain(output), isTrue,
              reason: tensorType.name);
        }
      });

      test('engineering sweep accepts ${analysisType.name} ${units.name}', () {
        final sweep = LaminaEngineeringSweep.calculate(
          analysisType: analysisType,
          material: _material(units),
          cte: _cte(units),
        );
        expect(sweep.results, hasLength(181));
        expect(
            sweep.results
                .every(CalculatorResultValidation.engineeringConstants),
            isTrue);
        expect(sweep.atAngle(-90), same(sweep.results.first));
        expect(sweep.atAngle(90), same(sweep.results.last));
        expect(sweep.atAngle(0).E1, greaterThan(0));
      });

      test('mixture guard accepts ${analysisType.name} ${units.name} outputs',
          () {
        final output = UDFRCRulesOfMixtureCalculator.calculate(
            _mixture(units, analysisType));
        expect(CalculatorResultValidation.rulesOfMixture(output), isTrue);
        output.hybirdRulesOfMixture.stiffness[0][0] = double.infinity;
        expect(CalculatorResultValidation.rulesOfMixture(output), isFalse);
      });
    }
  }

  test('remaining guards reject overflow from finite calculator inputs', () {
    final laminaInput = LaminaStressStrainInput(
      E1: 181000,
      E2: 10300,
      G12: 7170,
      nu12: 0.28,
      tensorType: TensorType.strain,
      epsilon11: 1e308,
    );
    final laminaOutput = LaminaStressStrainCalculator.calculate(laminaInput);
    expect(
        CalculatorResultValidation.laminaStressStrain(laminaOutput), isFalse);

    final mixtureInput = _mixture(Units.si, AnalysisType.thermalElastic)
      ..alpha11_fiber = 1e308
      ..alpha22_fiber = -1e308;
    final mixtureOutput = UDFRCRulesOfMixtureCalculator.calculate(mixtureInput);
    expect(CalculatorResultValidation.rulesOfMixture(mixtureOutput), isFalse);

    expect(
      () => LaminaEngineeringSweep.calculate(
        analysisType: AnalysisType.thermalElastic,
        material: _material(Units.si),
        cte: _cte(Units.si)
          ..alpha11 = 1e308
          ..alpha22 = -1e308,
      ),
      throwsA(anything),
    );
  });

  test('engineering sweep rejects a singular material before results open', () {
    expect(
      () => LaminaEngineeringSweep.calculate(
        analysisType: AnalysisType.elastic,
        material: TransverselyIsotropicMaterial()
          ..e1 = 1
          ..e2 = 1
          ..g12 = 1
          ..nu12 = 1,
        cte: TransverselyIsotropicCTE(),
      ),
      throwsA(anything),
    );
  });

  testWidgets(
      'engineering recovers from singular and overflow inputs; slider uses sweep',
      (tester) async {
    await _prepare(tester, const LaminaEngineeringConstantsPage());
    await _fillLamina(tester);
    for (final label in ['E1 (GPa)', 'E2 (GPa)', 'G12 (GPa)', 'ν12']) {
      await _enter(tester, label, '1');
    }
    await _calculateError(tester, LaminaEngineeringConstantsPage,
        LaminaEngineeringConstantsResultPage);
    expect(_fieldText(tester, 'ν12'), '1');
    await _fillLamina(tester);
    await _thermal(tester);
    await _enter(tester, 'ɑ11 (1/°C)', '1e308');
    await _enter(tester, 'ɑ22 (1/°C)', '-1e308');
    await _enter(tester, 'ɑ12 (1/°C)', '0');
    await _calculateError(tester, LaminaEngineeringConstantsPage,
        LaminaEngineeringConstantsResultPage);
    expect(_fieldText(tester, 'ɑ11 (1/°C)'), '1e308');
    await _enter(tester, 'ɑ11 (1/°C)', '-1e-7');
    await _enter(tester, 'ɑ22 (1/°C)', '3e-5');
    await _tap(tester, find.text('Calculate'));
    final page = tester.widget<LaminaEngineeringConstantsResultPage>(
        find.byType(LaminaEngineeringConstantsResultPage));
    expect(page.sweep.results, hasLength(181));
    for (final angle in [-90, 90]) {
      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.drag(slider, Offset(angle < 0 ? -2000 : 2000, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).value, angle.toDouble());
      final q = tester
          .widgetList<Result3By3Matrix>(find.byType(Result3By3Matrix))
          .first
          .matrixList;
      expect(q, same(page.sweep.atAngle(angle).Q));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'lamina stress recovers from singular and finite overflow without losing inputs',
      (tester) async {
    await _prepare(tester, LaminaStressStrainPage());
    await _fillLamina(tester);
    await _enter(tester, '(-90 <= Angle <= 90)', '30');
    for (final label in ['σ11 (MPa)', 'σ22 (MPa)', 'σ12 (MPa)']) {
      await _enter(tester, label, label.startsWith('σ11') ? '100' : '0');
    }
    for (final label in ['E1 (GPa)', 'E2 (GPa)', 'G12 (GPa)', 'ν12']) {
      await _enter(tester, label, '1');
    }
    await _calculateError(
        tester, LaminaStressStrainPage, LaminaStressStrainResult);
    expect(_fieldText(tester, 'σ11 (MPa)'), '100');
    expect(_fieldText(tester, '(-90 <= Angle <= 90)'), '30');
    await _fillLamina(tester);
    await _tap(tester, find.byType(DropdownButton<String>));
    await _tap(tester, find.text('Strain').last);
    await _enter(tester, 'ε11', '1e308');
    await _enter(tester, 'ε22', '0');
    await _enter(tester, 'γ12 (2ε12)', '0');
    await _calculateError(
        tester, LaminaStressStrainPage, LaminaStressStrainResult);
    expect(_fieldText(tester, 'ε11'), '1e308');
    await _enter(tester, 'ε11', '0.001');
    await _tap(tester, find.text('Calculate'));
    expect(find.byType(LaminaStressStrainResult), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thermal lamina requires finite temperature and accepts cooling',
      (tester) async {
    await _prepare(tester, LaminaStressStrainPage());
    await _fillLamina(tester);
    await _thermal(tester);
    await _enter(tester, 'ɑ11 (1/°C)', '-1e-7');
    await _enter(tester, 'ɑ22 (1/°C)', '3e-5');
    await _enter(tester, 'ɑ12 (1/°C)', '0');
    await _enter(tester, '(-90 <= Angle <= 90)', '0');
    for (final label in ['σ11 (MPa)', 'σ22 (MPa)', 'σ12 (MPa)']) {
      await _enter(tester, label, label.startsWith('σ11') ? '100' : '0');
    }
    for (final text in ['', 'NaN']) {
      await _enter(tester, 'ΔT (°C)', text);
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(LaminaStressStrainResult), findsNothing);
      expect(find.text('Enter a finite number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await _enter(tester, 'ΔT (°C)', '-50');
    await _tap(tester, find.text('Calculate'));
    final result = tester.widget<LaminaStressStrainResult>(
        find.byType(LaminaStressStrainResult));
    expect(
        CalculatorResultValidation.laminaStressStrain(result.output), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mixture recovers from singular and overflow material while retaining inputs',
      (tester) async {
    await _prepare(tester, const RulesOfMixturePage());
    await _fillMixture(tester);
    await _enter(tester, 'ν23', '-1');
    await _calculateError(tester, RulesOfMixturePage, RulesOfMixtureResultPage);
    expect(_fieldText(tester, 'Volume Fraction (0.0 ~ 1.0)'), '0.6');
    await _enter(tester, 'ν23', '0.25');
    await _enter(tester, 'E (GPa)', '1e-320');
    await _calculateError(tester, RulesOfMixturePage, RulesOfMixtureResultPage);
    expect(_fieldText(tester, 'E (GPa)'), '1e-320');
    await _enter(tester, 'E (GPa)', '3.5');
    await _tap(tester, find.text('Calculate'));
    expect(find.byType(RulesOfMixtureResultPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final matrixCte in ['0', '-2e-6']) {
    testWidgets(
        'thermal mixture accepts matrix CTE $matrixCte without hidden fiber shear CTE',
        (tester) async {
      await _prepare(tester, const RulesOfMixturePage());
      await _fillMixture(tester);
      await _thermal(tester);
      await _enter(tester, 'ɑ11 (1/°C)', '-1e-7');
      await _enter(tester, 'ɑ22 (1/°C)', '1e-5');
      await _enter(tester, 'ɑ (1/°C)', matrixCte);
      final fiberCte = tester.widget<TransverselyThermalConstantsRow>(
          find.byType(TransverselyThermalConstantsRow));
      expect(fiberCte.shouldConsider12, isFalse);
      expect(fiberCte.material.alpha12, isNull);
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(RulesOfMixtureResultPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget page) => MultiProvider(
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
        home: page,
      ),
    );

Future<void> _prepare(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1600, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(page));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

String _fieldText(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller?.text ??
    tester
        .widget<EditableText>(find.descendant(
            of: _field(label), matching: find.byType(EditableText)))
        .controller
        .text;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await _tap(tester, _field(label));
  await tester.enterText(_field(label), text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _fillLamina(WidgetTester tester) async {
  for (final entry in {
    'E1 (GPa)': '181',
    'E2 (GPa)': '10.3',
    'G12 (GPa)': '7.17',
    'ν12': '0.28'
  }.entries) {
    await _enter(tester, entry.key, entry.value);
  }
}

Future<void> _fillMixture(WidgetTester tester) async {
  for (final entry in {
    'E1 (GPa)': '230',
    'E2 (GPa)': '15',
    'G12 (GPa)': '15',
    'ν12': '0.2',
    'ν23': '0.25',
    'E (GPa)': '3.5',
    'ν': '0.35',
    'Volume Fraction (0.0 ~ 1.0)': '0.6'
  }.entries) {
    await _enter(tester, entry.key, entry.value);
  }
}

Future<void> _thermal(WidgetTester tester) async {
  await _tap(tester, find.byType(DropdownButton<AnalysisType>));
  await _tap(tester, find.text(AnalysisType.thermalElastic.name).last);
}

Future<void> _calculateError(
    WidgetTester tester, Type page, Type result) async {
  await _tap(tester, find.text('Calculate'));
  expect(find.byType(result), findsNothing);
  final strings = S.of(tester.element(find.byType(page)));
  expect(find.text(strings.Calculator_calculation_failed), findsOneWidget);
  expect(tester.takeException(), isNull);
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .clearSnackBars();
  await tester.pumpAndSettle();
}
