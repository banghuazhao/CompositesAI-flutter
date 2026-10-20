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

const _criterion = ValueKey('failure-criterion-filter');
const _onlyFailing = ValueKey('failure-only-failed-filter');
const _status = ValueKey('failure-filter-status');
const _empty = ValueKey('failure-empty-state');
const _range = ValueKey('failure-table-range');
const _next = ValueKey('failure-table-next-page');
const _last = ValueKey('failure-table-last-page');
const _stress = 12.3456789123;

LaminateFailureResult _result(int surfaces,
        {Map<FailureCriterion, double> Function(int)? ratios}) =>
    LaminateFailureResult(
      points: [
        for (var row = 0; row < surfaces; row++)
          PlyStressPoint(
            ply: row ~/ 2 + 1,
            angle: (row ~/ 2).isEven ? 0 : 45,
            isTop: row.isOdd,
            z: row * .125,
            globalStress: [_stress + row, -1, 0],
            materialStress: [_stress + row, -1, 0],
            results: {
              for (final criterion in FailureCriterion.values)
                criterion: CriterionResult(
                    ratios?.call(row)[criterion] ?? 2, 'Fiber tension'),
            },
          ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );

LaminateFailureResult _differentCriteria() => _result(6, ratios: (row) {
      return switch (row) {
        0 => {FailureCriterion.maxStress: 1},
        1 => {FailureCriterion.tsaiHill: .5},
        2 => {FailureCriterion.hashin: .25},
        3 => {
            for (final criterion in FailureCriterion.values)
              criterion: double.infinity
          },
        4 => {FailureCriterion.maxStress: 1, FailureCriterion.tsaiWu: 1},
        _ => {},
      };
    });

Widget _app(LaminateFailureResult result,
        {required NumberPrecisionHelper precision,
        required UnitSettings units,
        Locale locale = const Locale('en'),
        double scale = 1}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: precision),
        ChangeNotifierProvider.value(value: units),
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
            child: child!),
        home: LaminateFailureResultPage(result: result),
      ),
    );

Future<void> _pump(WidgetTester tester, LaminateFailureResult result,
    {required NumberPrecisionHelper precision,
    required UnitSettings units,
    Size size = const Size(1200, 2200),
    Locale locale = const Locale('en'),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(result,
      precision: precision, units: units, locale: locale, scale: scale));
  await tester.pumpAndSettle();
  if (find.byKey(_criterion).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.byKey(_criterion), 300,
        scrollable: find.byType(Scrollable).first);
  }
  await _show(tester, find.byKey(_criterion));
}

Future<void> _show(WidgetTester tester, Finder finder) async {
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
}

Future<void> _select(WidgetTester tester, FailureCriterion? criterion) async {
  final strings = S.of(tester.element(find.byType(LaminateFailureResultPage)));
  await _tap(tester, _criterion);
  await tester.tap(find
      .text(criterion?.label ?? strings.Calculator_all_failure_criteria)
      .last);
  await tester.pumpAndSettle();
}

DataTable _table(WidgetTester tester) =>
    tester.widget<DataTable>(find.byType(DataTable));
List<Key?> _rowKeys(WidgetTester tester) =>
    _table(tester).rows.map((row) => row.key).toList();
List<Key> _keys(Iterable<int> indexes) =>
    indexes.map((index) => ValueKey('failure-point-$index')).toList();
List<String?> _columns(WidgetTester tester) => _table(tester)
    .columns
    .map((column) => (column.label as Text).data)
    .toList();
Text _cell(WidgetTester tester, int row, int column) =>
    _table(tester).rows[row].cells[column].child as Text;
String _rangeText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_range)).data!;
CalcReport _report(WidgetTester tester) => tester
    .widget<ReportExportButton>(find.byType(ReportExportButton))
    .buildReport();

void _expectRange(WidgetTester tester, int first, int last, int total) {
  final localizations =
      MaterialLocalizations.of(tester.element(find.byKey(_range)));
  expect(_rangeText(tester),
      localizations.pageRowsInfoTitle(first, last, total, false));
}

void _expectStatus(WidgetTester tester, int shown, int total) {
  final strings = S.of(tester.element(find.byKey(_status)));
  expect(tester.widget<Text>(find.byKey(_status)).data,
      strings.Calculator_failure_filter_summary(shown, total));
}

void _expectHeadingVisible() => expect(
    find.byKey(const ValueKey('failure-table-heading')).hitTestable(),
    findsOneWidget);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NumberPrecisionHelper precision;
  late UnitSettings units;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'Number_Precision': 3});
    await SharedPreferencesHelper.init();
    precision = NumberPrecisionHelper();
    units = UnitSettings();
  });
  tearDown(() {
    precision.dispose();
    units.dispose();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('criterion filters use each outcome and include threshold ties',
      (tester) async {
    final result = _differentCriteria();
    final original = result.points.toList();
    await _pump(tester, result, precision: precision, units: units);
    expect(_table(tester).rows, hasLength(6));
    expect(_columns(tester).skip(5),
        FailureCriterion.values.map((criterion) => criterion.shortLabel));
    _expectStatus(tester, 6, 6);
    _expectRange(tester, 1, 6, 6);
    final summary =
        _report(tester).results.whereType<TableSection>().first.rows;
    expect(
        summary.first[2], 1); // Equal strength ratios keep the first surface.

    await _tap(tester, _onlyFailing);
    expect(_rowKeys(tester), _keys([0, 1, 2, 4]));
    _expectStatus(tester, 4, 6);
    for (final (criterion, indexes) in [
      (FailureCriterion.maxStress, [0, 4]),
      (FailureCriterion.tsaiHill, [1]),
      (FailureCriterion.tsaiWu, [4]),
      (FailureCriterion.hashin, [2]),
    ]) {
      await _select(tester, criterion);
      expect(_columns(tester).skip(5), [criterion.shortLabel]);
      expect(_rowKeys(tester), _keys(indexes));
      _expectStatus(tester, indexes.length, 6);
      expect(_cell(tester, 0, 5).style?.fontWeight, FontWeight.w600);
      _expectHeadingVisible();
    }
    await _select(tester, null);
    expect(_rowKeys(tester), _keys([0, 1, 2, 4]));
    await _tap(tester, _onlyFailing);
    expect(_rowKeys(tester), _keys(List.generate(6, (index) => index)));
    expect(_cell(tester, 3, 5).data, '0'); // Infinite R means unloaded.
    expect(_cell(tester, 3, 5).style?.color, isNull);
    expect(
        _report(tester).results.whereType<TableSection>().first.rows, summary);
    expect(result.points, orderedEquals(original));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'filtered pagination uses original indexes and empty clears safely',
      (tester) async {
    final result = _result(50,
        ratios: (row) => {
              if (row.isEven) FailureCriterion.maxStress: .5,
            });
    await _pump(tester, result, precision: precision, units: units);
    await _tap(tester, _last);
    _expectRange(tester, 41, 50, 50);
    await _tap(tester, _onlyFailing);
    _expectRange(tester, 1, 20, 25);
    expect(_rowKeys(tester), _keys(List.generate(20, (index) => index * 2)));
    _expectHeadingVisible();
    await _tap(tester, _next);
    _expectRange(tester, 21, 25, 25);
    expect(_rowKeys(tester), _keys([40, 42, 44, 46, 48]));
    expect(_cell(tester, 0, 0).data, '21 (0°)');
    expect(_cell(tester, 0, 1).data, 'Bottom');
    expect(_cell(tester, 4, 0).data, '25 (0°)');

    await _select(tester, FailureCriterion.tsaiHill);
    expect(_table(tester).rows, isEmpty);
    _expectRange(tester, 0, 0, 0);
    _expectStatus(tester, 0, 50);
    expect(find.byKey(_empty), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(_next)).onPressed, isNull);
    final strings = S.of(tester.element(find.byKey(_empty)));
    expect(find.text(strings.Calculator_no_failed_surfaces), findsOneWidget);
    _expectHeadingVisible();
    await _tap(tester, _onlyFailing);
    expect(find.byKey(_empty), findsNothing);
    _expectRange(tester, 1, 20, 50);
    expect(_table(tester).rows, hasLength(20));
    expect(_columns(tester).skip(5), [FailureCriterion.tsaiHill.shortLabel]);
    await _tap(tester, _last);
    await _select(tester, null);
    _expectRange(tester, 1, 20, 50);
    expect(_table(tester).columns, hasLength(9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing outcomes are unavailable rather than failed',
      (tester) async {
    final result = _differentCriteria();
    result.points[0].results.remove(FailureCriterion.maxStress);
    await _pump(tester, result, precision: precision, units: units);
    await _select(tester, FailureCriterion.maxStress);
    expect(_cell(tester, 0, 5).data, '—');
    expect(_cell(tester, 0, 5).style?.color, isNull);
    await _tap(tester, _onlyFailing);
    expect(_rowKeys(tester), _keys([4]));
    final exported = _report(tester).results.whereType<TableSection>().last;
    expect(exported.rows, hasLength(6));
    expect(exported.rows.first[7], isNull);
    expect(exported.headers, hasLength(11));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'replacement resets pagination, keeps filters and handles no data',
      (tester) async {
    await _pump(
        tester, _result(50, ratios: (_) => {FailureCriterion.maxStress: .5}),
        precision: precision, units: units);
    await _select(tester, FailureCriterion.maxStress);
    await _tap(tester, _onlyFailing);
    await _tap(tester, _last);
    await tester.pumpWidget(_app(
        _result(8,
            ratios: (row) => {
                  if (row == 6) FailureCriterion.maxStress: 1,
                }),
        precision: precision,
        units: units));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<FailureCriterion>>(find.byKey(_criterion))
            .value,
        FailureCriterion.maxStress);
    expect(
        tester.widget<SwitchListTile>(find.byKey(_onlyFailing)).value, isTrue);
    _expectRange(tester, 1, 1, 1);
    expect(_rowKeys(tester), _keys([6]));
    _expectHeadingVisible();

    await tester
        .pumpWidget(_app(_result(0), precision: precision, units: units));
    await tester.pumpAndSettle();
    _expectRange(tester, 0, 0, 0);
    _expectStatus(tester, 0, 0);
    expect(_table(tester).rows, isEmpty);
    expect(find.byKey(_empty), findsOneWidget);
    final strings = S.of(tester.element(find.byKey(_empty)));
    expect(find.text(strings.Calculator_no_failure_results), findsWidgets);
    expect(
        _report(tester).results.whereType<TableSection>().last.rows, isEmpty);
    expect(_report(tester).toCsv(), contains('FI Hashin'));
    await _tap(tester, _onlyFailing);
    await _select(tester, null);
    expect(_table(tester).columns, hasLength(9));
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('$locale filters fit320px at2x and retain precision and units',
        (tester) async {
      precision.set(9);
      await _pump(tester, _differentCriteria(),
          precision: precision,
          units: units,
          size: const Size(320, 700),
          locale: locale,
          scale: 2);
      await _select(tester, FailureCriterion.maxStress);
      await _tap(tester, _onlyFailing);
      _expectStatus(tester, 2, 6);
      expect(_cell(tester, 0, 2).data,
          CalcReport.formatNumber(_stress, precision: 9));
      await units.setSystem(UnitSystem.us);
      precision.set(1);
      await tester.pumpAndSettle();
      expect(_rowKeys(tester), _keys([0, 4]));
      expect(_cell(tester, 0, 2).data,
          CalcReport.formatNumber(_stress, precision: 1));
      expect(_report(tester).units, Units.us);
      expect(_report(tester).results.whereType<TableSection>().last.headers,
          contains('σ1 (ksi)'));
      _expectRange(tester, 1, 2, 2);
      await _select(tester, FailureCriterion.tsaiHill);
      expect(_rowKeys(tester), _keys([1]));
      await _select(tester, null);
      expect(_rowKeys(tester), _keys([0, 1, 2, 4]));
      // Leave framework errors uncaught so an overflow reports its source.
    });
  }

  testWidgets('filtered copy and CSV retain every surface and criterion',
      (tester) async {
    String? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    final result = _result(42,
        ratios: (row) => {if (row == 40) FailureCriterion.tsaiWu: .5});
    await _pump(tester, result, precision: precision, units: units);
    final before = _report(tester);
    await _select(tester, FailureCriterion.tsaiWu);
    await _tap(tester, _onlyFailing);
    expect(_rowKeys(tester), _keys([40]));
    final report = _report(tester);
    final table = report.results.whereType<TableSection>().last;
    expect(table.headers, hasLength(11));
    expect(table.rows, hasLength(42));
    expect(table.rows, before.results.whereType<TableSection>().last.rows);
    expect(report.results.whereType<TableSection>().first.rows,
        before.results.whereType<TableSection>().first.rows);
    final chart = report.results.whereType<ChartSection>().single;
    expect(chart.series, hasLength(4));
    expect(
        chart.series.map((series) => series.points.length), everyElement(42));

    await tester.tap(find.byTooltip('Export results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy results'));
    await tester.pumpAndSettle();
    for (final (text, separator) in [
      (copied!, '\t'),
      (report.toCsv(), ','),
    ]) {
      final lines = text.split('\r\n');
      final start = lines
          .indexOf('Result: Ply stresses (material axes) and failure indices');
      expect(start, greaterThanOrEqualTo(0));
      final headers = lines[start + 1].split(separator);
      expect(
          headers.skip(7),
          FailureCriterion.values
              .map((criterion) => 'FI ${criterion.shortLabel}'));
      final rows = lines
          .skip(start + 2)
          .take(42)
          .map((line) => line.split(separator))
          .toList();
      expect(rows, hasLength(42));
      expect(rows.first[0], '1');
      expect(rows.last[0], '21');
      expect(rows.first[4], _stress.toString());
      expect(rows[40][9], '2');
      expect(rows.every((row) => row.length == 11), isTrue);
    }
    expect(result.points, hasLength(42));
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued filter reveal is safe when the result screen is removed',
      (tester) async {
    await _pump(tester, _differentCriteria(),
        precision: precision, units: units);
    tester
        .widget<DropdownButton<FailureCriterion>>(find.byKey(_criterion))
        .onChanged!(FailureCriterion.tsaiWu);
    tester.widget<SwitchListTile>(find.byKey(_onlyFailing)).onChanged!(true);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
