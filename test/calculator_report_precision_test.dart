import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';

import 'support/pdf_fixture_writer.dart';

const _value = 1.23456789123456;

CalcReport _report(Units units) => CalcReport(
      title: 'Laminate failure precision review',
      units: units,
      createdAt: DateTime(2026, 10, 20, 12),
      inputs: [
        ValuesSection('Loading', [
          ReportEntry('Applied load', _value, units.forceResultant),
          ReportEntry('Ply thickness', units.lengthFromMm(0.125), units.length),
        ]),
      ],
      results: [
        ValuesSection('Selected values', [
          ReportEntry('Precision check', _value),
          ReportEntry('Unloaded ratio', double.infinity),
          ReportEntry('Zero load', 0.0),
        ]),
        MatrixSection(
            'Stiffness',
            [
              [_value, -_value, 0],
              [-_value, _value, 0],
              [0, 0, _value],
            ],
            unit: units.modulus),
        TableSection(
          'Ply stresses and failure indices',
          headers: [
            'Ply',
            'Angle (°)',
            'Surface',
            'z (${units.length})',
            'σ1 (${units.stress})',
            'σ2 (${units.stress})',
            'τ12 (${units.stress})',
            'FI Max Stress',
            'FI Tsai-Hill',
            'FI Tsai-Wu',
            'FI Hashin',
          ],
          rows: [
            for (var row = 0; row < 32; row++)
              [
                row ~/ 2 + 1,
                row.isEven ? 45 : -45,
                row.isEven ? 'Bottom' : 'Top',
                units.lengthFromMm((row - 16) * 0.125),
                units.stressFromMPa(123456.789123456),
                units.stressFromMPa(-123456.789123456),
                units.stressFromMPa(0.0000123456789123456),
                _value,
                _value / 10,
                _value * 100,
                0.0,
              ],
          ],
        ),
      ],
      notes: const ['Every ply surface is retained in the exported report.'],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('display precision is safe at all supported and invalid boundaries', () {
    expect(CalcReport.formatNumber(_value, precision: 1), '1.2e+0');
    expect(CalcReport.formatNumber(_value, precision: 9), '1.234567891e+0');
    expect(CalcReport.formatNumber(_value, precision: -100), '1.2e+0');
    expect(CalcReport.formatNumber(_value, precision: 1000), '1.234567891e+0');
    expect(CalcReport.formatNumber(0), '0');
    expect(CalcReport.formatNumber(90), '90');
    expect(CalcReport.formatNumber(double.infinity), '∞');
  });

  // Flutter's Chrome unit-test runner does not answer the application asset
  // channel used by bundled PDF fonts. VM tests cover these font/layout paths.
  for (final units in [Units.si, Units.us]) {
    for (final precision in [1, 9]) {
      test('${units.name} PDF supports precision $precision in wide tables',
          () async {
        final report = _report(units);
        final csv = report.toCsv();
        final clipboard = report.toClipboardText();
        final bytes = await report.toPdf(precision: precision);
        expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
        expect(report.toCsv(), csv);
        expect(report.toClipboardText(), clipboard);
        expect(csv, contains(_value.toString()));
        expect(clipboard, contains(_value.toString()));
        expect((report.results.last as TableSection).rows, hasLength(32));
        if (const bool.fromEnvironment('CAPTURE_PDF_QA')) {
          await writePdfFixture('${units.system.name}-$precision', bytes);
        }
      }, testOn: 'vm');
    }
  }

  test('PDF generation also normalizes invalid caller precision', () async {
    for (final precision in [-100, 1000]) {
      final bytes = await _report(Units.si).toPdf(precision: precision);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    }
  }, testOn: 'vm');
}
