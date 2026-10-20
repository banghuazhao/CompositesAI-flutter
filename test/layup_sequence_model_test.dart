import 'package:composite_calculator/utils/layup_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';

void main() {
  test('an uninitialized sequence is invalid', () {
    expect(LayupSequence().isValid(), isFalse);
  });

  test('preserves documented repetition and symmetry order', () {
    final examples = <String, List<double>>{
      '0/90': [0, 90],
      '[0/90]': [0, 90],
      '[0/90]2': [0, 90, 0, 90],
      '[0/90]+2': [0, 90, 0, 90],
      '[0/90]s': [0, 90, 90, 0],
      ' [0/90]s': [0, 90, 90, 0],
      '[0/90]2 ': [0, 90, 0, 90],
      '[0/90]s2 ': [0, 90, 90, 0, 0, 90, 90, 0],
      ' [0/90] 2 s +1 ': [0, 90, 0, 90, 90, 0, 90, 0],
      '[30/-30]2s': [30, -30, 30, -30, -30, 30, -30, 30],
      '[30/-30]s2': [30, -30, -30, 30, 30, -30, -30, 30],
      '[0/45/90]2s2': [
        0,
        45,
        90,
        0,
        45,
        90,
        90,
        45,
        0,
        90,
        45,
        0,
        0,
        45,
        90,
        0,
        45,
        90,
        90,
        45,
        0,
        90,
        45,
        0,
      ],
      ' 0 / -45.5 / +9e1 ': [0, -45.5, 90],
      '[ 0 / -45.5 / +9e1 ]2s1': [
        0,
        -45.5,
        90,
        0,
        -45.5,
        90,
        90,
        -45.5,
        0,
        90,
        -45.5,
        0,
      ],
    };

    for (final example in examples.entries) {
      final sequence = LayupSequence()..value = example.key;
      expect(sequence.isValid(), isTrue, reason: example.key);
      expect(sequence.stringValue, example.key);
      expect(sequence.layups, example.value, reason: example.key);
      // The property calculators reparse the text through this dependency.
      expect(LayupParser.parse(sequence.stringValue), sequence.layups,
          reason: example.key);
    }
  });

  test('invalid text never retains the previous valid layup', () {
    final invalidInputs = [
      '',
      ' ',
      '[]',
      '[ ]',
      '/',
      '0/',
      '/90',
      '0//90',
      '[0/90',
      '0/90]',
      '0/90]2',
      '[[0/90]]',
      '[0/90][45]',
      '[0/90]ss',
      '[0/90]2s2s',
      '[0/90]S',
      '[0/90]s ',
      '[0/90]s\n',
      '[0/90] ',
      '[0/90] s',
      '[0/90]abc',
      '0/90s',
      '[0/90]0',
      '[0/90]-2',
      '[0/90]1.5',
      '[0/90]0s',
      '[0/90]s0',
      '[0/90]2s-1',
      'NaN',
      'Infinity',
      '-Infinity',
      '1e309',
      '[0/NaN]s',
    ];

    final sequence = LayupSequence();
    for (final text in invalidInputs) {
      sequence.value = '[0/90]s';
      sequence.value = text;
      expect(sequence.stringValue, text);
      expect(sequence.layups, isNull, reason: text);
      expect(sequence.isValid(), isFalse, reason: text);
    }
  });

  test('rejects oversized repeats before allocating the expanded sequence', () {
    final sequence = LayupSequence();
    for (final text in [
      '[0/90]500001',
      '[0]500001s',
      '[0]s500001',
      '[0]1000000s1000000',
      '[0]9223372036854775807s9223372036854775807',
      '[0]99999999999999999999999999999999999999999999',
    ]) {
      sequence.value = text;
      expect(sequence.layups, isNull, reason: text);
      expect(sequence.isValid(), isFalse, reason: text);
      expect(sequence.exceedsLayerLimit, isTrue, reason: text);
    }

    sequence.value = '[0/90]s';
    expect(sequence.isValid(), isTrue);
    expect(sequence.exceedsLayerLimit, isFalse);
  });

  test('retains the existing inclusive one-million-layer limit', () {
    final sequence = LayupSequence()..value = '[0/90]250000s';
    expect(sequence.isValid(), isTrue);
    expect(sequence.layups, hasLength(LayupSequence.maxLayers));
    expect(sequence.layups!.take(4), [0, 90, 0, 90]);
    expect(sequence.layups!.skip(LayupSequence.maxLayers - 4), [90, 0, 90, 0]);
    expect(sequence.exceedsLayerLimit, isFalse);
  });

  test('rejects a base sequence above the layer limit', () {
    final sequence = LayupSequence()
      ..value = List.filled(LayupSequence.maxLayers + 1, '0').join('/');
    expect(sequence.layups, isNull);
    expect(sequence.exceedsLayerLimit, isTrue);
  });
}
