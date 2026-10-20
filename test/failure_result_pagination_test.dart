import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_result_page.dart';
import 'package:swiftcomp/presentation/tools/widget/report_export_button.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

const _ratio = 1.23456789123;
const _stress = 12.3456789123;
const _first = ValueKey('failure-table-first-page');
const _previous = ValueKey('failure-table-previous-page');
const _next = ValueKey('failure-table-next-page');
const _last = ValueKey('failure-table-last-page');
const _range = ValueKey('failure-table-range');

LaminateFailureResult _result(int plies, {double ratio = _ratio}) =>
    LaminateFailureResult(
      points: [
        for (var row = 0; row < plies * 2; row++)
          PlyStressPoint(
            ply: row ~/ 2 + 1,
            angle: 0,
            isTop: row.isOdd,
            z: row / 2,
            globalStress: [_stress, -0.123456789123, 0],
            materialStress: [_stress, -0.123456789123, 0],
            results: {
              for (final criterion in FailureCriterion.values)
                criterion: CriterionResult(ratio, 'Fiber tension'),
            },
          ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );

Widget _app(
  LaminateFailureResult result, {
  required NumberPrecisionHelper precision,
  double scale = 1,
  Locale locale = const Locale('en'),
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: precision),
        ChangeNotifierProvider(create: (_) => UnitSettings()),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: LaminateFailureResultPage(result: result),
      ),
    );

Future<void> _pump(WidgetTester tester, LaminateFailureResult result,
    NumberPrecisionHelper precision,
    {Size size = const Size(1200, 2200),
    double scale = 1,
    Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      _app(result, precision: precision, scale: scale, locale: locale));
  await tester.pumpAndSettle();
  if (find.byType(DataTable).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.byType(DataTable), 300,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.pumpAndSettle();
}

DataTable _table(WidgetTester tester) =>
    tester.widget<DataTable>(find.byType(DataTable));

Future<void> _show(WidgetTester tester, Finder finder) async {
  // A shorter last page can move the table above the current list viewport.
  // Lazily kept sliver children are intentionally omitted by default finders.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, -300,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await _show(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('failure-table-heading')).hitTestable(),
      findsOneWidget);
}

String _rangeText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_range)).data!;

bool _enabled(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key)).onPressed != null;

Text _cell(WidgetTester tester, int row, int column) =>
    _table(tester).rows[row].cells[column].child as Text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'Number_Precision': 3});
    await SharedPreferencesHelper.init();
  });
  tearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

  testWidgets(
      'navigation keeps20 surface rows and handles a partial final page',
      (tester) async {
    final precision = NumberPrecisionHelper();
    addTearDown(precision.dispose);
    await _pump(tester, _result(21), precision);
    expect(_table(tester).rows, hasLength(20));
    expect(_rangeText(tester), '1–20 of 42');
    expect(_cell(tester, 0, 0).data, '1 (0°)');
    expect(_cell(tester, 0, 1).data, 'Bottom');
    expect(_cell(tester, 19, 0).data, '10 (0°)');
    expect(_cell(tester, 19, 1).data, 'Top');
    expect(_enabled(tester, _first), isFalse);
    expect(_enabled(tester, _previous), isFalse);
    expect(_enabled(tester, _next), isTrue);

    await _tap(tester, _next);
    expect(_rangeText(tester), '21–40 of 42');
    expect(_cell(tester, 0, 0).data, '11 (0°)');
    await _tap(tester, _last);
    expect(_rangeText(tester), '41–42 of 42');
    expect(_table(tester).rows, hasLength(2));
    expect(_cell(tester, 0, 0).data, '21 (0°)');
    expect(_cell(tester, 0, 1).data, 'Bottom');
    expect(_cell(tester, 1, 1).data, 'Top');
    expect(_enabled(tester, _next), isFalse);
    expect(_enabled(tester, _last), isFalse);

    await _tap(tester, _previous);
    expect(_rangeText(tester), '21–40 of 42');
    await _tap(tester, _first);
    expect(_rangeText(tester), '1–20 of 42');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'large results build only the current page and replacement resets it',
      (tester) async {
    final precision = NumberPrecisionHelper();
    addTearDown(precision.dispose);
    await _pump(tester, _result(1001), precision);
    expect(_table(tester).rows, hasLength(20));
    await _tap(tester, _last);
    expect(_table(tester).rows, hasLength(2));
    final localizations = MaterialLocalizations.of(
        tester.element(find.byType(LaminateFailureResultPage)));
    expect(_rangeText(tester),
        localizations.pageRowsInfoTitle(2001, 2002, 2002, false));

    await tester.pumpWidget(_app(_result(2), precision: precision));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DataTable));
    expect(_rangeText(tester), '1–4 of 4');
    expect(_table(tester).rows, hasLength(4));
    expect(_cell(tester, 0, 0).data, '1 (0°)');
    expect(_enabled(tester, _next), isFalse);
    expect(_enabled(tester, _previous), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R, FI and stresses follow the same precision through9',
      (tester) async {
    final precision = NumberPrecisionHelper();
    addTearDown(precision.dispose);
    await _pump(tester, _result(2), precision);
    for (final digits in [1, 5, 9]) {
      precision.set(digits);
      await tester.pumpAndSettle();
      final ratio = CalcReport.formatNumber(_ratio, precision: digits);
      expect(find.text('R = $ratio'), findsNWidgets(4));
      expect(_cell(tester, 0, 2).data,
          CalcReport.formatNumber(_stress, precision: digits));
      expect(_cell(tester, 0, 5).data,
          CalcReport.formatNumber(1 / _ratio, precision: digits));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed FI colors and unloaded infinity keep their meanings',
      (tester) async {
    final result = _result(2);
    for (final criterion in FailureCriterion.values) {
      result.points[0].results[criterion] =
          const CriterionResult(0.5, 'Fiber tension');
      result.points[1].results[criterion] =
          const CriterionResult(double.infinity, 'Unloaded');
    }
    final precision = NumberPrecisionHelper();
    addTearDown(precision.dispose);
    await _pump(tester, result, precision);
    final errorColor =
        Theme.of(tester.element(find.byType(DataTable))).colorScheme.error;
    expect(_cell(tester, 0, 5).data, '2');
    expect(_cell(tester, 0, 5).style?.color, errorColor);
    expect(_cell(tester, 0, 5).style?.fontWeight, FontWeight.w600);
    expect(_cell(tester, 1, 5).data, '0');
    expect(_cell(tester, 1, 5).style?.color, isNull);

    await tester.pumpWidget(
        _app(_result(2, ratio: double.infinity), precision: precision));
    await tester.pumpAndSettle();
    expect(find.text('R = ∞'), findsNWidgets(4));
    expect(_cell(tester, 0, 5).data, '0');
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets(
        '$locale pagination fits320px with large text and accessible controls',
        (tester) async {
      final precision = NumberPrecisionHelper()..set(9);
      addTearDown(precision.dispose);
      await _pump(tester, _result(21), precision,
          size: const Size(320, 600), scale: 1.8, locale: locale);
      await tester.ensureVisible(find.byKey(_next));
      await tester.pumpAndSettle();
      final localizations =
          MaterialLocalizations.of(tester.element(find.byKey(_next)));
      expect(tester.widget<IconButton>(find.byKey(_next)).tooltip,
          localizations.nextPageTooltip);
      expect(tester.widget<IconButton>(find.byKey(_last)).tooltip,
          localizations.lastPageTooltip);
      expect(_rangeText(tester),
          localizations.pageRowsInfoTitle(1, 20, 42, false));
      await _tap(tester, _last);
      expect(_rangeText(tester),
          localizations.pageRowsInfoTitle(41, 42, 42, false));
      expect(_table(tester).rows, hasLength(2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'pagination keeps every row and full precision in exported reports',
      (tester) async {
    String? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData')
        copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    final result = _result(21);
    final precision = NumberPrecisionHelper();
    addTearDown(precision.dispose);
    await _pump(tester, result, precision);
    await _tap(tester, _last);
    expect(_table(tester).rows, hasLength(2));
    final report = tester
        .widget<ReportExportButton>(find.byType(ReportExportButton))
        .buildReport();
    final table = report.results.whereType<TableSection>().last;
    expect(table.rows, hasLength(42));
    expect(table.rows.first[0], 1);
    expect(table.rows.last[0], 21);
    expect(table.rows.first[4], _stress);

    await tester.tap(find.byTooltip('Export results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy results'));
    await tester.pumpAndSettle();
    final lines = copied!.split('\r\n');
    final start = lines
        .indexOf('Result: Ply stresses (material axes) and failure indices');
    expect(start, greaterThanOrEqualTo(0));
    final rows =
        lines.skip(start + 2).take(42).map((line) => line.split('\t')).toList();
    expect(rows, hasLength(42));
    expect(rows.first[0], '1');
    expect(rows.last[0], '21');
    expect(rows.first[4], _stress.toString());
    expect(result.points, hasLength(42));
    expect(tester.takeException(), isNull);
  });
}
