import 'package:composite_calculator/calculators/lamina_engineering_constants_calculator.dart';
import 'package:composite_calculator/models/lamina_engineering_constants_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaminaEngineeringConstantsCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = LaminaEngineeringConstantsInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = LaminaEngineeringConstantsCalculator.calculate(input);

      // Assert: Check the output against expected values (you will need to provide real expected values here)
      expect(output.E1, closeTo(4431.314, 1e-3));
      expect(output.E2, closeTo(4431.314, 1e-3));
      expect(output.G12, closeTo(36144.578, 1e-3));
      expect(output.nu12, closeTo(0.77252, 1e-5));
      expect(output.eta1_12, closeTo(0.10339, 1e-5));
      expect(output.eta2_12, closeTo(0.10339, 1e-5));

      // Optionally check the Q and S matrices for expected values
      List<List<double>> expectedQ = [
        [43000.503, 40500.503, -70422.535],
        [40500.503, 43000.503, -70422.535],
        [-70422.535, -70422.535, 154929.577]
      ];

      for (int i = 0; i < output.Q.length; i++) {
        for (int j = 0; j < output.Q[i].length; j++) {
          expect(output.Q[i][j], closeTo(expectedQ[i][j], 1e-3));
        }
      }
    });

    test('Custom input test case', () {
      // Arrange: Create custom input data
      var input = LaminaEngineeringConstantsInput(
          E1: 200000, E2: 12000, G12: 6000, nu12: 0.25, layupAngle: 30);

      // Act: Calculate the output using the calculator
      var output = LaminaEngineeringConstantsCalculator.calculate(input);

      // Assert: Check if the output matches your expected results for custom input
      // Assert: Check the output against expected values (you will need to provide real expected values here)
      expect(output.E1, closeTo(7544.204322200394, 1e-3));
      expect(output.E2, closeTo(5823.475887170155, 1e-3));
      expect(output.G12, closeTo(17036.379769299012, 1e-3));
      expect(output.nu12, closeTo(0.8239685658153242, 1e-5));
      expect(output.eta1_12, closeTo(0.5982210844216282, 1e-5));
      expect(output.eta2_12, closeTo(-0.2642467565080819, 1e-5));

      // Optionally check the Q and S matrices for expected values
      List<List<double>> expectedQ = [
        [115930.52070263491, 40656.68130489335, -125181.96189496155],
        [40656.68130489335, 21576.693851944787, -38243.6600989902],
        [-125181.96189496154, -38243.66009899021, 156581.55583437887]
      ];

      for (int i = 0; i < output.Q.length; i++) {
        for (int j = 0; j < output.Q[i].length; j++) {
          expect(output.Q[i][j], closeTo(expectedQ[i][j], 1e-3));
        }
      }
    });
  });
}
