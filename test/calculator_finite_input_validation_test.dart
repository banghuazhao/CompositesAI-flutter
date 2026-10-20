import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/angle_model.dart';
import 'package:swiftcomp/presentation/tools/model/delta_t.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/delta_temperature_row.dart';
import 'package:swiftcomp/presentation/tools/widget/laminate_stress_strain_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_angle_row.dart';
import 'package:swiftcomp/presentation/tools/widget/plane_stress_strain_row.dart';
import 'package:swiftcomp/util/others.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) =>
    ChangeNotifierProvider(
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
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
  });

  test('angle and temperature reject nonfinite values without new range limits',
      () {
    final angle = LayupAngle();
    final temperature = DeltaTemperature();
    for (final invalid in <double?>[
      null,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      angle.value = invalid;
      temperature.value = invalid;
      expect(angle.isValid(), isFalse, reason: '$invalid');
      expect(temperature.isValid(), isFalse, reason: '$invalid');
    }
    for (final valid in [-360.0, -90.0, -1e-300, 0.0, 90.0, 360.0, 1e300]) {
      angle.value = valid;
      temperature.value = valid;
      expect(angle.isValid(), isTrue, reason: '$valid');
      expect(temperature.isValid(), isTrue, reason: '$valid');
    }
  });

  final tensors = <({
    String name,
    int length,
    MechanicalTensor Function(List<double?>) create,
  })>[
    (
      name: 'plane stress',
      length: 3,
      create: (v) => PlaneStress.from(v[0], v[1], v[2]),
    ),
    (
      name: 'plane strain',
      length: 3,
      create: (v) => PlaneStrain.from(v[0], v[1], v[2]),
    ),
    (
      name: 'laminate stress',
      length: 6,
      create: (v) => LaminateStress.from(v[0], v[1], v[2], v[3], v[4], v[5]),
    ),
    (
      name: 'laminate strain',
      length: 6,
      create: (v) => LaminateStrain.from(v[0], v[1], v[2], v[3], v[4], v[5]),
    ),
  ];

  for (final tensor in tensors) {
    test('${tensor.name} requires every component to be finite', () {
      expect(tensor.create(List.filled(tensor.length, 0)).isValid(), isTrue);
      expect(
          tensor.create(List.filled(tensor.length, -1.25)).isValid(), isTrue);
      for (var component = 0; component < tensor.length; component++) {
        for (final invalid in <double?>[
          null,
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          final values = List<double?>.filled(tensor.length, 0);
          values[component] = invalid;
          expect(tensor.create(values).isValid(), isFalse,
              reason: 'component $component: $invalid');
        }
      }
    });
  }

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('angle finite errors are localized in $locale and recover live',
        (tester) async {
      final angle = LayupAngle();
      await tester.pumpWidget(app(
        LayupAngleRow(layupAngle: angle, validate: true),
        locale: locale,
      ));
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(find.byType(LayupAngleRow)));

      for (final text in ['NaN', 'Infinity', '-Infinity']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(angle.isValid(), isFalse);
        expect(find.text(strings.Calculator_finite_thickness), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), '-180');
      await tester.pump();
      expect(angle.value, -180);
      expect(angle.isValid(), isTrue);
      expect(find.text(strings.Calculator_finite_thickness), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('temperature finite errors recover for negative and zero values',
      (tester) async {
    final temperature = DeltaTemperature();
    await tester.pumpWidget(app(
        DeltaTemperatureRow(deltaTemperature: temperature, validate: true)));
    await tester.pumpAndSettle();
    for (final text in ['NaN', 'Infinity', '-Infinity']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(temperature.isValid(), isFalse);
      expect(find.text('Enter a finite number'), findsOneWidget);
    }
    for (final text in ['-50', '0']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(temperature.isValid(), isTrue);
      expect(find.text('Enter a finite number'), findsNothing);
    }
  });

  for (final laminate in [false, true]) {
    testWidgets(
        '${laminate ? 'laminate' : 'plane'} inputs reject nonfinite components in both modes',
        (tester) async {
      MechanicalTensor tensor = laminate
          ? LaminateStress.from(0, 0, 0, 0, 0, 0)
          : PlaneStress.from(0, 0, 0);
      await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) {
          void changeMode(String mode) {
            setState(() {
              tensor = laminate
                  ? (mode == 'Stress Resultants'
                      ? LaminateStress.from(0, 0, 0, 0, 0, 0)
                      : LaminateStrain.from(0, 0, 0, 0, 0, 0))
                  : (mode == 'Stress'
                      ? PlaneStress.from(0, 0, 0)
                      : PlaneStrain.from(0, 0, 0));
            });
          }

          return laminate
              ? LaminateStressStrainRow(
                  mechanicalTensor: tensor,
                  validate: true,
                  callback: changeMode)
              : PlaneStressStrainRow(
                  mechanicalTensor: tensor,
                  validate: true,
                  callback: changeMode);
        },
      )));
      await tester.pumpAndSettle();

      for (final strainMode in [false, true]) {
        if (strainMode) {
          await tester.tap(find.byType(DropdownButton<String>));
          await tester.pumpAndSettle();
          await tester.tap(
              find.text(laminate ? 'Plate Strains/Curvatures' : 'Strain').last);
          await tester.pumpAndSettle();
        }
        for (var component = 0; component < (laminate ? 6 : 3); component++) {
          for (final text in ['NaN', 'Infinity', '-Infinity']) {
            await tester.enterText(find.byType(TextField).at(component), text);
            await tester.pump();
            expect(tensor.isValid(), isFalse);
            expect(find.text('Enter a finite number'), findsOneWidget);

            await tester.enterText(find.byType(TextField).at(component),
                component.isEven ? '0' : '-2.5');
            await tester.pump();
            expect(tensor.isValid(), isTrue);
            expect(find.text('Enter a finite number'), findsNothing);
          }
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
