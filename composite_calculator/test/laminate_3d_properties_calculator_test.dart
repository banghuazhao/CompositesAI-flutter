import 'package:composite_calculator/calculators/laminate_3d_properties_calculator.dart';
import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/laminate_3d_properties_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Laminate3DPropertiesCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = Laminate3DPropertiesInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = Laminate3DPropertiesCalculator.calculate(input);

      // Assert:
      List<List<double>> expectedStiffness = [
        [
          64721.54471544715,
          20950.54200542005,
          3420.0542005420057,
          0.0,
          0.0,
          2.518159238084159e-14
        ],
        [
          20950.54200542005,
          64721.544715447155,
          3420.054200542005,
          0.0,
          0.0,
          1.968615053474552e-12
        ],
        [
          3420.054200542005,
          3420.054200542005,
          10775.067750677508,
          0.0,
          0.0,
          2.408436210670166e-14
        ],
        [0.0, 0.0, 0.0, 4500.0, 1.4759469852271958e-14, 0.0],
        [0.0, 0.0, 0.0, 1.475946985227196e-14, 4500.0, 0.0],
        [
          2.5181592380841582e-14,
          1.968615053474552e-12,
          2.4084362106701667e-14,
          0.0,
          0.0,
          21885.501355013548
        ]
      ];

      List<List<double>> expectedCompliance = [
        [
          1.7411039446147903e-05,
          -5.43513583169007e-06,
          -3.8012048192771085e-06,
          0.0,
          0.0,
          4.7304386328905965e-22
        ],
        [
          -5.43513583169007e-06,
          1.7411039446147903e-05,
          -3.8012048192771076e-06,
          0.0,
          0.0,
          -1.555697483446916e-21
        ],
        [
          -3.801204819277108e-06,
          -3.801204819277108e-06,
          9.521987951807227e-05,
          0.0,
          0.0,
          2.415078035031392e-22
        ],
        [0.0, 0.0, 0.0, 0.00022222222222222223, -7.2886270875417085e-22, 0.0],
        [0.0, 0.0, 0.0, -7.288627087541709e-22, 0.00022222222222222223, 0.0],
        [
          4.730438632890597e-22,
          -1.5556974834469162e-21,
          2.415078035031391e-22,
          0.0,
          0.0,
          4.569235055567595e-05
        ]
      ];

      for (int i = 0; i < output.stiffness.length; i++) {
        for (int j = 0; j < output.stiffness[i].length; j++) {
          expect(
              output.stiffness[i][j], closeTo(expectedStiffness[i][j], 1e-3));
        }
      }
      for (int i = 0; i < output.compliance.length; i++) {
        for (int j = 0; j < output.compliance[i].length; j++) {
          expect(
              output.compliance[i][j], closeTo(expectedCompliance[i][j], 1e-3));
        }
      }

      expect(
          output.engineeringConstants["E1"], closeTo(57434.824789926286, 1e-3));
      expect(
          output.engineeringConstants["E2"], closeTo(57434.824789926286, 1e-3));
      expect(
          output.engineeringConstants["E3"], closeTo(10502.008667320408, 1e-3));

      expect(output.engineeringConstants["G12"],
          closeTo(21885.501355013548, 1e-3));
      expect(output.engineeringConstants["G13"], closeTo(4500.0, 1e-3));
      expect(output.engineeringConstants["G23"], closeTo(4500.0, 1e-3));

      expect(output.engineeringConstants["nu12"],
          closeTo(0.3121660742025695, 1e-5));
      expect(output.engineeringConstants["nu13"],
          closeTo(0.21832153278580413, 1e-5));
      expect(output.engineeringConstants["nu23"],
          closeTo(0.21832153278580407, 1e-5));
    });

    test('Custom input test case', () {
      // Arrange: Create custom input data
      var input = Laminate3DPropertiesInput(
          analysisType: AnalysisType.thermalElastic,
          E1: 200000,
          E2: 10000,
          G12: 5000,
          nu12: 0.3,
          nu23: 0.25,
          layupSequence: "[0/90/45/-45]s",
          layerThickness: 0.125,
          alpha11: 0.1);

      // Act: Calculate the output using the calculator
      var output = Laminate3DPropertiesCalculator.calculate(input);

      // Assert:
      List<List<double>> expectedStiffness = [
        [
          83453.44129554657,
          27183.535762483127,
          3398.110661268555,
          0.0,
          0.0,
          2.5265570771882806e-14
        ],
        [
          27183.535762483127,
          83453.44129554652,
          3398.110661268555,
          0.0,
          0.0,
          3.2608622670156525e-12
        ],
        [
          3398.110661268555,
          3398.110661268555,
          10747.638326585693,
          0.0,
          0.0,
          2.4168340497742894e-14
        ],
        [0.0, 0.0, 0.0, 4500.0, 1.4759469852271958e-14, 0.0],
        [0.0, 0.0, 0.0, 1.475946985227196e-14, 4500.0, 0.0],
        [
          2.52655707718828e-14,
          3.2608622670156525e-12,
          2.4168340497742894e-14,
          0.0,
          0.0,
          28134.952766531715
        ]
      ];

      for (int i = 0; i < output.stiffness.length; i++) {
        for (int j = 0; j < output.stiffness[i].length; j++) {
          expect(
              output.stiffness[i][j], closeTo(expectedStiffness[i][j], 1e-3));
        }
      }

      expect(
          output.engineeringConstants["alpha11"], closeTo(9.39815e-2, 1e-3));
      expect(
          output.engineeringConstants["alpha22"], closeTo(9.39815e-2, 1e-3));
      expect(
          output.engineeringConstants["alpha12"], closeTo(2.51097e-18, 1e-3));
    });
  });
}
