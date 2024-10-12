import 'package:composite_calculator/calculators/lamina_engineering_constants_calculator.dart';
import 'package:composite_calculator/calculators/laminate_plate_properties_calculator.dart';
import 'package:composite_calculator/models/lamina_engineering_constants_input.dart';
import 'package:composite_calculator/models/laminate_plate_properties_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaminatePlatePropertiesCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = LaminatePlatePropertiesInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = LaminatePlatePropertiesCalculator.calculate(input);

      // Assert:
      List<List<double>> expectedA = [
        [63616.70020120725, 19884.305835010055, 2.2638717237759177e-14],
        [19884.305835010055, 63616.70020120723, 1.9648901387141773e-12],
        [2.263871723775917e-14, 1.9648901387141773e-12, 21866.19718309859]
      ];

      List<List<double>> expectedB = [
        [0.0, -1.1368683772161603e-13, 7.074599136799743e-15],
        [
          -1.1368683772161603e-13,
          -3.410605131648481e-13,
          -1.2493627684232382e-13
        ],
        [7.074599136799741e-15, -1.1249439120707794e-14, 0.0]
      ];

      List<List<double>> expectedD = [
        [8006.057176391683, 602.8881623071763, 275.08802816901414],
        [602.8881623071763, 4705.000838363513, 275.08802816901425],
        [275.08802816901414, 275.0880281690143, 768.0457746478874]
      ];

      for (int i = 0; i < output.A.length; i++) {
        for (int j = 0; j < output.A[i].length; j++) {
          expect(output.A[i][j], closeTo(expectedA[i][j], 1e-3));
        }
      }
      for (int i = 0; i < output.B.length; i++) {
        for (int j = 0; j < output.B[i].length; j++) {
          expect(output.B[i][j], closeTo(expectedB[i][j], 1e-3));
        }
      }
      for (int i = 0; i < output.D.length; i++) {
        for (int j = 0; j < output.D[i].length; j++) {
          expect(output.D[i][j], closeTo(expectedD[i][j], 1e-3));
        }
      }

      expect(output.inPlaneProperties.E1, closeTo(57401.57717078148, 1e-3));
      expect(output.inPlaneProperties.E2, closeTo(57401.57717078147, 1e-3));
      expect(output.inPlaneProperties.G12, closeTo(21866.19718309859, 1e-3));
      expect(output.inPlaneProperties.nu12, closeTo(0.312564244484858, 1e-5));
      expect(output.inPlaneProperties.eta121,
          closeTo(-1.030486815205974e-17, 1e-5));
      expect(output.inPlaneProperties.eta122,
          closeTo(3.410732216189378e-17, 1e-5));

      expect(output.flexuralProperties.E1, closeTo(94227.69205595773, 1e-3));
      expect(output.flexuralProperties.E2, closeTo(54891.6513180624, 1e-3));
      expect(output.flexuralProperties.G12, closeTo(8936.487112074954, 1e-3));
      expect(
          output.flexuralProperties.nu12, closeTo(0.10948959541430607, 1e-5));
      expect(
          output.flexuralProperties.eta121, closeTo(0.03024905861937437, 1e-5));
      expect(output.flexuralProperties.eta122,
          closeTo(0.054591112229385966, 1e-5));
    });

    test('Custom input test case', () {
      // Arrange: Create custom input data
      var input = LaminatePlatePropertiesInput(
          E1: 200000,
          E2: 10000,
          G12: 5000,
          nu12: 0.3,
          layupSequence: "[0/90/45/-45]s",
          layerThickness: 0.125);

      // Act: Calculate the output using the calculator
      var output = LaminatePlatePropertiesCalculator.calculate(input);

      // Assert:
      List<List<double>> expectedA = [
        [82359.36715218483, 26128.8297338021, 2.271993528051501e-14],
        [26128.8297338021, 82359.3671521848, 3.2571113306334796e-12],
        [2.2719935280515002e-14, 3.2571113306334796e-12, 28115.268709191358]
      ];

      for (int i = 0; i < output.A.length; i++) {
        for (int j = 0; j < output.A[i].length; j++) {
          expect(output.A[i][j], closeTo(expectedA[i][j], 1e-3));
        }
      }
    });
  });
}
