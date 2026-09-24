import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../util/export/pdf_fonts.dart';
import 'material_model.dart';
import 'thermal_model.dart';
import 'unit_system.dart';

/// A labelled value in a report. [value] is a number or text.
class ReportEntry {
  const ReportEntry(this.label, this.value, [this.unit = '']);

  final String label;
  final Object? value;
  final String unit;
}

sealed class ReportSection {
  const ReportSection(this.title);

  final String title;
}

class ValuesSection extends ReportSection {
  const ValuesSection(super.title, this.entries);

  final List<ReportEntry> entries;
}

class MatrixSection extends ReportSection {
  const MatrixSection(super.title, this.values, {this.unit = ''});

  final List<List<double>> values;
  final String unit;
}

class TableSection extends ReportSection {
  const TableSection(super.title, {required this.headers, required this.rows});

  final List<String> headers;

  /// Cells are numbers or text.
  final List<List<Object?>> rows;
}

class ChartSeries {
  const ChartSeries(this.name, this.points);

  final String name;

  /// (x, y) pairs.
  final List<(double, double)> points;
}

class ChartSection extends ReportSection {
  const ChartSection(
    super.title, {
    required this.xLabel,
    required this.yLabel,
    required this.series,
  });

  final String xLabel;
  final String yLabel;
  final List<ChartSeries> series;
}

/// Inputs and results of one calculation, exportable as CSV or PDF.
class CalcReport {
  CalcReport({
    required this.title,
    required this.units,
    this.inputs = const [],
    required this.results,
    this.notes = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String title;
  final Units units;
  final List<ReportSection> inputs;
  final List<ReportSection> results;
  final List<String> notes;
  final DateTime createdAt;

  String get _dateLine => DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

  static String formatNumber(double value, {int precision = 5}) {
    if (value == 0) return '0';
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value > 0 ? '∞' : '-∞';
    // Whole numbers such as ply angles or ply numbers read better plainly.
    if (value == value.roundToDouble() && value.abs() < 1e5) {
      return value.toInt().toString();
    }
    return value.toStringAsExponential(precision);
  }

  static String _cell(Object? value, int precision) {
    if (value == null) return '';
    if (value is double) return formatNumber(value, precision: precision);
    if (value is int) return '$value';
    return value.toString();
  }

  // ---------------------------------------------------------------- CSV

  /// CSV with a UTF-8 byte order mark so spreadsheet apps read symbols such
  /// as ν and · correctly. Numbers keep full precision.
  String toCsv() {
    final rows = <List<String>>[
      [title],
      ['Units', '${units.name} (${units.summary})'],
      ['Generated', 'CompositesAI $_dateLine'],
    ];
    void addSections(String group, List<ReportSection> sections) {
      for (final section in sections) {
        rows
          ..add([])
          ..add(['$group: ${section.title}']);
        switch (section) {
          case ValuesSection(:final entries):
            rows.add(['Quantity', 'Value', 'Unit']);
            for (final entry in entries) {
              rows.add([
                entry.label,
                _csvNumber(entry.value),
                entry.unit,
              ]);
            }
          case MatrixSection(:final values, :final unit):
            if (unit.isNotEmpty) rows.add(['Unit', unit]);
            for (final row in values) {
              rows.add([for (final v in row) _csvNumber(v)]);
            }
          case TableSection(:final headers, rows: final tableRows):
            rows.add(headers);
            for (final row in tableRows) {
              rows.add([for (final v in row) _csvNumber(v)]);
            }
          case ChartSection(:final xLabel, :final yLabel, :final series):
            for (final s in series) {
              rows
                ..add(['Series', s.name])
                ..add([xLabel, yLabel]);
              for (final (x, y) in s.points) {
                rows.add([_csvNumber(x), _csvNumber(y)]);
              }
            }
        }
      }
    }

    addSections('Input', inputs);
    addSections('Result', results);
    if (notes.isNotEmpty) {
      rows
        ..add([])
        ..add(['Notes']);
      for (final note in notes) {
        rows.add([note]);
      }
    }
    return '\uFEFF${rows.map((row) => row.map(_csvEscape).join(',')).join('\r\n')}\r\n';
  }

  /// Shortest round-trip representation for spreadsheets; text passes
  /// through.
  static String _csvNumber(Object? value) {
    if (value is double) {
      if (value.isInfinite || value.isNaN) return _cell(value, 6);
      final text = value.toString();
      return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
    }
    return _cell(value, 6);
  }

  static String _csvEscape(String value) {
    if (value.contains(RegExp(r'[",\r\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ---------------------------------------------------------------- PDF

  Future<Uint8List> toPdf({int precision = 5}) async {
    final fonts = await PdfFonts.load(sampleText: title);
    final document = pw.Document(
      title: title,
      author: 'CompositesAI',
      creator: 'CompositesAI',
      theme: fonts.theme,
    );
    const muted = PdfColors.grey700;

    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(font: fonts.bold, fontSize: 13),
          ),
        );

    List<pw.Widget> sectionWidgets(ReportSection section) {
      final title = pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
        child: pw.Text(
          section is MatrixSection && section.unit.isNotEmpty
              ? '${section.title} (${section.unit})'
              : section.title,
          style: pw.TextStyle(font: fonts.bold, fontSize: 10.5),
        ),
      );
      switch (section) {
        case ValuesSection(:final entries):
          return [
            title,
            _table(
              headers: const ['Quantity', 'Value', 'Unit'],
              rows: [
                for (final e in entries)
                  [e.label, _cell(e.value, precision), e.unit],
              ],
              fonts: fonts,
              numericColumns: const {1},
            ),
          ];
        case MatrixSection(:final values):
          return [
            title,
            _table(
              rows: [
                for (final row in values)
                  [for (final v in row) _cell(v, precision)],
              ],
              fonts: fonts,
              numericColumns: {for (var i = 0; i < values.first.length; i++) i},
            ),
          ];
        case TableSection(:final headers, :final rows):
          return [
            title,
            _table(
              headers: headers,
              rows: [
                for (final row in rows) [for (final v in row) _cell(v, 3)],
              ],
              fonts: fonts,
              numericColumns: {
                for (var i = 0; i < headers.length; i++)
                  if (rows.isNotEmpty && rows.first[i] is double) i,
              },
              fontSize: headers.length > 7 ? 6.5 : 8,
            ),
          ];
        case ChartSection():
          // Keep the title on the same page as its chart.
          return [
            pw.Inseparable(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [title, _chart(section, fonts)],
              ),
            ),
          ];
      }
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 36),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'CompositesAI · $title',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(font: fonts.bold, fontSize: 18)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Units: ${units.name} (${units.summary}) · Generated $_dateLine',
            style: const pw.TextStyle(fontSize: 9, color: muted),
          ),
          if (inputs.isNotEmpty) ...[
            heading('Inputs'),
            for (final section in inputs) ...sectionWidgets(section),
          ],
          heading('Results'),
          for (final section in results) ...sectionWidgets(section),
          if (notes.isNotEmpty) ...[
            heading('Notes'),
            for (final note in notes)
              pw.Bullet(
                text: note,
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _table({
    List<String>? headers,
    required List<List<String>> rows,
    required PdfFonts fonts,
    Set<int> numericColumns = const {},
    double fontSize = 8.5,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerCount: headers == null ? 0 : 1,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(font: fonts.bold, fontSize: fontSize),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellStyle: pw.TextStyle(fontSize: fontSize),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      cellAlignments: {
        for (final column in numericColumns) column: pw.Alignment.centerRight,
      },
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  static const List<PdfColor> _seriesColors = [
    PdfColor.fromInt(0xFF1A73E8),
    PdfColor.fromInt(0xFFD93025),
    PdfColor.fromInt(0xFF188038),
    PdfColor.fromInt(0xFFF29900),
    PdfColor.fromInt(0xFF9334E6),
    PdfColor.fromInt(0xFF12B5CB),
  ];

  static pw.Widget _chart(ChartSection chart, PdfFonts fonts) {
    final points = chart.series.expand((s) => s.points).toList();
    if (points.isEmpty) return pw.SizedBox();
    final xs = points.map((p) => p.$1);
    final ys = points.map((p) => p.$2);
    final xTicks = _ticks(xs.reduce(math.min), xs.reduce(math.max));
    final yTicks = _ticks(ys.reduce(math.min), ys.reduce(math.max));
    String tick(num value) {
      final v = value.toDouble();
      if (v == 0) return '0';
      final magnitude = v.abs();
      return magnitude >= 1e4 || magnitude < 1e-2
          ? v.toStringAsExponential(1)
          : double.parse(v.toStringAsPrecision(3)).toString();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: 170,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                xTicks,
                format: tick,
                textStyle: const pw.TextStyle(fontSize: 7),
                divisions: true,
                divisionsColor: PdfColors.grey200,
              ),
              yAxis: pw.FixedAxis(
                yTicks,
                format: tick,
                textStyle: const pw.TextStyle(fontSize: 7),
                divisions: true,
                divisionsColor: PdfColors.grey200,
              ),
            ),
            datasets: [
              for (var i = 0; i < chart.series.length; i++)
                pw.LineDataSet(
                  legend: chart.series[i].name,
                  color: _seriesColors[i % _seriesColors.length],
                  drawPoints: false,
                  lineWidth: 1.2,
                  isCurved: false,
                  data: [
                    for (final (x, y) in chart.series[i].points)
                      pw.PointChartValue(x, y),
                  ],
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 10,
          children: [
            pw.Text(
              'x: ${chart.xLabel}   y: ${chart.yLabel}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
            for (var i = 0; i < chart.series.length; i++)
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 8,
                    height: 2,
                    color: _seriesColors[i % _seriesColors.length],
                  ),
                  pw.SizedBox(width: 3),
                  pw.Text(
                    chart.series[i].name,
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// About five evenly spaced, rounded ticks covering [min, max].
  static List<double> _ticks(double min, double max) {
    if (min == max) {
      final pad = min == 0 ? 1.0 : min.abs() * 0.1;
      min -= pad;
      max += pad;
    }
    final rawStep = (max - min) / 5;
    final magnitude =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final step = [1.0, 2.0, 2.5, 5.0, 10.0]
            .map((factor) => factor * magnitude)
            .firstWhere((candidate) => candidate >= rawStep);
    final first = (min / step).floor();
    final last = (max / step).ceil();
    return [
      for (var i = first; i <= last; i++)
        // Multiplying (not accumulating) avoids drift like -5.6e-17 for 0.
        double.parse((i * step).toStringAsPrecision(10)),
    ];
  }
}

/// Input sections shared by several calculators.
class ReportInputs {
  const ReportInputs._();

  static ValuesSection lamina(
    TransverselyIsotropicMaterial material,
    Units units, {
    String title = 'Lamina constants',
    bool includeNu23 = false,
  }) {
    return ValuesSection(title, [
      ReportEntry('E1', material.e1, units.modulus),
      ReportEntry('E2', material.e2, units.modulus),
      ReportEntry('G12', material.g12, units.modulus),
      ReportEntry('ν12', material.nu12),
      if (includeNu23) ReportEntry('ν23', material.nu23),
    ]);
  }

  static ValuesSection cte(
    TransverselyIsotropicCTE cte,
    Units units, {
    String title = 'CTEs',
  }) {
    return ValuesSection(title, [
      ReportEntry('ɑ11', cte.alpha11, units.cte),
      ReportEntry('ɑ22', cte.alpha22, units.cte),
      ReportEntry('ɑ12', cte.alpha12, units.cte),
    ]);
  }

  static ValuesSection layup(String sequence, double? plyThickness,
      Units units) {
    return ValuesSection('Layup', [
      ReportEntry('Layup sequence', sequence),
      ReportEntry('Ply thickness', plyThickness, units.length),
    ]);
  }
}

/// Result sections shared by the 3D property calculators.
class ReportResults {
  const ReportResults._();

  static List<ReportSection> threeDimensional({
    required List<List<double>> stiffness,
    required List<List<double>> compliance,
    required Map<String, double> constants,
    required Units units,
    String prefix = '',
  }) {
    String title(String text) => prefix.isEmpty ? text : '$prefix: $text';
    const labels = {
      'E1': 'E1',
      'E2': 'E2',
      'E3': 'E3',
      'G12': 'G12',
      'G13': 'G13',
      'G23': 'G23',
      'nu12': 'ν12',
      'nu13': 'ν13',
      'nu23': 'ν23',
      'alpha11': 'ɑ11',
      'alpha22': 'ɑ22',
      'alpha33': 'ɑ33',
      'alpha12': 'ɑ12',
    };
    String unitFor(String key) {
      if (key.startsWith('E') || key.startsWith('G')) return units.modulus;
      if (key.startsWith('alpha')) return units.cte;
      return '';
    }

    return [
      MatrixSection(title('Effective 3D stiffness matrix'), stiffness,
          unit: units.modulus),
      MatrixSection(title('Effective 3D compliance matrix'), compliance,
          unit: units.compliance),
      ValuesSection(title('Engineering constants'), [
        for (final entry in constants.entries)
          ReportEntry(
            labels[entry.key] ?? entry.key,
            entry.value,
            unitFor(entry.key),
          ),
      ]),
    ];
  }
}
