import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/unit_system_picker.dart';
import 'package:swiftcomp/util/others.dart';

const _storageKey = 'Calculator_Unit_System';

class _TestPreferences extends Fake implements SharedPreferences {
  _TestPreferences({required this.read, required this.write});

  final Object? Function() read;
  final Future<bool> Function(String value) write;

  @override
  Object? get(String key) => read();

  @override
  Future<bool> setString(String key, String value) => write(value);
}

Future<void> _initialize([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  await SharedPreferencesHelper.init();
}

void _usePreferences(_TestPreferences preferences) {
  final original = SharedPreferencesHelper.localStorage;
  SharedPreferencesHelper.localStorage = preferences;
  addTearDown(() => SharedPreferencesHelper.localStorage = original);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Capture bootstrap behavior before any test initializes static preferences.
  final earlySettings = UnitSettings();
  final beforeInitialization = earlySettings.system;
  final earlySave = earlySettings.setSystem(UnitSystem.us);
  final earlySelection = earlySettings.system;
  earlySettings.dispose();

  setUp(_initialize);

  test('bootstrap reads default safely and preserves an early selection',
      () async {
    expect(beforeInitialization, UnitSystem.si);
    expect(earlySelection, UnitSystem.us);
    await expectLater(earlySave, completes);
  });

  test('missing, unknown and wrong-type saved values safely use SI', () async {
    for (final stored in <Object?>[
      null,
      'unknown',
      'US',
      1,
      true,
      1.5,
      <String>['us'],
      'si',
      'us',
    ]) {
      await _initialize({if (stored != null) _storageKey: stored});
      final settings = UnitSettings();
      expect(settings.system, stored == 'us' ? UnitSystem.us : UnitSystem.si,
          reason: '$stored');
      settings.dispose();
    }
  });

  test('selection notifies synchronously only on changes and survives reload',
      () async {
    final settings = UnitSettings();
    addTearDown(settings.dispose);
    final notifications = <UnitSystem>[];
    settings.addListener(() => notifications.add(settings.system));

    final firstSave = settings.setSystem(UnitSystem.us);
    expect(settings.units.modulus, 'Msi');
    expect(notifications, [UnitSystem.us]);
    await firstSave;
    expect(SharedPreferencesHelper.localStorage.getString(_storageKey), 'us');
    final reloaded = UnitSettings();
    expect(reloaded.system, UnitSystem.us);
    reloaded.dispose();

    await settings.setSystem(UnitSystem.us);
    expect(notifications, [UnitSystem.us]);
    await settings.setSystem(UnitSystem.si);
    expect(notifications, [UnitSystem.us, UnitSystem.si]);
    final finalReload = UnitSettings();
    expect(finalReload.system, UnitSystem.si);
    finalReload.dispose();
  });

  for (final failure in [
    'false result',
    'synchronous throw',
    'asynchronous throw'
  ]) {
    test('$failure does not lose the session choice or escape the setter',
        () async {
      _usePreferences(_TestPreferences(
        read: () => throw StateError('Read failed'),
        write: (_) {
          if (failure == 'synchronous throw') throw StateError('Write failed');
          if (failure == 'asynchronous throw') {
            return Future<bool>.error(StateError('Write failed'));
          }
          return Future<bool>.value(false);
        },
      ));
      final settings = UnitSettings();
      addTearDown(settings.dispose);
      var notifications = 0;
      settings.addListener(() => notifications++);
      expect(settings.system, UnitSystem.si);
      final saved = settings.setSystem(UnitSystem.us);
      expect(settings.system, UnitSystem.us);
      expect(notifications, 1);
      await expectLater(saved, completes);
      await expectLater(settings.setSystem(UnitSystem.us), completes);
      expect(settings.system, UnitSystem.us);
      expect(notifications, 1);
    });
  }

  test('rapid choices serialize writes and recover after failed queued writes',
      () async {
    Object? stored;
    final writes = <String>[];
    final pending = <Completer<bool>>[];
    _usePreferences(_TestPreferences(
      read: () => stored,
      write: (value) {
        writes.add(value);
        final completion = Completer<bool>();
        pending.add(completion);
        return completion.future.then((success) {
          if (success) stored = value;
          return success;
        });
      },
    ));
    final settings = UnitSettings();
    addTearDown(settings.dispose);
    final first = settings.setSystem(UnitSystem.us);
    final second = settings.setSystem(UnitSystem.si);
    final last = settings.setSystem(UnitSystem.us);
    expect(settings.system, UnitSystem.us);
    expect(writes, ['us']);

    pending[0].complete(false);
    await first;
    await Future<void>.value();
    expect(writes, ['us', 'si']);
    pending[1].completeError(StateError('Second write failed'));
    await second;
    await Future<void>.value();
    expect(writes, ['us', 'si', 'us']);
    pending[2].complete(true);
    await last;
    expect(stored, 'us');
    expect(settings.system, UnitSystem.us);
    final reloaded = UnitSettings();
    expect(reloaded.system, UnitSystem.us);
    reloaded.dispose();
  });

  test('a listener selection is persisted after the selection that notified it',
      () async {
    Object? stored;
    final writes = <String>[];
    _usePreferences(_TestPreferences(
      read: () => stored,
      write: (value) async {
        writes.add(value);
        stored = value;
        return true;
      },
    ));
    final settings = UnitSettings();
    addTearDown(settings.dispose);
    Future<void>? listenerSave;
    settings.addListener(() {
      if (settings.system == UnitSystem.us) {
        listenerSave = settings.setSystem(UnitSystem.si);
      }
    });
    await settings.setSystem(UnitSystem.us);
    await listenerSave;
    expect(writes, ['us', 'si']);
    expect(settings.system, UnitSystem.si);
    expect(stored, 'si');
  });

  test('disposing during a pending write does not notify after disposal',
      () async {
    final pending = Completer<bool>();
    _usePreferences(_TestPreferences(
      read: () => null,
      write: (_) => pending.future,
    ));
    final settings = UnitSettings();
    var notifications = 0;
    settings.addListener(() => notifications++);
    final saved = settings.setSystem(UnitSystem.us);
    expect(notifications, 1);
    settings.dispose();
    pending.complete(true);
    await expectLater(saved, completes);
    expect(notifications, 1);
  });

  testWidgets('picker changes immediately without converting entered numbers',
      (tester) async {
    final writes = <String>[];
    final pending = <Completer<bool>>[];
    _usePreferences(_TestPreferences(
      read: () => null,
      write: (value) {
        writes.add(value);
        final completion = Completer<bool>();
        pending.add(completion);
        return completion.future;
      },
    ));
    final settings = UnitSettings();
    addTearDown(settings.dispose);
    final input = TextEditingController();
    addTearDown(input.dispose);
    await tester.pumpWidget(_pickerApp(settings, input));
    await tester.enterText(find.byType(TextField), '181');
    await tester.tap(find.widgetWithText(TextButton, 'SI'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('US customary'));
    await tester.pump();
    expect(settings.system, UnitSystem.us);
    expect(
        tester
            .widget<RadioGroup<UnitSystem>>(find.byType(RadioGroup<UnitSystem>))
            .groupValue,
        UnitSystem.us);
    expect(find.text('E1 (Msi)'), findsOneWidget);
    expect(input.text, '181');
    expect(writes, ['us']);

    await tester.tap(find.text('SI').last);
    await tester.pump();
    expect(settings.system, UnitSystem.si);
    expect(
        tester
            .widget<RadioGroup<UnitSystem>>(find.byType(RadioGroup<UnitSystem>))
            .groupValue,
        UnitSystem.si);
    expect(find.text('E1 (GPa)'), findsOneWidget);
    expect(input.text, '181');
    expect(writes, ['us']);

    pending[0].complete(false);
    await tester.pump();
    expect(writes, ['us', 'si']);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(RadioGroup<UnitSystem>), findsNothing);
    pending[1].completeError(StateError('Storage unavailable'));
    await tester.pumpAndSettle();
    expect(settings.system, UnitSystem.si);
    expect(input.text, '181');
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker handles a synchronous storage failure safely',
      (tester) async {
    _usePreferences(_TestPreferences(
      read: () => null,
      write: (_) => throw StateError('Storage unavailable'),
    ));
    final settings = UnitSettings();
    addTearDown(settings.dispose);
    final input = TextEditingController(text: '26.25');
    addTearDown(input.dispose);
    await tester.pumpWidget(_pickerApp(settings, input));
    await tester.tap(find.widgetWithText(TextButton, 'SI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('US customary'));
    await tester.pumpAndSettle();
    expect(settings.units.modulus, 'Msi');
    expect(find.text('E1 (Msi)'), findsOneWidget);
    expect(input.text, '26.25');
    expect(tester.takeException(), isNull);
  });
}

Widget _pickerApp(UnitSettings settings, TextEditingController input) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      home: Builder(builder: (context) {
        final units = context.watch<UnitSettings>().units;
        return Scaffold(
          appBar: AppBar(actions: const [UnitSystemButton()]),
          body: TextField(
            controller: input,
            decoration: InputDecoration(labelText: 'E1 (${units.modulus})'),
          ),
        );
      }),
    ),
  );
}
