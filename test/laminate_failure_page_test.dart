import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_failure_result_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  Widget app() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NumberPrecisionHelper()),
        ChangeNotifierProvider(create: (_) => UnitSettings()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LaminateFailurePage(),
      ),
    );
  }

  testWidgets('library material fills inputs and analysis shows results',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('E1 (GPa)'), findsOneWidget);
    expect(find.text('Xt (MPa)'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T300/5208 carbon/epoxy'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '181'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '1500'), findsNWidgets(2));
    expect(find.widgetWithText(TextFormField, '246'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '[xx/xx/xx/xx]msn'),
      '[0/90]s',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Thickness (mm)'),
      '0.125',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'N11 (N/mm)'),
      '100',
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.byType(LaminateFailureResultPage), findsOneWidget);
    expect(find.text('First-ply failure'), findsOneWidget);
    expect(find.textContaining('Matrix tension'), findsWidgets);
    expect(find.textContaining(RegExp(r'^R = ')), findsNWidgets(4));
    expect(find.text('R = 1.871'), findsWidgets);
  });

  testWidgets('switching to US units relabels inputs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(LaminateFailurePage));
    await Provider.of<UnitSettings>(context, listen: false)
        .setSystem(UnitSystem.us);
    await tester.pump();

    expect(find.text('E1 (Msi)'), findsOneWidget);
    expect(find.text('Xt (ksi)'), findsOneWidget);
  });
}
