import 'dart:async';

import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';
import 'package:swiftcomp/util/result_precision.dart';

class _TestPreferences extends Fake implements SharedPreferences {
  _TestPreferences({required this.read, required this.write});

  final Object? Function() read;
  final Future<bool> Function(int) write;

  @override
  Object? get(String key) => read();

  @override
  Future<bool> setInt(String key, int value) => write(value);
}

Future<void> _initialize([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  await SharedPreferencesHelper.init();
}

void main() {
  // Read before any test initializes the static preferences, independently of
  // test execution order. This mirrors a widget reading during app bootstrap.
  final earlyHelper = NumberPrecisionHelper();
  final beforeInitialization = earlyHelper.precision;
  earlyHelper.dispose();

  test('precision policy preserves supported values and clamps other integers',
      () {
    expect(ResultPrecision.minimum, 1);
    expect(ResultPrecision.maximum, 9);
    expect(ResultPrecision.defaultValue, 5);
    for (final value in [-1000, 0, 1, 5, 9, 1000]) {
      final normalized = ResultPrecision.normalize(value);
      expect(normalized, inInclusiveRange(1, 9));
      if (value >= 1 && value <= 9) expect(normalized, value);
    }
    expect(ResultPrecision.normalize(-1000), 1);
    expect(ResultPrecision.normalize(1000), 9);
  });

  test('reading before preferences initialize uses the default', () {
    expect(beforeInitialization, ResultPrecision.defaultValue);
  });

  test('missing and wrong-type saved values fall back; integers are bounded',
      () async {
    for (final example in <({Object? stored, int expected})>[
      (stored: null, expected: 5),
      (stored: '9', expected: 5),
      (stored: true, expected: 5),
      (stored: 2.5, expected: 5),
      (stored: -10, expected: 1),
      (stored: 1000, expected: 9),
      (stored: 7, expected: 7),
    ]) {
      await _initialize({
        if (example.stored != null) 'Number_Precision': example.stored!,
      });
      final helper = NumberPrecisionHelper();
      expect(helper.precision, example.expected, reason: '${example.stored}');
      helper.dispose();
    }
  });

  test('setters persist normalized values and round trip through a new helper',
      () async {
    await _initialize();
    final helper = NumberPrecisionHelper();
    addTearDown(helper.dispose);
    for (final value in [-10, 1, 5, 9, 1000]) {
      await helper.set(value);
      final expected = ResultPrecision.normalize(value);
      expect(helper.precision, expected);
      expect(SharedPreferencesHelper.localStorage.getInt('Number_Precision'),
          expected);
      final reloaded = NumberPrecisionHelper();
      expect(reloaded.precision, expected);
      reloaded.dispose();
    }
  });

  test('listeners and UI state update before persistence completes', () async {
    await _initialize();
    final original = SharedPreferencesHelper.localStorage;
    addTearDown(() => SharedPreferencesHelper.localStorage = original);
    final pendingWrite = Completer<bool>();
    final writes = <int>[];
    SharedPreferencesHelper.localStorage = _TestPreferences(
      read: () => 5,
      write: (value) {
        writes.add(value);
        return pendingWrite.future;
      },
    );
    final helper = NumberPrecisionHelper();
    addTearDown(helper.dispose);
    var notifications = 0;
    helper.addListener(() => notifications++);

    final saved = helper.set(7);
    expect(helper.precision, 7);
    expect(notifications, 1);
    expect(writes, [7]);
    pendingWrite.complete(false);
    await saved;
    expect(helper.precision, 7);
    await helper.set(7);
    expect(notifications, 1);
    await helper.set(1000);
    expect(helper.precision, 9);
    expect(writes.last, 9);
    expect(notifications, 2);
  });

  test('storage read and synchronous or asynchronous write failures are safe',
      () async {
    await _initialize();
    final original = SharedPreferencesHelper.localStorage;
    addTearDown(() => SharedPreferencesHelper.localStorage = original);
    for (final synchronousFailure in [false, true]) {
      SharedPreferencesHelper.localStorage = _TestPreferences(
        read: () => throw StateError('Read failed'),
        write: (value) {
          if (synchronousFailure) throw StateError('Write failed');
          return Future<bool>.error(StateError('Write failed'));
        },
      );
      final helper = NumberPrecisionHelper();
      expect(helper.precision, 5);
      await expectLater(helper.set(8), completes);
      expect(helper.precision, 8);
      helper.dispose();
    }
  });

  for (final mode in [TensorType.stress, TensorType.strain]) {
    testWidgets('lamina ${mode.name} values follow live precision1 through9',
        (tester) async {
      await _initialize();
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final helper = NumberPrecisionHelper();
      addTearDown(helper.dispose);
      final output = LaminaStressStrainOutput(
        tensorType: mode,
        sigma11: 1.23456789123,
        sigma22: -0.000987654321,
        sigma12: 0,
        epsilon11: 0.00123456789123,
        epsilon22: -0.00000987654321,
        gamma12: 0,
      );
      final values = mode == TensorType.stress
          ? [output.sigma11, output.sigma22, output.sigma12]
          : [output.epsilon11, output.epsilon22, output.gamma12];
      await helper.set(1);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: helper,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: ResultPlaneStressStrainRow(output: output, stressUnit: 'MPa'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      for (final digits in [1, 9]) {
        await helper.set(digits);
        await tester.pump();
        for (final value in values) {
          expect(
              find.text(value.toStringAsExponential(digits)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      expect(
          find.text(mode == TensorType.stress ? 'σ11' : 'ε11'), findsOneWidget);
      expect(find.text(mode == TensorType.stress ? 'Result (MPa)' : 'Result'),
          findsOneWidget);
    });
  }

  testWidgets(
      'isolated lamina result uses safe default precision without provider',
      (tester) async {
    final output = LaminaStressStrainOutput(
      tensorType: TensorType.stress,
      sigma11: 1.23456789123,
      sigma22: -0.123456789123,
      sigma12: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ResultPlaneStressStrainRow(output: output)),
    ));
    for (final value in [output.sigma11, output.sigma22, output.sigma12]) {
      expect(
          find.text(value.toStringAsExponential(ResultPrecision.defaultValue)),
          findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets(
        'precision controls fit narrow large text and disable bounds in $locale',
        (tester) async {
      await _initialize({'Number_Precision': 1000});
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final helper = NumberPrecisionHelper();
      addTearDown(helper.dispose);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: helper,
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
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const ResultPrecisionPage(),
        ),
      ));
      await tester.pumpAndSettle();
      final add = find.widgetWithIcon(IconButton, Icons.add);
      final remove = find.widgetWithIcon(IconButton, Icons.remove);
      final strings = S.of(tester.element(find.byType(ResultPrecisionPage)));
      expect(find.text(strings.Result_Precision), findsWidgets);
      expect(find.byTooltip('${strings.Result_Precision} +'), findsOneWidget);
      expect(tester.widget<IconButton>(add).onPressed, isNull);
      expect(tester.widget<IconButton>(remove).onPressed, isNotNull);
      expect(find.text(123456789.toStringAsExponential(9)), findsOneWidget);

      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(helper.precision, 8);
      expect(tester.widget<IconButton>(add).onPressed, isNotNull);

      await helper.set(1);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(remove).onPressed, isNull);
      expect(tester.widget<IconButton>(add).onPressed, isNotNull);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(helper.precision, 2);
      expect(find.text(123456789.toStringAsExponential(2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
