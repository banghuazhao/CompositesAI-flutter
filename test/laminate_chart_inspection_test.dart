import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_stress_strain_result_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

const _data = [
  FlSpot(-0.125, 1.23456),
  FlSpot(0, 2.34567),
  FlSpot(0, 6.78901),
  FlSpot(0.125, 8.90123),
];

LaminarStressStrainLineChat _chart({
  Units units = Units.si,
  List<FlSpot> data = _data,
  bool strain = false,
}) =>
    LaminarStressStrainLineChat(
      title: strain ? 'ε11' : 'σ11',
      data: data,
      component: strain ? 'ε11' : 'σ11',
      depthUnit: units.length,
      valueUnit: strain ? '' : units.stress,
    );

Widget _app(
  Widget child, {
  NumberPrecisionHelper? precision,
  Locale? locale,
  double scale = 1,
}) {
  final app = MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: locale == null
        ? null
        : const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
    builder: (context, child) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(body: child),
  );
  return precision == null
      ? app
      : ChangeNotifierProvider.value(
          value: precision,
          child: app,
        );
}

LineChart _line(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart));

Rect _plot(WidgetTester tester) =>
    tester.getRect(find.byKey(_line(tester).chartRendererKey!));

String _tooltip(WidgetTester tester) {
  final data = _line(tester).data;
  final spots = data.showingTooltipIndicators.single.showingSpots;
  return data.lineTouchData.touchTooltipData
      .getTooltipItems(spots)
      .single!
      .text;
}

Future<void> _tapInterface(WidgetTester tester) async {
  await tester.tapAt(_plot(tester).center);
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'Number_Precision': 3});
    await SharedPreferencesHelper.init();
  });

  for (final units in [Units.si, Units.us]) {
    testWidgets('${units.name} touch shows both interface surfaces and units',
        (tester) async {
      final precision = NumberPrecisionHelper();
      addTearDown(precision.dispose);
      await tester.pumpWidget(_app(_chart(units: units), precision: precision));
      await tester.pumpAndSettle();
      expect(_line(tester).data.showingTooltipIndicators, isEmpty);

      await _tapInterface(tester);
      final text = _tooltip(tester);
      expect(text, contains('Depth: 0 ${units.length}'));
      expect(text, contains('Ply 1 · Top'));
      expect(text, contains('Ply 2 · Bottom'));
      expect(text, contains('σ11: 2.346e+0 ${units.stress}'));
      expect(text, contains('σ11: 6.789e+0 ${units.stress}'));
      expect(_line(tester).data.lineBarsData.single.showingIndicators, [1, 2]);
      expect(_line(tester).data.lineBarsData.single.spots, same(_data));

      precision.set(1);
      await tester.pump();
      expect(_tooltip(tester), contains('σ11: 2.3e+0 ${units.stress}'));
      expect(_tooltip(tester), contains('σ11: 6.8e+0 ${units.stress}'));
      // Corrupt saved precision must not cause toStringAsExponential to throw.
      precision.set(1000);
      await tester.pump();
      expect(_line(tester).data.showingTooltipIndicators, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'outermost chart points identify only the first bottom and last top',
      (tester) async {
    await tester.pumpWidget(_app(_chart()));
    await tester.pumpAndSettle();

    for (final endpoint in [
      (index: 0, depth: '-1.25000e-1', surface: 'Ply 1 · Bottom'),
      (index: 3, depth: '1.25000e-1', surface: 'Ply 2 · Top'),
    ]) {
      final plot = _plot(tester);
      await tester.tapAt(
          Offset(endpoint.index == 0 ? plot.left : plot.right, plot.center.dy));
      await tester.pump();

      final line = _line(tester).data;
      expect(line.lineBarsData.single.showingIndicators, [endpoint.index]);
      final selected = line.showingTooltipIndicators.single.showingSpots.single;
      expect(selected.x, _data[endpoint.index].x);
      expect(selected.y, _data[endpoint.index].y);
      final text = _tooltip(tester);
      expect(text, contains('Depth: ${endpoint.depth} mm'));
      expect(text, contains(endpoint.surface));
      expect('Ply '.allMatches(text), hasLength(1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mouse hover inspects and exit dismisses without a provider',
      (tester) async {
    await tester.pumpWidget(_app(_chart()));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(_plot(tester).center);
    await tester.pump();
    expect(_tooltip(tester), contains('Ply 1 · Top'));
    expect(_tooltip(tester), contains('Ply 2 · Bottom'));
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(_line(tester).data.showingTooltipIndicators, isEmpty);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero strain shows both identical sides without a stress unit',
      (tester) async {
    await tester.pumpWidget(_app(_chart(
      units: Units.us,
      strain: true,
      data: const [
        FlSpot(-0.125, 0),
        FlSpot(0, 0),
        FlSpot(0, 0),
        FlSpot(0.125, 0)
      ],
    )));
    await tester.pumpAndSettle();
    await _tapInterface(tester);
    final text = _tooltip(tester);
    expect(text, contains('Depth: 0 in'));
    expect(text, contains('Ply 1 · Top'));
    expect(text, contains('Ply 2 · Bottom'));
    expect('ε11: 0'.allMatches(text), hasLength(2));
    expect(text, isNot(contains('ksi')));
    expect(text, isNot(contains('NaN')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow chart tooltip fits and vertical drags keep scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    final precision = NumberPrecisionHelper();
    addTearDown(scroll.dispose);
    addTearDown(precision.dispose);
    await tester.pumpWidget(_app(
      SingleChildScrollView(
        controller: scroll,
        child: Column(children: [_chart(), const SizedBox(height: 1000)]),
      ),
      precision: precision,
      scale: 1.6,
    ));
    await tester.pumpAndSettle();
    await _tapInterface(tester);
    final line = _line(tester);
    final tooltipData = line.data.lineTouchData.touchTooltipData;
    final item = tooltipData
        .getTooltipItems(line.data.showingTooltipIndicators.single.showingSpots)
        .single!;
    final painter = TextPainter(
      text: TextSpan(text: item.text, style: item.textStyle),
      textDirection: item.textDirection,
      textScaler: const TextScaler.linear(1.6),
    )..layout(maxWidth: tooltipData.maxContentWidth);
    expect(painter.width + tooltipData.tooltipPadding.horizontal,
        lessThanOrEqualTo(_plot(tester).width));
    expect(painter.height + tooltipData.tooltipPadding.vertical,
        lessThanOrEqualTo(_plot(tester).height));
    painter.dispose();

    final before = scroll.offset;
    await tester.dragFrom(_plot(tester).center, const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip labels follow the active localization', (tester) async {
    await tester.pumpWidget(_app(_chart(), locale: const Locale('zh')));
    await tester.pumpAndSettle();
    await _tapInterface(tester);
    final strings = S.of(tester.element(find.byType(LineChart)));
    final text = _tooltip(tester);
    expect(text, contains(strings.Calculator_chart_depth('0', 'mm')));
    expect(
        text,
        contains(strings.Calculator_chart_ply_surface(
            1, strings.Calculator_surface_top)));
    expect(
        text,
        contains(strings.Calculator_chart_ply_surface(
            2, strings.Calculator_surface_bottom)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing chart data clears an obsolete selection',
      (tester) async {
    await tester.pumpWidget(_app(_chart()));
    await tester.pumpAndSettle();
    await _tapInterface(tester);
    expect(_line(tester).data.showingTooltipIndicators, hasLength(1));
    await tester
        .pumpWidget(_app(_chart(data: const [FlSpot(-1, 0), FlSpot(1, 1)])));
    await tester.pumpAndSettle();
    expect(_line(tester).data.showingTooltipIndicators, isEmpty);
    await tester.pumpWidget(_app(_chart(data: const [])));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
