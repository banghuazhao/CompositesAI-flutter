import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_page.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/others.dart';

// Run on iOS or Android to exercise the real platform clipboard. The calculator
// opens directly, without app startup, authentication or backend requests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final system in UnitSystem.values) {
    final units = Units.of(system);

    testWidgets('${units.name} calculator inputs and native clipboard smoke',
        (tester) async {
      expect(kIsWeb, isFalse,
          reason: 'Run this smoke target on iOS or Android.');
      expect(
        defaultTargetPlatform,
        anyOf(TargetPlatform.iOS, TargetPlatform.android),
        reason: 'This target verifies a native clipboard, without a mock.',
      );

      // Isolate settings and the material library from the installed app's
      // saved preferences, while keeping the real platform clipboard.
      SharedPreferences.setMockInitialValues({
        'Calculator_Unit_System': system.name,
      });
      await SharedPreferencesHelper.init();
      MaterialLibrary.instance.resetForTest();
      addTearDown(MaterialLibrary.instance.resetForTest);

      await tester.pumpWidget(_calculatorApp());
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Library'));
      final search = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search materials');
      await _enterText(tester, search, 'T300/5208');
      await _tap(tester, find.text('T300/5208 carbon/epoxy'));
      expect(find.text('E1 (${units.modulus})'), findsOneWidget);

      final thickness = units.lengthFromMm(0.125);
      await _enterText(
        tester,
        _fieldWithLabel('Thickness (${units.length})'),
        thickness.toString(),
      );
      final layup = _fieldWithLabel('[xx/xx/xx/xx]msn');

      if (system == UnitSystem.si) {
        // A previously valid layup must stop calculating as soon as Clear is
        // pressed. Material and thickness are already valid to isolate layup.
        await _enterText(tester, layup, '[0/90]s');
        await _tap(
          tester,
          find.descendant(
            of: find.byType(LayupSequenceRow),
            matching: find.byIcon(Icons.cancel),
          ),
        );
        expect(tester.widget<TextField>(layup).controller!.text, isEmpty);
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
        await _show(tester, layup);
        expect(find.text('Wrong layup sequence'), findsOneWidget);

        // Reject the repetition before allocating the expanded laminate. The
        // following interactions also prove the input screen stays responsive.
        await _enterText(tester, layup, '[0/90]1000001');
        await _tap(tester, find.text('Calculate'));
        expect(find.byType(LaminatePlatePropertiesResultPage), findsNothing);
        await _show(tester, layup);
        expect(find.text('Too many layers'), findsOneWidget);
      }

      // Build an explicitly symmetric layup with every helper button. Closing
      // the bracket is the final edit, so a helper that fails to update the
      // calculation model cannot be masked by a later keyboard edit.
      await _enterText(tester, layup, '');
      await _tap(tester, _layupButton('['));
      await _enterText(tester, layup, '[0');
      await _tap(tester, _layupButton('/'));
      expect(tester.widget<TextField>(layup).controller!.text, '[0/');
      await _enterText(tester, layup, '[0/90/90/0');
      await _tap(tester, _layupButton(']'));
      const sequence = '[0/90/90/0]';
      expect(tester.widget<TextField>(layup).controller!.text, sequence);

      await _tap(tester, find.text('Calculate'));
      expect(find.byType(LaminatePlatePropertiesResultPage), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('A Matrix (${units.aMatrix})'), findsOneWidget);

      await _tap(tester, find.byTooltip('Export results'));
      expect(find.text('Share as CSV'), findsOneWidget);
      expect(find.text('Share as PDF'), findsOneWidget);
      await _tap(tester, find.text('Copy results'));
      await _waitFor(tester, find.text('Results copied to clipboard'));
      expect(find.text('Results copied to clipboard'), findsOneWidget);

      // Deliberately use the real Clipboard API: no platform-channel handler
      // is installed by this target.
      final copied = await Clipboard.getData(Clipboard.kTextPlain);
      expect(copied?.text, isNotNull);
      final text = copied!.text!;
      expect(text, startsWith('Laminate Plate Properties\r\n'));
      expect(text, contains('Units\t${units.name} (${units.summary})\r\n'));
      expect(text, contains('Layup sequence\t$sequence\t\r\n'));
      expect(text, contains('Ply thickness\t$thickness\t${units.length}\r\n'));
      expect(text, contains('Result: A Matrix\r\nUnit\t${units.aMatrix}'));
      expect(text, contains('Result: B Matrix\r\nUnit\t${units.bMatrix}'));
      expect(text, contains('Result: D Matrix\r\nUnit\t${units.dMatrix}'));
      expect(text, isNot(contains('NaN')));
      expect(text, isNot(contains('Infinity')));

      final rows = text.split('\r\n');
      final matrixStart = rows.indexOf('Result: A Matrix');
      expect(matrixStart, greaterThanOrEqualTo(0));
      for (var row = 0; row < 3; row++) {
        final cells = rows[matrixStart + 2 + row].split('\t');
        expect(cells, hasLength(3));
        final values = cells.map(double.parse).toList();
        expect(values.every((value) => value.isFinite), isTrue);
        expect(values[row], greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}

Widget _calculatorApp() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NumberPrecisionHelper()),
        ChangeNotifierProvider(create: (_) => UnitSettings()),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LaminatePlatePropertiesPage(),
      ),
    );

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

Finder _layupButton(String symbol) => find.descendant(
      of: find.byType(LayupSequenceRow),
      matching: find.widgetWithText(ElevatedButton, symbol),
    );

Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await _hideKeyboard(tester);
  expect(finder, findsOneWidget);
  // The calculator uses a scroll view on phones. Dismiss the native keyboard
  // before revealing a control so it cannot obscure the intended tap target.
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _show(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterText(
    WidgetTester tester, Finder finder, String value) async {
  await _show(tester, finder);
  // The integration binding keeps its last focusedEditable after unfocusing.
  // showKeyboard (called by enterText) only requests focus when that reference
  // changes, so explicitly tap to reopen the native connection for repeated
  // edits to the same field.
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pump();
  expect(
    _enteredText(tester, finder),
    value,
    reason: 'Text entry must reach the field before keyboard dismissal.',
  );
  await _hideKeyboard(tester);
  expect(
    _enteredText(tester, finder),
    value,
    reason: 'Keyboard dismissal must preserve the entered text.',
  );
}

String _enteredText(WidgetTester tester, Finder finder) => tester
    .widget<EditableText>(find.descendant(
      of: finder,
      matching: find.byType(EditableText),
    ))
    .controller
    .text;

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final watch = Stopwatch()..start();
  while (finder.evaluate().isEmpty &&
      watch.elapsed < const Duration(seconds: 10)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
