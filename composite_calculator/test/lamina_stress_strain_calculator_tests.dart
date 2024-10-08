import 'package:composite_calculator/calculators/lamina_stress_strain_calculator.dart';
import 'package:composite_calculator/models/lamina_stress_strain_input.dart';
import 'package:composite_calculator/models/tensor_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaminaStressStrainCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = LaminaStressStrainInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = LaminaStressStrainCalculator.calculate(input);

      expect(output.epsilon11, closeTo(2.257 * 10e-5, 1e-3));
      expect(output.epsilon11, closeTo(-1.743 * 10e-5, 1e-3));
      expect(output.epsilon11, closeTo(2.333 * 10e-5, 1e-3));

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

    test('Default input test case with custom strain input', () {
      // Arrange: Create input data with default values
      var input = LaminaStressStrainInput.withDefaults();
      input.tensorType = TensorType.strain;
      input.epsilon11 = 1e-5;

      // Act: Calculate the output using the calculator
      var output = LaminaStressStrainCalculator.calculate(input);

      expect(output.sigma11, closeTo(4.3e-1, 1e-3));
      expect(output.sigma22, closeTo(4.05e-1, 1e-3));
      expect(output.sigma12, closeTo(-7.042e-1, 1e-3));

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
      var input = LaminaStressStrainInput(
          E1: 200000,
          E2: 12000,
          G12: 6000,
          nu12: 0.25,
          layupAngle: 30,
          tensorType: TensorType.strain,
          epsilon11: 1e-5);

      // Act: Calculate the output using the calculator
      var output = LaminaStressStrainCalculator.calculate(input);

      expect(output.sigma11, closeTo(1.159, 1e-3));
      expect(output.sigma22, closeTo(4.066e-1, 1e-3));
      expect(output.sigma12, closeTo(-1.252, 1e-3));
    });
  });
}
