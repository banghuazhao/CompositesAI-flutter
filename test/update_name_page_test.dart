import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/update_name_page.dart';

class _Settings extends ChangeNotifier implements SettingsViewModel {
  @override
  int sessionGeneration = 7;
  final names = <String>[];
  final generations = <int?>[];
  Future<bool> Function()? respond;

  @override
  Future<bool> updateUserName(
    String name, {
    int? expectedSessionGeneration,
  }) async {
    names.add(name);
    generations.add(expectedSessionGeneration);
    if (expectedSessionGeneration != sessionGeneration) return false;
    return await respond!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigation extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

void main() {
  final input = find.byKey(const ValueKey('name_input'));
  final textInput =
      find.descendant(of: input, matching: find.byType(TextField));
  final save = find.byKey(const ValueKey('name_save'));
  const errorText = 'Could not update your name. Please try again.';
  late _Settings settings;
  late GlobalKey<NavigatorState> navigator;
  late _Navigation navigation;
  Object? pageResult;

  setUp(() {
    settings = _Settings();
    navigator = GlobalKey<NavigatorState>();
    navigation = _Navigation();
    pageResult = null;
  });

  Future<void> openPage(
    WidgetTester tester, {
    int? expectedSessionGeneration,
  }) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
    });
    await tester.pumpWidget(ChangeNotifierProvider<SettingsViewModel>.value(
      value: settings,
      child: MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [navigation],
        home: const Scaffold(body: Text('Account page')),
      ),
    ));
    unawaited(navigator.currentState!
        .push<String>(MaterialPageRoute<String>(
          builder: (_) => UpdateNamePage(
            currentName: 'Current name',
            expectedSessionGeneration: expectedSessionGeneration,
          ),
        ))
        .then((value) => pageResult = value));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the current name in an editable name field',
      (tester) async {
    await openPage(tester);

    final field = tester.widget<TextField>(textInput);
    expect(field.controller!.text, 'Current name');
    expect(field.readOnly, isFalse);
    expect(field.textInputAction, TextInputAction.done);
    expect(field.autofillHints, contains(AutofillHints.name));
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
    expect(settings.names, isEmpty);
  });

  testWidgets(
      'Save and Done reject whitespace inline without sending a request',
      (tester) async {
    await openPage(tester);
    await tester.enterText(input, '   ');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Name cannot be empty'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(settings.names, isEmpty);
    expect(navigation.pops, 0);
    expect(find.text('Name cannot be empty'), findsOneWidget);
  });

  for (final action in ['Save', 'Done']) {
    testWidgets('$action trims the name and returns refresh only after success',
        (tester) async {
      final response = Completer<bool>();
      settings.respond = () => response.future;
      await openPage(tester);
      await tester.enterText(input, '  Updated name  ');
      if (action == 'Save') {
        await tester.tap(save);
      } else {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      await tester.pump();

      expect(settings.names, ['Updated name']);
      expect(settings.generations, [7]);
      expect(navigation.pops, 0);
      expect(tester.widget<TextField>(textInput).readOnly, isTrue);
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      response.complete(true);
      await tester.pumpAndSettle();

      expect(navigation.pops, 1);
      expect(pageResult, 'refresh');
      expect(find.text('Account page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final throwsError in [false, true]) {
    testWidgets(
        '${throwsError ? 'Thrown' : 'Reported'} failure keeps the draft and permits retry',
        (tester) async {
      final first = Completer<bool>();
      settings.respond = () => first.future;
      await openPage(tester);
      await tester.enterText(input, 'Updated name');
      await tester.tap(save);
      await tester.pump();

      if (throwsError) {
        first.completeError(StateError('Private update diagnostic'));
      } else {
        first.complete(false);
      }
      await tester.pumpAndSettle();

      expect(navigation.pops, 0);
      expect(find.text(errorText), findsOneWidget);
      expect(find.textContaining('Private update diagnostic'), findsNothing);
      expect(
          tester.widget<TextFormField>(input).controller!.text, 'Updated name');
      expect(tester.widget<TextField>(textInput).readOnly, isFalse);
      expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);

      settings.respond = () async => true;
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(settings.names, ['Updated name', 'Updated name']);
      expect(navigation.pops, 1);
      expect(pageResult, 'refresh');
      expect(find.text(errorText), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('repeated Save and Done callbacks share one pending request',
      (tester) async {
    final response = Completer<bool>();
    settings.respond = () => response.future;
    await openPage(tester);
    await tester.enterText(input, 'Updated name');
    final saveAgain = tester.widget<ElevatedButton>(save).onPressed!;
    final doneAgain = tester.widget<TextField>(textInput).onSubmitted!;

    await tester.tap(save);
    saveAgain();
    doneAgain('Updated name');
    await tester.pump();

    expect(settings.names, ['Updated name']);
    expect(navigation.pops, 0);
    response.complete(true);
    await tester.pumpAndSettle();
    expect(navigation.pops, 1);
    expect(tester.takeException(), isNull);
  });

  for (final throwsError in [false, true]) {
    testWidgets(
        'Back permits leaving and late ${throwsError ? 'error' : 'success'} cannot pop the next screen',
        (tester) async {
      final response = Completer<bool>();
      settings.respond = () => response.future;
      await openPage(tester);
      await tester.enterText(input, 'Updated name');
      await tester.tap(save);
      await tester.pump();

      await tester.pageBack();
      await tester.pumpAndSettle();
      unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Next screen')),
      )));
      await tester.pumpAndSettle();
      expect(navigation.pops, 1);

      if (throwsError) {
        response.completeError(StateError('Private update diagnostic'));
      } else {
        response.complete(true);
      }
      await tester.pumpAndSettle();

      expect(navigation.pops, 1);
      expect(pageResult, isNull);
      expect(find.text('Next screen'), findsOneWidget);
      expect(find.text(errorText), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a covered name screen cannot pop a newer route on completion',
      (tester) async {
    final response = Completer<bool>();
    settings.respond = () => response.future;
    await openPage(tester);
    await tester.tap(save);
    await tester.pump();
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Next screen')),
    )));
    await tester.pumpAndSettle();

    response.complete(true);
    await tester.pumpAndSettle();

    expect(navigation.pops, 0);
    expect(pageResult, isNull);
    expect(find.text('Next screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'an old form remains bound to its opening session after a rebuild',
      (tester) async {
    settings.respond = () async => true;
    await openPage(tester);
    await tester.enterText(input, 'Old account draft');
    settings.sessionGeneration++;
    settings.notifyListeners();
    // Trigger inherited MediaQuery dependencies as well as notifier updates.
    tester.view.viewInsets = const FakeViewPadding(bottom: 20);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(settings.generations, [7]);
    expect(settings.sessionGeneration, 8);
    expect(navigation.pops, 0);
    expect(pageResult, isNull);
    expect(find.text(errorText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a parent-supplied old session cannot target a newly built account',
      (tester) async {
    settings.respond = () async => true;
    settings.sessionGeneration = 8;
    await openPage(tester, expectedSessionGeneration: 7);
    await tester.enterText(input, 'Old account draft');

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(settings.generations, [7]);
    expect(navigation.pops, 0);
    expect(pageResult, isNull);
    expect(find.text(errorText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
