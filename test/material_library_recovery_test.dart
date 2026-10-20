import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/presentation/tools/model/material_library.dart';
import 'package:swiftcomp/util/others.dart';

const _sourceKey = 'Custom_Materials_v1';
const _backupKey = 'Custom_Materials_Recovery_v1';

LibraryMaterial _entry(String name,
        {String? id, String source = 'Supplier\nRev B'}) =>
    LibraryMaterial(
      id: id ?? name,
      name: name,
      kind: MaterialKind.lamina,
      isCustom: true,
      source: source,
      e1: 150,
      e2: 10,
      g12: 5,
      nu12: 0.3,
      alpha11: -1e-6,
    );

String _mixedSource() => '[${jsonEncode(_entry('First').toJson())},'
    '{"name":"Wrong number","e1":"150","nu12":0.3},'
    '{"name":"Missing constant","e1":150},'
    'null,"not a material",'
    '{"name":"Nonfinite modulus","e1":1e309,"nu12":0.3},'
    '{"name":"Nonfinite optional","e1":150,"nu12":0.3,"g12":1e309},'
    '{"name":"Unknown kind","kind":"unsupported","e1":150,"nu12":0.3},'
    '{"name":" ","e1":150,"nu12":0.3},'
    '{"name":"Wrong metadata","e1":150,"nu12":0.3,"source":42},'
    '${jsonEncode(_entry('Last', source: '  Unchanged supplier text  ').toJson())}]';

List<String> _backupKeys(_Preferences storage) =>
    storage.values.keys.where((key) => key.startsWith(_backupKey)).toList();

Map<String, dynamic> _snapshot(_Preferences storage,
        [String key = _backupKey]) =>
    jsonDecode(storage.values[key] as String) as Map<String, dynamic>;

_Preferences _storage(Object? source) {
  final previous = SharedPreferencesHelper.localStorage;
  final storage = _Preferences();
  if (source != null) storage.values[_sourceKey] = source;
  SharedPreferencesHelper.localStorage = storage;
  addTearDown(() {
    SharedPreferencesHelper.localStorage = previous;
    MaterialLibrary.instance.resetForTest();
  });
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.init();
    MaterialLibrary.instance.resetForTest();
  });

  test(
      'mixed records load independently without changing source or writing backups',
      () {
    final raw = _mixedSource();
    final storage = _storage(raw);
    final materials = MaterialLibrary.instance.customMaterials;
    expect(materials.map((material) => material.name), ['First', 'Last']);
    expect(materials.last.source, '  Unchanged supplier text  ');
    expect(materials.first.e1, 150);
    expect(materials.first.alpha11, -1e-6);
    expect(storage.values[_sourceKey], raw);
    expect(storage.writes, isEmpty);
    expect(_backupKeys(storage), isEmpty);
  });

  test(
      'a repair save preserves exact damaged source before writing valid records',
      () async {
    final raw = _mixedSource();
    final storage = _storage(raw);
    await MaterialLibrary.instance.save(_entry('Added'));
    expect(storage.writes.take(2), [_backupKey, _sourceKey]);
    expect(_snapshot(storage), {
      'version': 1,
      'sourceKey': _sourceKey,
      'type': 'string',
      'value': raw,
    });
    final repaired = jsonDecode(storage.values[_sourceKey] as String) as List;
    expect(repaired.map((record) => (record as Map)['name']),
        ['Added', 'First', 'Last']);
    expect((repaired.last as Map)['source'], '  Unchanged supplier text  ');
    MaterialLibrary.instance.resetForTest();
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Added', 'First', 'Last']);
    await MaterialLibrary.instance.save(_entry('Next healthy save'));
    expect(_backupKeys(storage), [_backupKey]);
    expect(_snapshot(storage)['value'], raw);
  });

  test('deleting a recovered record first protects all original source records',
      () async {
    final raw = _mixedSource();
    final storage = _storage(raw);
    final first = MaterialLibrary.instance.customMaterials.first;
    await MaterialLibrary.instance.remove(first);
    expect(_snapshot(storage)['value'], raw);
    expect(storage.writes.take(2), [_backupKey, _sourceKey]);
    MaterialLibrary.instance.resetForTest();
    expect(MaterialLibrary.instance.customMaterials.single.name, 'Last');
    expect(MaterialLibrary.instance.customMaterials.single.source,
        '  Unchanged supplier text  ');
  });

  test('valid legacy partial records and complete source fields stay intact',
      () async {
    final complete =
        _entry('  Complete name  ', source: '  Supplier\nRevision B  ')
            .toJson();
    final partial = {'name': 'Legacy partial', 'e1': 120, 'nu12': 0.28};
    final storage = _storage(jsonEncode([complete, partial]));
    final loaded = MaterialLibrary.instance.customMaterials;
    expect(loaded, hasLength(2));
    expect(loaded.last.id, 'Legacy partial');
    expect(loaded.last.kind, MaterialKind.lamina);
    await MaterialLibrary.instance.save(_entry('New'));
    final saved = jsonDecode(storage.values[_sourceKey] as String) as List;
    expect(saved[1], complete);
    expect((saved[2] as Map)['name'], 'Legacy partial');
    expect((saved[2] as Map)['e1'], 120);
    expect(_backupKeys(storage), isEmpty);
  });

  for (final raw in ['', '{broken', '{}', 'null', '42', '[null,42,"wrong"]']) {
    test('invalid JSON source/root remains recoverable: $raw', () async {
      final storage = _storage(raw);
      expect(MaterialLibrary.instance.customMaterials, isEmpty);
      expect(storage.values[_sourceKey], raw);
      await MaterialLibrary.instance.save(_entry('Recovered'));
      expect(_snapshot(storage)['value'], raw);
      expect(_snapshot(storage)['type'], 'string');
      MaterialLibrary.instance.resetForTest();
      expect(MaterialLibrary.instance.customMaterials.single.name, 'Recovered');
    });
  }

  for (final source in <Object>[
    true,
    42,
    -0.0,
    3.5,
    double.infinity,
    double.nan,
    <String>['legacy', 'source']
  ]) {
    test(
        'wrong raw preference type is preserved: ${source.runtimeType} $source',
        () async {
      final storage = _storage(source);
      expect(MaterialLibrary.instance.customMaterials, isEmpty);
      await MaterialLibrary.instance.save(_entry('Recovered'));
      final snapshot = _snapshot(storage);
      if (source is int) {
        expect(snapshot['type'], 'int');
        expect(snapshot['value'], source.toString());
      } else if (source is double) {
        expect(snapshot['type'], 'double');
        expect(snapshot['value'], source.toString());
      } else {
        expect(snapshot['value'], source);
        expect(snapshot['type'], source is bool ? 'bool' : 'stringList');
      }
      MaterialLibrary.instance.resetForTest();
      expect(MaterialLibrary.instance.customMaterials.single.name, 'Recovered');
    });
  }

  for (final failure in _Failure.values) {
    test(
        'failed backup ($failure) never changes source/model and permits retry',
        () async {
      final raw = _mixedSource();
      final storage = _storage(raw);
      final before = MaterialLibrary.instance.customMaterials;
      var notifications = 0;
      void changed() => notifications++;
      MaterialLibrary.instance.addListener(changed);
      addTearDown(() => MaterialLibrary.instance.removeListener(changed));
      storage.failures[_backupKey] = [failure];
      await expectLater(
          MaterialLibrary.instance.save(_entry('Added')), throwsA(anything));
      expect(storage.values[_sourceKey], raw);
      expect(MaterialLibrary.instance.customMaterials, before);
      expect(notifications, 0);
      expect(storage.writes.where((key) => key == _sourceKey), isEmpty);
      expect(_backupKeys(storage), isEmpty);

      await MaterialLibrary.instance.save(_entry('Added'));
      expect(_snapshot(storage)['value'], raw);
      expect(
          MaterialLibrary.instance.customMaterials
              .map((material) => material.name),
          ['Added', 'First', 'Last']);
      expect(notifications, 1);
    });
  }

  test('failed backup cleanup is not mistaken for a verified recovery copy',
      () async {
    final raw = _mixedSource();
    final storage = _storage(raw);
    storage.failures[_backupKey] = [_Failure.returnsFalse];
    storage.removeFailures[_backupKey] = 1;
    await expectLater(
        MaterialLibrary.instance.save(_entry('Added')), throwsA(anything));
    expect(storage.values[_sourceKey], raw);
    expect(storage.values.containsKey(_backupKey), isTrue);
    expect(storage.writes.where((key) => key == _sourceKey), isEmpty);

    await MaterialLibrary.instance.save(_entry('Added'));
    expect(storage.writes, contains('$_backupKey.1'));
    expect(_snapshot(storage, '$_backupKey.1')['value'], raw);
    expect(MaterialLibrary.instance.customMaterials.first.name, 'Added');
  });

  for (final failure in _Failure.values) {
    test(
        'main write failure ($failure) rolls back and retains the checked backup',
        () async {
      final raw = _mixedSource();
      final storage = _storage(raw);
      final before = MaterialLibrary.instance.customMaterials;
      storage.failures[_sourceKey] = [failure];
      await expectLater(
          MaterialLibrary.instance.save(_entry('Added')), throwsA(anything));
      expect(storage.values[_sourceKey], raw);
      expect(MaterialLibrary.instance.customMaterials, before);
      expect(_snapshot(storage)['value'], raw);

      await MaterialLibrary.instance.save(_entry('Added'));
      expect(_snapshot(storage)['value'], raw);
      expect(_snapshot(storage, '$_backupKey.1')['value'], raw);
      MaterialLibrary.instance.resetForTest();
      expect(
          MaterialLibrary.instance.customMaterials
              .map((material) => material.name),
          ['Added', 'First', 'Last']);
    });
  }

  test('older damaged backups and later damage episodes are never overwritten',
      () async {
    final original = _mixedSource();
    final storage = _storage(original);
    storage.values[_backupKey] = 'an older damaged recovery copy';
    await MaterialLibrary.instance.save(_entry('Added'));
    final firstRecovery = storage.values['$_backupKey.1'];
    expect(storage.values[_backupKey], 'an older damaged recovery copy');
    expect(_snapshot(storage, '$_backupKey.1')['value'], original);

    const secondDamage = '{different damaged source}';
    storage.values[_sourceKey] = secondDamage;
    MaterialLibrary.instance.resetForTest();
    await MaterialLibrary.instance.save(_entry('Recovered again'));
    expect(storage.values[_backupKey], 'an older damaged recovery copy');
    expect(storage.values['$_backupKey.1'], firstRecovery);
    expect(_snapshot(storage, '$_backupKey.2')['value'], secondDamage);
  });

  test(
      'save and delete serialize across a pending backup without losing recovered records',
      () async {
    final raw = _mixedSource();
    final storage = _storage(raw);
    final first = MaterialLibrary.instance.customMaterials.first;
    final gate = Completer<void>();
    storage.gates[_backupKey] = gate;
    storage.writeStarted = Completer<String>();
    final save = MaterialLibrary.instance.save(_entry('Added'));
    expect(await storage.writeStarted!.future, _backupKey);
    final remove = MaterialLibrary.instance.remove(first);
    expect(storage.values[_sourceKey], raw);
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['First', 'Last']);
    gate.complete();
    await save;
    await remove;
    expect(_backupKeys(storage), [_backupKey]);
    expect(_snapshot(storage)['value'], raw);
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Added', 'Last']);
    MaterialLibrary.instance.resetForTest();
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Added', 'Last']);
  });

  test('a transient public read failure is not cached as an empty library',
      () async {
    final storage = _storage(jsonEncode([_entry('Kept').toJson()]));
    storage.readFailures[_sourceKey] = 1;
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
    await MaterialLibrary.instance.save(_entry('Added'));
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Added', 'Kept']);
    expect(_backupKeys(storage), isEmpty);
  });

  test(
      'a mutation load failure writes nothing and a corrected retry keeps existing records',
      () async {
    final raw = jsonEncode([_entry('Kept').toJson()]);
    final storage = _storage(raw);
    storage.readFailures[_sourceKey] = 1;
    await expectLater(
        MaterialLibrary.instance.save(_entry('Added')), throwsA(anything));
    expect(storage.values[_sourceKey], raw);
    expect(storage.writes, isEmpty);
    await MaterialLibrary.instance.save(_entry('Added'));
    expect(
        MaterialLibrary.instance.customMaterials
            .map((material) => material.name),
        ['Added', 'Kept']);
  });

  test('an unavailable backup slot aborts before overwriting degraded source',
      () async {
    final raw = _mixedSource();
    final storage = _storage(raw);
    storage.readFailures[_backupKey] = 1;
    await expectLater(
        MaterialLibrary.instance.save(_entry('Added')), throwsA(anything));
    expect(storage.values[_sourceKey], raw);
    expect(storage.writes, isEmpty);
    await MaterialLibrary.instance.save(_entry('Added'));
    expect(_snapshot(storage)['value'], raw);
  });

  test('unsupported raw objects fail closed without losing their source',
      () async {
    final raw = {'unsupported': 'preference object'};
    final storage = _storage(raw);
    await expectLater(
        MaterialLibrary.instance.save(_entry('Added')), throwsStateError);
    expect(storage.values[_sourceKey], same(raw));
    expect(storage.writes, isEmpty);
    expect(MaterialLibrary.instance.customMaterials, isEmpty);
  });
}

enum _Failure { returnsFalse, throwsError }

class _Preferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  final writes = <String>[];
  final failures = <String, List<_Failure>>{};
  final readFailures = <String, int>{};
  final removeFailures = <String, int>{};
  final gates = <String, Completer<void>>{};
  Completer<String>? writeStarted;

  @override
  Object? get(String key) {
    final remaining = readFailures[key] ?? 0;
    if (remaining > 0) {
      readFailures[key] = remaining - 1;
      throw StateError('Read unavailable');
    }
    return values[key];
  }

  @override
  String? getString(String key) => get(key) as String?;

  Future<bool> _write(String key, Object value) async {
    // Match legacy SharedPreferences: update cache before the platform result.
    values[key] = value;
    writes.add(key);
    final gate = gates.remove(key);
    if (gate != null) {
      writeStarted?.complete(key);
      await gate.future;
    }
    final queued = failures[key];
    if (queued != null && queued.isNotEmpty) {
      if (queued.removeAt(0) == _Failure.returnsFalse) return false;
      throw StateError('Write unavailable');
    }
    return true;
  }

  @override
  Future<bool> setString(String key, String value) => _write(key, value);
  @override
  Future<bool> setBool(String key, bool value) => _write(key, value);
  @override
  Future<bool> setInt(String key, int value) => _write(key, value);
  @override
  Future<bool> setDouble(String key, double value) => _write(key, value);
  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _write(key, List<String>.of(value));

  @override
  Future<bool> remove(String key) async {
    final remaining = removeFailures[key] ?? 0;
    if (remaining > 0) {
      removeFailures[key] = remaining - 1;
      throw StateError('Removal unavailable');
    }
    values.remove(key);
    return true;
  }
}
