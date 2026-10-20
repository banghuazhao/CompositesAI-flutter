import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/layer_thickness_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_preview.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';
import 'package:swiftcomp/presentation/tools/widget/number_field.dart';
import 'package:swiftcomp/presentation/tools/widget/report_export_button.dart';
import 'package:swiftcomp/presentation/tools/widget/unit_system_picker.dart';
import 'package:swiftcomp/util/others.dart';

const countKey = ValueKey('layup-ply-count');
const totalKey = ValueKey('layup-total-thickness');
const anglesKey = ValueKey('layup-expanded-angles');

Widget app(Widget child,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    ChangeNotifierProvider(
      create: (_) => UnitSettings(),
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Widget inputs(LayupSequence sequence, LayerThickness thickness) => Column(
      children: [
        LayupSequenceRow(
            layupSequence: sequence, validate: true, layerThickness: thickness),
        LayerThicknessPage(layerThickness: thickness, validate: true),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
  });
  tearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

  testWidgets('preview updates for thickness edits, invalid input and clearing',
      (tester) async {
    final sequence = LayupSequence()..value = '[0/90]s';
    final thickness = LayerThickness()..value = 0.125;
    addTearDown(thickness.dispose);
    await tester.pumpWidget(app(inputs(sequence, thickness)));
    await tester.pumpAndSettle();
    expect(find.text('4 plies'), findsOneWidget);
    expect(find.text('Angles: 0° / 90° / 90° / 0°'), findsOneWidget);
    expect(find.text('Total thickness: 0.5 mm'), findsOneWidget);

    final field = find.widgetWithText(TextField, 'Thickness (mm)');
    await tester.enterText(field, '0.25');
    await tester.pump();
    expect(find.text('Total thickness: 1 mm'), findsOneWidget);
    await tester.enterText(field, 'NaN');
    await tester.pump();
    expect(find.byKey(totalKey), findsNothing);
    expect(find.byKey(countKey), findsOneWidget);

    final layup = find.widgetWithText(TextField, '[xx/xx/xx/xx]msn');
    await tester.enterText(layup, '[0/');
    await tester.pump();
    expect(find.byKey(countKey), findsNothing);
    expect(find.byKey(anglesKey), findsNothing);
    await tester.enterText(layup, '45');
    await tester.pump();
    expect(find.text('1 ply'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pump();
    expect(find.byKey(countKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'preview is bounded for a million plies and hides overflowing totals',
      (tester) async {
    final sequence = LayupSequence()..value = '[45]1000000';
    final thickness = LayerThickness()..value = 1e308;
    addTearDown(thickness.dispose);
    await tester.pumpWidget(
        app(LayupPreview(layups: sequence.layups, layerThickness: thickness)));
    await tester.pumpAndSettle();
    expect(find.text('1000000 plies'), findsOneWidget);
    final text = tester.widget<Text>(find.byKey(anglesKey)).data!;
    expect('45°'.allMatches(text), hasLength(LayupPreview.maxVisibleAngles));
    expect(text, contains('+999988 more'));
    expect(text.length, lessThan(200));
    expect(find.byKey(totalKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview follows replacement models and selected unit labels',
      (tester) async {
    final sequence = LayupSequence()..value = '[0/90]';
    final oldThickness = LayerThickness()..value = 0.125;
    final newThickness = LayerThickness()..value = 0.25;
    addTearDown(oldThickness.dispose);
    addTearDown(newThickness.dispose);
    await tester.pumpWidget(app(inputs(sequence, oldThickness)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(inputs(sequence, newThickness)));
    await tester.pumpAndSettle();
    expect(find.text('Total thickness: 0.5 mm'), findsOneWidget);
    oldThickness.value = 50;
    await tester.pump();
    expect(find.text('Total thickness: 0.5 mm'), findsOneWidget);
    final settings =
        tester.element(find.byType(LayupPreview)).read<UnitSettings>();
    await settings.setSystem(UnitSystem.us);
    await tester.pump();
    expect(find.text('Total thickness: 0.5 in'), findsOneWidget);
    newThickness.value = 0.5;
    await tester.pump();
    expect(find.text('Total thickness: 1 in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    newThickness.value = 1;
    expect(tester.takeException(), isNull);
  });

  final translations = [
    (
      const Locale('en'),
      'Layup Sequence',
      'Layer Thickness',
      '4 plies',
      'Thickness must be greater than zero',
      'Must be greater than zero',
      'Export results',
      'Copy results',
      'Results copied to clipboard',
      'Could not copy these results. Please try again.',
      'Calculator units',
      'US customary'
    ),
    (
      const Locale('zh'),
      '铺层次序',
      '单层厚度',
      '4 层',
      '厚度必须大于零',
      '必须大于零',
      '导出结果',
      '复制结果',
      '结果已复制到剪贴板',
      '无法复制结果，请重试。',
      '计算器单位',
      '美制单位'
    ),
    (
      const Locale('zh', 'HK'),
      '鋪層次序',
      '單層厚度',
      '4 層',
      '厚度必須大於零',
      '必須大於零',
      '匯出結果',
      '複製結果',
      '結果已複製到剪貼簿',
      '無法複製結果，請重試。',
      '計算器單位',
      '美制單位'
    ),
  ];
  for (final tr in translations) {
    testWidgets('${tr.$1} labels, preview and validation are translated',
        (tester) async {
      final sequence = LayupSequence()..value = '[0/90]s';
      final thickness = LayerThickness()..value = -1;
      addTearDown(thickness.dispose);
      await tester.pumpWidget(app(
          Column(children: [
            inputs(sequence, thickness),
            NumberField(
                label: 'E1',
                value: -1,
                onChanged: (_) {},
                errorText: 'Not > 0'),
          ]),
          locale: tr.$1));
      await tester.pumpAndSettle();
      for (final label in [tr.$2, tr.$3, tr.$4, tr.$5, tr.$6]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byKey(totalKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${tr.$1} export success and failure use translated messages',
        (tester) async {
      var fail = false;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData' && fail) {
          throw PlatformException(code: 'unavailable');
        }
        return null;
      });
      await tester.pumpWidget(app(
          ReportExportButton(
              buildReport: () =>
                  CalcReport(title: 'Test', units: Units.si, results: [])),
          locale: tr.$1));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(tr.$7));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.$8));
      await tester.pumpAndSettle();
      expect(find.text(tr.$9), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(ReportExportButton)))
          .removeCurrentSnackBar();
      fail = true;
      await tester.tap(find.byTooltip(tr.$7));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.$8));
      await tester.pumpAndSettle();
      expect(find.text(tr.$10), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${tr.$1} unit picker fits narrow screens with large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(app(const UnitSystemButton(), locale: tr.$1, scale: 1.6));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(UnitSystemButton));
      await tester.pumpAndSettle();
      expect(find.text(tr.$11), findsOneWidget);
      final us = find.text(tr.$12);
      await tester.ensureVisible(us);
      await tester.tap(us);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(UnitSystemButton));
      expect(context.read<UnitSettings>().system, UnitSystem.us);
      expect(tester.takeException(), isNull);
    });
  }
}
