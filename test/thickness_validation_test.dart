import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/layer_thickness_row.dart';
import 'package:swiftcomp/util/others.dart';

Widget app(LayerThickness thickness, {bool validate = true}) =>
    ChangeNotifierProvider(
      create: (_) => UnitSettings(),
      child: MaterialApp(
        home: Scaffold(
          body: LayerThicknessPage(
            layerThickness: thickness,
            validate: validate,
          ),
        ),
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
  });

  test('thickness must be finite and greater than zero', () {
    final thickness = LayerThickness();
    addTearDown(thickness.dispose);
    for (final invalid in <double?>[
      null,
      0,
      -0.0,
      -0.125,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      thickness.value = invalid;
      expect(thickness.isValid(), isFalse, reason: '$invalid');
    }
    for (final valid in [1e-300, 0.125, 1.0, 1000000.0]) {
      thickness.value = valid;
      expect(thickness.isValid(), isTrue, reason: '$valid');
      expect(thickness.value, valid);
    }
  });

  test('listeners are notified only when the numeric value changes', () {
    final thickness = LayerThickness();
    addTearDown(thickness.dispose);
    var notifications = 0;
    thickness.addListener(() => notifications++);
    thickness.value = null;
    expect(notifications, 0);
    thickness.value = 0.125;
    thickness.value = 0.125;
    expect(notifications, 1);
    thickness.value = double.nan;
    thickness.value = double.nan;
    expect(notifications, 2);
    thickness.value = null;
    expect(notifications, 3);
  });

  testWidgets(
      'invalid thickness has an inline error and recovers while editing',
      (tester) async {
    final thickness = LayerThickness();
    addTearDown(thickness.dispose);
    await tester.pumpWidget(app(thickness));
    expect(find.text('Enter a finite number'), findsOneWidget);

    for (final text in ['0', '-0.125']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(find.text('Thickness must be greater than zero'), findsOneWidget);
      expect(thickness.isValid(), isFalse);
    }
    for (final text in ['', 'invalid', 'NaN', 'Infinity', '-Infinity']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(find.text('Enter a finite number'), findsOneWidget, reason: text);
      expect(thickness.isValid(), isFalse);
    }

    await tester.enterText(find.byType(TextField), '1e-300');
    await tester.pump();
    expect(thickness.value, 1e-300);
    expect(thickness.isValid(), isTrue);
    expect(find.text('Enter a finite number'), findsNothing);
    expect(find.text('Thickness must be greater than zero'), findsNothing);
  });

  testWidgets('validation and parent rebuilds preserve typed text',
      (tester) async {
    final thickness = LayerThickness();
    addTearDown(thickness.dispose);
    await tester.pumpWidget(app(thickness, validate: false));
    expect(find.text('Enter a finite number'), findsNothing);

    await tester.enterText(find.byType(TextField), '0.000');
    await tester.pumpWidget(app(thickness));
    expect(find.text('Thickness must be greater than zero'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '0.000');

    await tester.enterText(find.byType(TextField), '0.1250');
    await tester.pumpWidget(app(thickness));
    expect(thickness.value, 0.125);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '0.1250');
    expect(find.text('Thickness must be greater than zero'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('model updates and replacement never edit a stale model',
      (tester) async {
    final oldThickness = LayerThickness()..value = 0.125;
    final newThickness = LayerThickness()..value = 0.5;
    addTearDown(oldThickness.dispose);
    addTearDown(newThickness.dispose);
    await tester.pumpWidget(app(oldThickness));
    expect(find.text('0.125'), findsOneWidget);

    oldThickness.value = 0.25;
    await tester.pump();
    expect(find.text('0.25'), findsOneWidget);

    await tester.pumpWidget(app(newThickness));
    expect(find.text('0.5'), findsOneWidget);
    oldThickness.value = -1;
    await tester.pump();
    expect(find.text('0.5'), findsOneWidget);
    expect(find.text('Thickness must be greater than zero'), findsNothing);

    await tester.enterText(find.byType(TextField), '0.75');
    await tester.pump();
    expect(newThickness.value, 0.75);
    expect(oldThickness.value, -1);
    await tester.pumpWidget(const SizedBox.shrink());
    newThickness.value = 1;
    expect(tester.takeException(), isNull);
  });
}
