import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/calculator_result_validation.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_3d_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_3d_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_result_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

const _calculators = [
  (
    name: 'plate',
    page: LaminatePlatePropertiesPage(),
    result: LaminatePlatePropertiesResultPage,
  ),
  (
    name: 'stress/strain',
    page: LaminateStressStrainPage(),
    result: LaminateStressStrainResultPage,
  ),
  (
    name: '3D',
    page: Laminate3DPropertiesPage(),
    result: Laminate3DPropertiesResultPage,
  ),
  (
    name: 'failure',
    page: LaminateFailurePage(),
    result: LaminateFailureResultPage,
  ),
];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  for (final calculator in _calculators) {
    testWidgets('${calculator.name} blocks invalid thickness and recovers',
        (tester) async {
      await _prepare(tester, calculator.page);
      final strings =
          S.of(tester.element(find.byType(calculator.page.runtimeType)));
      for (final text in ['', '0', '-0.125', 'NaN', 'Infinity', '-Infinity']) {
        await _enter(tester, 'Thickness (mm)', text);
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(calculator.result), findsNothing, reason: text);
        final expectedError = text == '0' || text.startsWith('-0.')
            ? strings.Calculator_positive_thickness
            : strings.Calculator_finite_thickness;
        expect(find.text(expectedError), findsOneWidget, reason: text);
        expect(tester.takeException(), isNull, reason: text);
      }

      await _enter(tester, 'Thickness (mm)', '0.125');
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(calculator.result), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    if (calculator.name != '3D') {
      testWidgets(
          '${calculator.name} handles extreme positive thickness safely',
          (tester) async {
        await _prepare(tester, calculator.page);
        for (final text in ['1e-200', '1e200']) {
          await _enter(tester, 'Thickness (mm)', text);
          await _tap(tester, find.text('Calculate'));
          expect(find.byType(calculator.result), findsNothing, reason: text);
          _expectCalculationError(tester, calculator.page.runtimeType);
          expect(tester.takeException(), isNull, reason: text);
          await _clearSnackBars(tester);
        }

        await _enter(tester, 'Thickness (mm)', '0.125');
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(calculator.result), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('${calculator.name} handles singular material and recovers',
        (tester) async {
      await _prepare(tester, calculator.page);
      await _enter(tester, 'Thickness (mm)', '0.125');
      if (calculator.name == '3D') {
        await _enter(tester, 'ν23', '-1');
      } else {
        for (final label in ['E1 (GPa)', 'E2 (GPa)', 'G12 (GPa)', 'ν12']) {
          await _enter(tester, label, '1');
        }
      }
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(calculator.result), findsNothing);
      _expectCalculationError(tester, calculator.page.runtimeType);
      expect(tester.takeException(), isNull);
      await _clearSnackBars(tester);

      await _selectLibraryMaterial(tester);
      await _tap(tester, find.text('Calculate'));
      expect(find.byType(calculator.result), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('stress chart validation rejects overflow from otherwise finite values',
      () {
    final input = LaminarStressStrainInput(
      tensorType: TensorType.strain,
      layerThickness: 0.125,
      epsilon11: 1e308,
    );
    final output = LaminarStressStrainOutput();
    final q = Matrix([
      [2, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ]);
    expect(
        CalculatorResultValidation.stressStrain(input, output, [q]), isFalse);
  });

  test(
      'failure validation allows unloaded ratios but blocks non-finite indices',
      () {
    final result = LaminateFailureResult(
      points: [
        PlyStressPoint(
          ply: 1,
          angle: 0,
          isTop: false,
          z: -0.0625,
          globalStress: [0, 0, 0],
          materialStress: [0, 0, 0],
          results: {
            for (final criterion in FailureCriterion.values)
              criterion: const CriterionResult(double.infinity, 'Unloaded'),
          },
        ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );
    expect(CalculatorResultValidation.failure(result), isTrue);
    for (final ratio in [0.0, 1e-320]) {
      result.points.single.results[FailureCriterion.maxStress] =
          CriterionResult(ratio, 'Fiber tension');
      expect(CalculatorResultValidation.failure(result), isFalse,
          reason:
              'A strength ratio of $ratio gives an infinite failure index.');
    }
    result.points.single.results[FailureCriterion.maxStress] =
        const CriterionResult(double.infinity, 'Unloaded');
    expect(CalculatorResultValidation.failure(result), isTrue);
    result.points.single.materialStress[0] = double.nan;
    expect(CalculatorResultValidation.failure(result), isFalse);
  });
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
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(page));
  await tester.pumpAndSettle();
  await _selectLibraryMaterial(tester);
  await _enter(tester, '[xx/xx/xx/xx]msn', '[0/90]s');
  if (page is LaminateStressStrainPage) {
    for (final label in [
      'N11 (N/mm)',
      'N22 (N/mm)',
      'N12 (N/mm)',
      'M11 (N·mm/mm)',
      'M22 (N·mm/mm)',
      'M12 (N·mm/mm)'
    ]) {
      await _enter(tester, label, label.startsWith('N11') ? '100' : '0');
    }
  } else if (page is LaminateFailurePage) {
    await _enter(tester, 'N11 (N/mm)', '100');
  }
}

Future<void> _selectLibraryMaterial(WidgetTester tester) async {
  await _tap(tester, find.text('Library'));
  await _tap(tester, find.text('T300/5208 carbon/epoxy'));
  // T300/5208 has no published ν23 in this library entry. Fill the required
  // 3D-only field explicitly after selection, including recovery selections.
  final nu23 = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'ν23');
  if (nu23.evaluate().isNotEmpty) {
    await _enter(tester, 'ν23', '0.4');
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label);
  await _tap(tester, field);
  await tester.enterText(field, text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void _expectCalculationError(WidgetTester tester, Type pageType) {
  final strings = S.of(tester.element(find.byType(pageType)));
  expect(find.text(strings.Calculator_calculation_failed), findsOneWidget);
}

Future<void> _clearSnackBars(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .clearSnackBars();
  await tester.pumpAndSettle();
}
