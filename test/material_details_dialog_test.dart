import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/material_details_dialog.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

const _complete = LibraryMaterial(
  id: 'complete-record',
  name: 'Supplier carbon/epoxy, revision B',
  source: 'Supplier handbook, revision B, table 7.2.\n'
      'Full source text stays readable, including its qualification notes.',
  kind: MaterialKind.lamina,
  isCustom: true,
  e1: 181.234567891,
  e2: 10.3,
  g12: 7.17,
  nu12: 0.28,
  nu23: 0.4,
  alpha11: 0,
  alpha22: -22.5e-6,
  xt: 1500,
  xc: 1400,
  yt: 40,
  yc: 246,
  s12: 68,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'Calculator_Unit_System': 'si',
      'Number_Precision': 5,
      'Custom_Materials_v1': 'unchanged saved data',
    });
    await SharedPreferencesHelper.init();
  });

  for (final system in UnitSystem.values) {
    testWidgets('all material values and full source are shown in $system',
        (tester) async {
      await SharedPreferencesHelper.localStorage
          .setString('Calculator_Unit_System', system.name);
      final before = _complete.toJson();
      final harness = await _open(tester);
      final units = Units.of(system);
      final expected = <String, String>{
        'e1': _number(units.modulusFromGPa(_complete.e1), units.modulus),
        'e2': _number(units.modulusFromGPa(_complete.e2!), units.modulus),
        'g12': _number(units.modulusFromGPa(_complete.g12!), units.modulus),
        'nu12': _number(_complete.nu12),
        'nu23': _number(_complete.nu23!),
        'alpha11': _number(units.cteFromPerC(_complete.alpha11!), units.cte),
        'alpha22': _number(units.cteFromPerC(_complete.alpha22!), units.cte),
        'xt': _number(units.stressFromMPa(_complete.xt!), units.stress),
        'xc': _number(units.stressFromMPa(_complete.xc!), units.stress),
        'yt': _number(units.stressFromMPa(_complete.yt!), units.stress),
        'yc': _number(units.stressFromMPa(_complete.yc!), units.stress),
        's12': _number(units.stressFromMPa(_complete.s12!), units.stress),
      };
      for (final field in expected.entries) {
        expect(_value(tester, field.key), field.value, reason: field.key);
      }
      final strings = _strings(tester);
      expect(find.text(_complete.name), findsOneWidget);
      expect(find.text(_complete.source), findsOneWidget);
      expect(
          find.text(strings.Calculator_material_kind_lamina), findsOneWidget);
      for (final title in [
        strings.Calculator_material_elastic_properties,
        strings.Calculator_material_thermal_properties,
        strings.Calculator_material_strengths,
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('material-details-apply')));
      await tester.pumpAndSettle();
      expect(harness.result.choice, isTrue);
      expect(harness.result.selected, same(_complete));
      expect(_complete.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing groups are explicit without hiding supplied values',
      (tester) async {
    const partial = LibraryMaterial(
      id: 'partial',
      name: 'Partial fiber',
      kind: MaterialKind.fiber,
      e1: 200,
      nu12: 0.3,
      alpha22: -2e-6,
      xt: 1000,
    );
    await _open(tester, material: partial);
    final strings = _strings(tester);
    for (final field in [
      'e2',
      'g12',
      'nu23',
      'alpha11',
      'xc',
      'yt',
      'yc',
      's12'
    ]) {
      expect(_value(tester, field), strings.Calculator_material_not_provided,
          reason: field);
    }
    expect(_value(tester, 'alpha22'), _number(-2e-6, Units.si.cte));
    expect(_value(tester, 'xt'), _number(1000, Units.si.stress));
    expect(_value(tester, 'source'), strings.Calculator_material_not_provided);
    expect(find.text(strings.Calculator_material_kind_fiber), findsOneWidget);
    expect(find.text(strings.Calculator_material_missing_note), findsOneWidget);
    expect(
        find.text(strings.Calculator_material_strengths_note), findsOneWidget);
    expect(find.text(strings.Calculator_material_thermal_note), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matrix uses isotropic labels and keeps zero and negative CTEs',
      (tester) async {
    const matrix = LibraryMaterial(
      id: 'matrix',
      name: 'Matrix',
      kind: MaterialKind.matrix,
      e1: 3.5,
      nu12: 0.35,
      alpha11: 0,
      alpha22: -1e-6,
    );
    await _open(tester, material: matrix);
    expect(_label(tester, 'e1'), 'E');
    expect(_label(tester, 'nu12'), 'ν');
    expect(_label(tester, 'alpha11'), 'α');
    expect(_value(tester, 'alpha11'), '0 ${Units.si.cte}');
    expect(_value(tester, 'alpha22'), _number(-1e-6, Units.si.cte));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nonfinite record values are guarded during formatting',
      (tester) async {
    const invalid = LibraryMaterial(
      id: 'invalid',
      name: 'Invalid external record',
      kind: MaterialKind.lamina,
      e1: double.infinity,
      e2: double.negativeInfinity,
      nu12: double.nan,
      alpha11: double.nan,
      s12: double.infinity,
    );
    await _open(tester, material: invalid);
    for (final field in ['e1', 'e2', 'nu12', 'alpha11', 's12']) {
      expect(_value(tester, field),
          _strings(tester).Calculator_material_not_provided);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested settings providers update units and precision live',
      (tester) async {
    final harness = await _open(tester, providersBelowNavigator: true);
    await harness.precision.set(1);
    await tester.pump();
    expect(_value(tester, 'e1'), _number(_complete.e1, 'GPa', 1));
    await harness.units.setSystem(UnitSystem.us);
    await tester.pump();
    expect(_value(tester, 'e1'),
        _number(Units.us.modulusFromGPa(_complete.e1), 'Msi', 1));
    await harness.precision.set(9);
    await tester.pump();
    expect(_value(tester, 'e1'),
        _number(Units.us.modulusFromGPa(_complete.e1), 'Msi', 9));
    expect(_value(tester, 'alpha22'),
        _number(Units.us.cteFromPerC(_complete.alpha22!), Units.us.cte, 9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('isolated preview uses default SI precision and English labels',
      (tester) async {
    await _open(tester, includeProviders: false, localize: false);
    expect(find.text('Material details'), findsOneWidget);
    expect(_value(tester, 'e1'), _number(_complete.e1, 'GPa'));
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets(
        'details scroll and actions remain usable at 320px/2x in $locale',
        (tester) async {
      final harness = await _open(tester,
          locale: locale, size: const Size(320, 640), textScale: 2);
      final strings = _strings(tester);
      expect(find.text(strings.Calculator_material_details), findsOneWidget);
      expect(find.text(strings.Calculator_material_not_provided), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('material-details-s12')));
      await tester.pumpAndSettle();
      expect(_value(tester, 's12'), _number(_complete.s12!, 'MPa'));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('material-details-cancel')));
      await tester.pumpAndSettle();
      expect(harness.result.choice, isFalse);
      expect(harness.result.selected, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dismissal in ['cancel', 'barrier', 'back']) {
    testWidgets('$dismissal never applies or writes previewed data',
        (tester) async {
      final original = SharedPreferencesHelper.localStorage;
      final before = {
        for (final key in original.getKeys()) key: original.get(key)
      };
      final spy = _ReadOnlyPreferences(original);
      SharedPreferencesHelper.localStorage = spy;
      addTearDown(() => SharedPreferencesHelper.localStorage = original);
      final record = _complete.toJson();
      final harness = await _open(tester);
      if (dismissal == 'cancel') {
        await tester.tap(find.byKey(const Key('material-details-cancel')));
      } else if (dismissal == 'barrier') {
        await tester.tapAt(const Offset(2, 2));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(harness.result.choice, isNot(isTrue));
      expect(harness.result.selected, isNull);
      expect(harness.result.completions, 1);
      expect(spy.writes, 0);
      expect(_complete.toJson(), record);
      expect({for (final key in original.getKeys()) key: original.get(key)},
          before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('double Apply and stale callbacks cannot pop the caller',
      (tester) async {
    final harness = await _open(tester);
    final apply = tester
        .widget<FilledButton>(find.byKey(const Key('material-details-apply')))
        .onPressed!;
    apply();
    apply();
    await tester.pumpAndSettle();
    apply();
    expect(harness.result.choice, isTrue);
    expect(harness.result.selected, same(_complete));
    expect(harness.result.completions, 1);
    expect(find.byKey(const Key('open-details')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barrier and widget disposal invalidate saved Apply callbacks',
      (tester) async {
    final harness = await _open(tester);
    final apply = tester
        .widget<FilledButton>(find.byKey(const Key('material-details-apply')))
        .onPressed!;
    await tester.tapAt(const Offset(2, 2));
    apply();
    await tester.pumpAndSettle();
    expect(harness.result.choice, isNull);
    expect(harness.result.selected, isNull);
    await tester.tap(find.byKey(const Key('open-details')));
    await tester.pumpAndSettle();
    final disposedApply = tester
        .widget<FilledButton>(find.byKey(const Key('material-details-apply')))
        .onPressed!;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    disposedApply();
    expect(harness.result.selected, isNull);
    expect(tester.takeException(), isNull);
  });
}

String _number(double value, [String unit = '', int precision = 5]) {
  final text = value == 0 ? '0' : value.toStringAsExponential(precision);
  return unit.isEmpty ? text : '$text $unit';
}

Finder _texts(String field) => find.descendant(
      of: find.byKey(ValueKey('material-details-$field')),
      matching: find.byType(Text),
    );

String _value(WidgetTester tester, String field) =>
    tester.widget<Text>(_texts(field).last).data!;

String _label(WidgetTester tester, String field) =>
    tester.widget<Text>(_texts(field).first).data!;

S _strings(WidgetTester tester) =>
    S.of(tester.element(find.byKey(const Key('material-details-dialog'))));

class _Result {
  bool? choice;
  int completions = 0;
  LibraryMaterial? selected;
}

class _Harness {
  _Harness(this.units, this.precision, this.result);

  final UnitSettings units;
  final NumberPrecisionHelper precision;
  final _Result result;
}

Future<_Harness> _open(
  WidgetTester tester, {
  LibraryMaterial material = _complete,
  Locale locale = const Locale('en'),
  Size size = const Size(900, 1100),
  double textScale = 1,
  bool providersBelowNavigator = false,
  bool includeProviders = true,
  bool localize = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final units = UnitSettings();
  final precision = NumberPrecisionHelper();
  addTearDown(units.dispose);
  addTearDown(precision.dispose);
  final result = _Result();
  Widget providers(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: units),
          ChangeNotifierProvider.value(value: precision),
        ],
        child: child,
      );
  Widget home = Builder(builder: (context) {
    return Scaffold(
      body: TextButton(
        key: const Key('open-details'),
        onPressed: () async {
          final choice = await showMaterialDetails(context, material);
          result.choice = choice;
          result.completions++;
          if (choice == true) result.selected = material;
        },
        child: const Text('Preview'),
      ),
    );
  });
  if (includeProviders && providersBelowNavigator) home = providers(home);
  Widget app = MaterialApp(
    locale: locale,
    supportedLocales:
        localize ? S.delegate.supportedLocales : const [Locale('en')],
    localizationsDelegates: localize
        ? const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ]
        : null,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
  if (includeProviders && !providersBelowNavigator) app = providers(app);
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const Key('open-details')));
  await tester.pumpAndSettle();
  return _Harness(units, precision, result);
}

class _ReadOnlyPreferences extends Fake implements SharedPreferences {
  _ReadOnlyPreferences(this.backing);

  final SharedPreferences backing;
  int writes = 0;

  @override
  Object? get(String key) => backing.get(key);

  @override
  Future<bool> setString(String key, String value) async {
    writes++;
    return false;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    writes++;
    return false;
  }
}
