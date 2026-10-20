import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/report_export_button.dart';

CalcReport report(
        {Units units = Units.si, String title = 'Plate properties'}) =>
    CalcReport(
      title: title,
      units: units,
      createdAt: DateTime(2026, 10, 20, 10, 30),
      inputs: [
        ValuesSection('Layup', [
          const ReportEntry('Sequence', '[0/90]s'),
          ReportEntry('Ply thickness', 0.125, units.length),
        ]),
      ],
      results: [
        MatrixSection(
          'A Matrix',
          const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ],
          unit: units.aMatrix,
        ),
        ValuesSection('Properties', [
          ReportEntry('E1', 123.12345678901234, units.modulus),
          const ReportEntry('ν12', 0.3),
          const ReportEntry('Small value', -3e-14),
          const ReportEntry('Unavailable', null),
        ]),
        const TableSection(
          'Plies',
          headers: ['Ply', 'Note'],
          rows: [
            [1, 'a\tb\n"quoted"'],
          ],
        ),
        ChartSection(
          'Stress',
          xLabel: 'z (${units.length})',
          yLabel: 'σ (${units.stress})',
          series: const [
            ChartSeries('σ11', [(-0.25, -10), (0.25, 10)]),
          ],
        ),
      ],
      notes: const ['Symmetric laminates only.'],
    );

Widget app(CalcReport Function() buildReport) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [ReportExportButton(buildReport: buildReport)]),
      ),
    );

Future<void> selectCopy(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Export results'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Copy results'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

  for (final units in [Units.si, Units.us]) {
    test('clipboard text preserves ${units.name} units and matrix row order',
        () {
      final text = report(units: units).toClipboardText();

      expect(text, startsWith('Plate properties\r\nUnits\t${units.name}'));
      expect(text, isNot(contains('\uFEFF')));
      expect(text, contains('Input: Layup\r\nQuantity\tValue\tUnit'));
      expect(text, contains('Ply thickness\t0.125\t${units.length}'));
      expect(
        text,
        contains('Result: A Matrix\r\nUnit\t${units.aMatrix}\r\n'
            '1\t2\t3\r\n4\t5\t6\r\n7\t8\t9\r\n'),
      );
      expect(text, contains('E1\t123.12345678901234\t${units.modulus}'));
      expect(text, contains('ν12\t0.3\t\r\n'));
      expect(text, contains('Small value\t-3e-14\t\r\n'));
      expect(text, contains('Unavailable\t\t\r\n'));
      expect(text, contains('z (${units.length})\tσ (${units.stress})'));
      expect(text, contains('-0.25\t-10\r\n0.25\t10\r\n'));
      expect(text, endsWith('Notes\r\nSymmetric laminates only.\r\n'));
    });
  }

  test('clipboard text quotes tabs, newlines and quotes within cells', () {
    final text = report(title: 'A "quoted" title').toClipboardText();

    expect(text, startsWith('"A ""quoted"" title"\r\n'));
    expect(text, contains('Ply\tNote\r\n1\t"a\tb\n""quoted"""\r\n'));
  });

  testWidgets('copies the current report and retains CSV and PDF options',
      (tester) async {
    String? copiedText;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    var current = report();
    await tester.pumpWidget(app(() => current));

    await tester.tap(find.byTooltip('Export results'));
    await tester.pumpAndSettle();
    expect(find.text('Share as CSV'), findsOneWidget);
    expect(find.text('Share as PDF'), findsOneWidget);
    current = report(units: Units.us, title: 'Updated result');
    await tester.tap(find.text('Copy results'));
    await tester.pumpAndSettle();

    expect(copiedText, current.toClipboardText());
    expect(find.text('Results copied to clipboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard failure shows an error and allows another attempt',
      (tester) async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData' && ++attempts == 1) {
        throw PlatformException(code: 'clipboard_unavailable');
      }
      return null;
    });
    await tester.pumpWidget(app(() => report()));

    await selectCopy(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not copy these results. Please try again.'),
        findsOneWidget);
    expect(find.text('Results copied to clipboard'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await selectCopy(tester);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Results copied to clipboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
        'leaving the page during clipboard ${fail ? 'failure' : 'success'} '
        'does not update disposed widgets', (tester) async {
      final pending = Completer<Object?>();
      var attempts = 0;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          attempts++;
          return pending.future;
        }
        return null;
      });
      await tester.pumpWidget(app(() => report()));
      await selectCopy(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(attempts, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      if (fail) {
        pending.completeError(PlatformException(code: 'clipboard_unavailable'));
      } else {
        pending.complete(null);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
