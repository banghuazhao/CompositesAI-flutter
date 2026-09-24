import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/thermal_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';
import 'package:swiftcomp/presentation/tools/widget/number_field.dart';
import 'package:swiftcomp/util/others.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  group('Units', () {
    test('converts SI values to US customary', () {
      const us = Units.us;
      expect(us.modulusFromGPa(6.894757293168361), closeTo(1, 1e-12));
      expect(us.stressFromMPa(689.4757293168361), closeTo(100, 1e-9));
      expect(us.lengthFromMm(25.4), closeTo(1, 1e-12));
      expect(us.cteFromPerC(1.8e-6), closeTo(1e-6, 1e-18));
      expect(us.modulusToGPa(us.modulusFromGPa(181)), closeTo(181, 1e-9));
    });

    test('SI is the identity', () {
      const si = Units.si;
      expect(si.modulusFromGPa(181), 181);
      expect(si.stressFromMPa(1500), 1500);
      expect(si.cteFromPerC(22.5e-6), 22.5e-6);
    });

    test('settings persist the chosen system', () async {
      final settings = UnitSettings();
      expect(settings.system, UnitSystem.si);
      var notified = false;
      settings.addListener(() => notified = true);
      await settings.setSystem(UnitSystem.us);
      expect(notified, isTrue);
      expect(UnitSettings().system, UnitSystem.us);
      expect(UnitSettings().units.modulus, 'Msi');
    });

    test('flags moduli typed in the wrong unit', () {
      expect(validateModulusIn(181, Units.si), isNull);
      expect(validateModulusIn(181000, Units.si), contains('GPa'));
      expect(validateModulusIn(26, Units.us), isNull);
      expect(validateModulusIn(26000000, Units.us), contains('Msi'));
    });
  });

  group('MaterialLibrary', () {
    test('built-in entries are complete for their kind', () {
      for (final material in builtInMaterials) {
        expect(material.e1, greaterThan(0), reason: material.name);
        if (material.kind != MaterialKind.matrix) {
          expect(material.e2, isNotNull, reason: material.name);
          expect(material.g12, isNotNull, reason: material.name);
        }
        if (material.kind == MaterialKind.lamina) {
          expect(material.hasStrengths, isTrue, reason: material.name);
        }
        expect(material.source, isNotEmpty, reason: material.name);
      }
      final ids = builtInMaterials.map((m) => m.id).toSet();
      expect(ids.length, builtInMaterials.length);
    });

    test('applies values in the selected units', () {
      final t300 = builtInMaterials.firstWhere((m) => m.id == 't300-5208');
      final lamina = TransverselyIsotropicMaterial();
      final cte = TransverselyIsotropicCTE();
      final strengths = LaminaStrengths();

      t300
        ..applyToLamina(lamina, Units.us)
        ..applyCte(cte, Units.us)
        ..applyStrengths(strengths, Units.us);

      expect(lamina.e1, closeTo(26.25, 0.01)); // Msi
      expect(lamina.nu12, 0.28);
      expect(lamina.nu23, isNull);
      expect(cte.alpha22, closeTo(12.5e-6, 1e-9)); // 1/°F
      expect(cte.alpha12, 0);
      expect(strengths.xt, closeTo(217.6, 0.1)); // ksi
      expect(strengths.isValid(), isTrue);
    });

    test('saves, reloads and removes custom materials', () async {
      final saved = LibraryMaterial.fromLaminaInputs(
        name: 'My prepreg',
        units: Units.us,
        material: TransverselyIsotropicMaterial()
          ..e1 = 20
          ..e2 = 1.5
          ..g12 = 0.8
          ..nu12 = 0.3,
      );
      expect(saved, isNotNull);
      await MaterialLibrary.instance.save(saved!);

      final raw = SharedPreferencesHelper.localStorage
          .getString('Custom_Materials_v1');
      final stored = (jsonDecode(raw!) as List).single as Map;
      expect(stored['e1'], closeTo(137.9, 0.01)); // stored in GPa

      MaterialLibrary.instance.resetForTest();
      final reloaded = MaterialLibrary.instance.materials(MaterialKind.lamina);
      expect(reloaded.first.name, 'My prepreg');
      expect(reloaded.first.isCustom, isTrue);

      await MaterialLibrary.instance.remove(reloaded.first);
      expect(MaterialLibrary.instance.customMaterials, isEmpty);
    });

    test('incomplete inputs cannot be saved', () {
      expect(
        LibraryMaterial.fromLaminaInputs(
          name: 'Incomplete',
          units: Units.si,
          material: TransverselyIsotropicMaterial()..e1 = 100,
        ),
        isNull,
      );
    });
  });

  group('formatInputNumber', () {
    test('keeps inputs readable', () {
      expect(formatInputNumber(null), '');
      expect(formatInputNumber(181), '181');
      expect(formatInputNumber(0.28), '0.28');
      expect(formatInputNumber(26.251741), '26.2517');
      expect(formatInputNumber(22.5e-6), '2.25e-5');
      expect(formatInputNumber(-1e-6), '-1e-6');
    });
  });

  group('CalcReport', () {
    CalcReport report() => CalcReport(
          title: 'Laminate plate properties',
          units: Units.si,
          createdAt: DateTime(2026, 9, 24),
          inputs: const [
            ValuesSection('Layup', [
              ReportEntry('Layup sequence', '[0/90]s'),
              ReportEntry('Ply thickness', 0.125, 'mm'),
            ]),
          ],
          results: const [
            MatrixSection(
              'A Matrix',
              [
                [1.0, 2.0, 0.0],
                [2.0, 1.0, 0.0],
                [0.0, 0.0, 3.0],
              ],
              unit: 'N/mm',
            ),
            TableSection(
              'Plies',
              headers: ['Ply', 'Note'],
              rows: [
                [1, 'a, "quoted" note'],
              ],
            ),
            ChartSection(
              'Stress',
              xLabel: 'z (mm)',
              yLabel: 'σ (MPa)',
              series: [
                ChartSeries('σ11', [(-0.25, -10.0), (0.25, 10.0)]),
              ],
            ),
          ],
          notes: ['Symmetric laminates only.'],
        );

    test('CSV contains every section and escapes text', () {
      final csv = report().toCsv();
      expect(csv, startsWith('\uFEFFLaminate plate properties\r\n'));
      expect(csv, contains('Units,SI (GPa · MPa · mm)'));
      expect(csv, contains('Input: Layup'));
      expect(csv, contains('Layup sequence,[0/90]s,'));
      expect(csv, contains('Result: A Matrix\r\nUnit,N/mm\r\n'));
      expect(csv, contains('Unit,N/mm\r\n1,2,0\r\n'));
      expect(csv, contains('-0.25,-10'));
      expect(csv, contains('1,"a, ""quoted"" note"'));
      expect(csv, contains('z (mm),σ (MPa)'));
      expect(csv, contains('Symmetric laminates only.'));
    });

    test('PDF export produces a document', () async {
      final bytes = await report().toPdf();
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
