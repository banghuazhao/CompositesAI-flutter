import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';

Widget app(LayupSequence sequence) => MaterialApp(
      home: Scaffold(
        body: LayupSequenceRow(layupSequence: sequence, validate: true),
      ),
    );

void main() {
  testWidgets('initializes from the model and clearing invalidates old inputs',
      (tester) async {
    final sequence = LayupSequence()..value = '[0/90]s';
    await tester.pumpWidget(app(sequence));
    expect(find.text('[0/90]s'), findsOneWidget);
    expect(find.text('Wrong layup sequence'), findsNothing);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pump();

    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(sequence.stringValue, '');
    expect(sequence.layups, isNull);
    expect(sequence.isValid(), isFalse);
    expect(find.text('Wrong layup sequence'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('typing and all helper buttons synchronize text and parsed state',
      (tester) async {
    final sequence = LayupSequence();
    await tester.pumpWidget(app(sequence));

    await tester.tap(find.widgetWithText(ElevatedButton, '['));
    await tester.pump();
    expect(sequence.stringValue, '[');
    expect(sequence.isValid(), isFalse);

    await tester.enterText(find.byType(TextField), '[0');
    await tester.tap(find.widgetWithText(ElevatedButton, '/'));
    await tester.pump();
    expect(sequence.stringValue, '[0/');
    expect(sequence.isValid(), isFalse);

    await tester.enterText(find.byType(TextField), '[0/90');
    await tester.tap(find.widgetWithText(ElevatedButton, ']'));
    await tester.pump();
    expect(sequence.stringValue, '[0/90]');
    expect(sequence.layups, [0, 90]);
    expect(sequence.isValid(), isTrue);
    expect(find.text('Wrong layup sequence'), findsNothing);

    await tester.enterText(find.byType(TextField), '[0/90]s');
    await tester.pump();
    expect(sequence.stringValue, '[0/90]s');
    expect(sequence.layups, [0, 90, 90, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an oversized input error and recovers after editing',
      (tester) async {
    final sequence = LayupSequence();
    await tester.pumpWidget(app(sequence));

    await tester.enterText(find.byType(TextField), '[0]999999999999999999999');
    await tester.pump();
    expect(sequence.isValid(), isFalse);
    expect(sequence.layups, isNull);
    expect(find.text('Too many layers'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '[0/90]s');
    await tester.pump();
    expect(sequence.layups, [0, 90, 90, 0]);
    expect(find.text('Too many layers'), findsNothing);
    expect(find.text('Wrong layup sequence'), findsNothing);
  });

  testWidgets('replacing the model updates the controller and future edits',
      (tester) async {
    final oldSequence = LayupSequence()..value = '[0/90]';
    await tester.pumpWidget(app(oldSequence));

    final newSequence = LayupSequence()..stringValue = '[45/-45]s';
    await tester.pumpWidget(app(newSequence));
    expect(find.text('[45/-45]s'), findsOneWidget);
    expect(newSequence.layups, [45, -45, -45, 45]);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pump();
    expect(newSequence.isValid(), isFalse);
    expect(oldSequence.stringValue, '[0/90]');
    expect(oldSequence.layups, [0, 90]);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
