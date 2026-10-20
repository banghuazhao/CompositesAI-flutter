import 'package:flutter/material.dart';
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

const _stress = 12.3456789123;
const _filter = ValueKey('failure-criterion-filter');
const _onlyFailing = ValueKey('failure-only-failed-filter');
const _focused = ValueKey('failure-focused-surface');

LaminateFailureResult _result(int count,
        {Map<FailureCriterion, CriterionResult> Function(int)? outcomes}) =>
    LaminateFailureResult(
      points: [
        for (var index = 0; index < count; index++)
          PlyStressPoint(
            ply: index ~/ 2 + 1,
            angle: 45,
            isTop: index.isOdd,
            // Adjacent top/bottom interfaces deliberately share a depth.
            z: (index + 1) ~/ 2 * .125,
            globalStress: [_stress + index, 0, -1],
            materialStress: [_stress + index, 0, -1],
            results: outcomes?.call(index) ??
                {
                  for (final criterion in FailureCriterion.values)
                    criterion: CriterionResult(
                        index ==
                                switch (criterion) {
                                  FailureCriterion.maxStress => 45,
                                  FailureCriterion.tsaiHill => 44,
                                  FailureCriterion.tsaiWu => 31,
                                  FailureCriterion.hashin => 47,
                                }
                            ? .5
                            : 2,
                        'Fiber tension'),
                },
          ),
      ],
      midplaneStrains: [0, 0, 0],
      curvatures: [0, 0, 0],
    );

Widget _app(LaminateFailureResult result, NumberPrecisionHelper precision,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UnitSettings()),
        ChangeNotifierProvider.value(value: precision),
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
    Locale locale = const Locale('en'),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester
      .pumpWidget(_app(result, precision, locale: locale, scale: scale));
  await tester.pumpAndSettle();
}

Finder _action(FailureCriterion criterion) =>
    find.byKey(ValueKey('failure-view-${criterion.name}'));

Future<void> _show(WidgetTester tester, Finder finder,
    {double direction = -300}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, direction,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _focus(WidgetTester tester, FailureCriterion criterion) async {
  await _show(tester, _action(criterion));
  await tester.tap(_action(criterion));
  await tester.pumpAndSettle();
}

DataTable _table(WidgetTester tester) =>
    tester.widget<DataTable>(find.byType(DataTable));

DataRow _selected(WidgetTester tester) {
  final rows = _table(tester).rows.where((row) => row.selected);
  expect(rows, hasLength(1));
  return rows.single;
}

void _expectFocus(WidgetTester tester, int index, FailureCriterion criterion) {
  final row = _selected(tester);
  expect(row.key, ValueKey('failure-point-$index'));
  expect((row.cells[1].child as Text).data, index.isOdd ? 'Top' : 'Bottom');
  expect(
      tester
          .widget<DropdownButton<FailureCriterion>>(find.byKey(_filter))
          .value,
      criterion);
  expect(_table(tester).columns, hasLength(6));
  final label = row.cells.first.child as Text;
  expect(find.byKey(label.key!).hitTestable(), findsOneWidget,
      reason: 'The requested surface must be visible without another scroll.');
}

List<List<List<Object?>>> _reportRows(WidgetTester tester) => tester
    .widget<ReportExportButton>(find.byType(ReportExportButton))
    .buildReport()
    .results
    .whereType<TableSection>()
    .map((section) => section.rows)
    .toList();

void main() {
  late NumberPrecisionHelper precision;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'Number_Precision': 5});
    await SharedPreferencesHelper.init();
    precision = NumberPrecisionHelper();
  });
  tearDown(() => precision.dispose());

  testWidgets('focus jumps beyond40 surfaces and separates same-ply top/bottom',
      (tester) async {
    final result = _result(48);
    await _pump(tester, result, precision);
    final reportBefore = _reportRows(tester);
    final pointsBefore = [...result.points];
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 45, FailureCriterion.maxStress);
    expect(_table(tester).rows.first.key, const ValueKey('failure-point-40'));
    expect(_table(tester).rows.last.key, const ValueKey('failure-point-47'));
    await _focus(tester, FailureCriterion.tsaiHill);
    _expectFocus(tester, 44, FailureCriterion.tsaiHill);
    expect(_reportRows(tester), reportBefore);
    expect(result.points, orderedEquals(pointsBefore));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed filtering stays active when the critical point is failed',
      (tester) async {
    final result = _result(50,
        outcomes: (index) => {
              FailureCriterion.maxStress: CriterionResult(
                  index == 46 ? .1 : (index.isEven ? .5 : 2), 'Fiber tension'),
              FailureCriterion.tsaiHill:
                  const CriterionResult(double.infinity, 'Unloaded'),
            });
    await _pump(tester, result, precision);
    await _show(tester, find.byKey(_onlyFailing), direction: 300);
    await tester.tap(find.byKey(_onlyFailing));
    await tester.pumpAndSettle();
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 46, FailureCriterion.maxStress);
    expect(
        tester.widget<SwitchListTile>(find.byKey(_onlyFailing)).value, isTrue);
    expect(_table(tester).rows.map((row) => row.key), [
      for (final index in [40, 42, 44, 46, 48]) ValueKey('failure-point-$index')
    ]);
    // An unloaded criterion has no failed rows, so its critical surface must
    // leave the failed-only view and retain the first tied infinite outcome.
    await _focus(tester, FailureCriterion.tsaiHill);
    _expectFocus(tester, 0, FailureCriterion.tsaiHill);
    expect(
        tester.widget<SwitchListTile>(find.byKey(_onlyFailing)).value, isFalse);
    expect((_selected(tester).cells[5].child as Text).data, '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('first tied minimum wins and absent criteria have no action',
      (tester) async {
    await _pump(
        tester,
        _result(48,
            outcomes: (index) => {
                  FailureCriterion.maxStress: CriterionResult(
                      index == 44 || index == 45 ? .5 : 2, 'Fiber tension'),
                }),
        precision);
    expect(_action(FailureCriterion.hashin), findsNothing);
    expect(_action(FailureCriterion.tsaiHill), findsNothing);
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 44, FailureCriterion.maxStress);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'empty results and results with no outcomes have no focus actions',
      (tester) async {
    for (final result in [_result(0), _result(2, outcomes: (_) => {})]) {
      await tester.pumpWidget(_app(result, precision));
      await tester.pumpAndSettle();
      for (final criterion in FailureCriterion.values) {
        expect(_action(criterion), findsNothing);
      }
      expect(find.byKey(_focused), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('rapid focus actions resolve to the latest requested criterion',
      (tester) async {
    await _pump(tester, _result(48), precision);
    final first = tester
        .widget<TextButton>(_action(FailureCriterion.maxStress))
        .onPressed!;
    final last = tester
        .widget<TextButton>(_action(FailureCriterion.tsaiHill))
        .onPressed!;
    first();
    last();
    await tester.pumpAndSettle();
    _expectFocus(tester, 44, FailureCriterion.tsaiHill);
    await precision.set(9);
    await tester.pumpAndSettle();
    expect((_selected(tester).cells[2].child as Text).data,
        CalcReport.formatNumber(_stress + 44, precision: 9));
    _expectFocus(tester, 44, FailureCriterion.tsaiHill);
    // Scroll to the summary and back without another focus request: the table
    // must keep its focused page, criterion and exact selected surface.
    await _show(tester, _action(FailureCriterion.maxStress));
    await _show(tester, find.byType(DataTable), direction: 300);
    expect(_selected(tester).key, const ValueKey('failure-point-44'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'manual pagination clears highlighting and repeat focus restores it',
      (tester) async {
    await _pump(tester, _result(48), precision);
    await _focus(tester, FailureCriterion.maxStress);
    final firstPage = find.byKey(const ValueKey('failure-table-first-page'));
    await _show(tester, firstPage, direction: 300);
    await tester.tap(firstPage);
    await tester.pumpAndSettle();
    expect(_table(tester).rows.where((row) => row.selected), isEmpty);
    expect(find.byKey(_focused), findsNothing);
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 45, FailureCriterion.maxStress);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'stale and queued focus callbacks ignore replaced or disposed data',
      (tester) async {
    await _pump(tester, _result(48), precision);
    final stale = tester
        .widget<TextButton>(_action(FailureCriterion.maxStress))
        .onPressed!;
    stale();
    final replacement = _result(2,
        outcomes: (index) => {
              FailureCriterion.maxStress:
                  CriterionResult(index == 1 ? .25 : 2, 'Matrix tension'),
            });
    await tester.pumpWidget(_app(replacement, precision));
    stale();
    await tester.pumpAndSettle();
    expect(_table(tester).rows, hasLength(2));
    expect(_table(tester).rows.where((row) => row.selected), isEmpty);
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 1, FailureCriterion.maxStress);
    await _show(tester, _action(FailureCriterion.maxStress));
    final removed = tester
        .widget<TextButton>(_action(FailureCriterion.maxStress))
        .onPressed!;
    removed();
    await tester.pumpWidget(const SizedBox.shrink());
    removed();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a covered result screen ignores old focus actions until dismissed',
      (tester) async {
    await _pump(tester, _result(48), precision);
    final callback = tester
        .widget<TextButton>(_action(FailureCriterion.maxStress))
        .onPressed!;
    final context = tester.element(find.byType(LaminateFailureResultPage));
    final dismissed = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Covered')),
    );
    await tester.pumpAndSettle();
    callback();
    await tester.pump();
    expect(find.text('Covered'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await dismissed;
    await tester.pumpAndSettle();
    expect(find.byKey(_focused), findsNothing);
    await _focus(tester, FailureCriterion.maxStress);
    _expectFocus(tester, 45, FailureCriterion.maxStress);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('lazy table focus works at320px/2x in $locale', (tester) async {
      await _pump(tester, _result(48), precision,
          size: const Size(320, 640), scale: 2, locale: locale);
      expect(find.byType(DataTable), findsNothing,
          reason: 'The large summary initially leaves the table unmounted.');
      final strings = S.of(tester.element(_action(FailureCriterion.maxStress)));
      expect(find.text(strings.Calculator_view_in_table), findsNWidgets(4));
      await _focus(tester, FailureCriterion.maxStress);
      _expectFocus(tester, 45, FailureCriterion.maxStress);
      await precision.set(1);
      await tester.pumpAndSettle();
      expect((_selected(tester).cells[2].child as Text).data,
          CalcReport.formatNumber(_stress + 45, precision: 1));
      expect(tester.takeException(), isNull);
    });
  }
}
