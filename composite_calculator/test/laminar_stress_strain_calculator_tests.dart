import 'package:composite_calculator/calculators/laminar_stress_strain_calculator.dart';
import 'package:composite_calculator/models/laminar_stress_strain_input.dart';
import 'package:composite_calculator/models/tensor_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaminarStressStrainCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = LaminarStressStrainInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = LaminarStressStrainCalculator.calculate(input);

      expect(output.epsilon11, closeTo(0.000017421124109966436, 1e-3));
      expect(output.epsilon22, closeTo(-0.000005445220495508603, 1e-3));
      expect(output.epsilon12, closeTo(4.712693325579657e-22, 1e-3));
      expect(output.kappa11, closeTo(3.261347510124405e-22, 1e-3));
      expect(output.kappa22, closeTo(-1.6068855629179688e-21, 1e-3));
      expect(output.kappa12, closeTo(2.184974840156989e-22, 1e-3));

    });

    test('Default input test case with custom strain input', () {
      // Arrange: Create input data with default values
      var input = LaminarStressStrainInput.withDefaults();
      input.tensorType = TensorType.strain;
      input.epsilon11 = 1e-5;

      // Act: Calculate the output using the calculator
      var output = LaminarStressStrainCalculator.calculate(input);

      expect(output.N11, closeTo(0.6361670020120725, 1e-3));
      expect(output.N22, closeTo(0.19884305835010055, 1e-3));
      expect(output.N12, closeTo(2.2638717237759187e-19, 1e-3));
      expect(output.M11, closeTo(0, 1e-3));
      expect(output.M22, closeTo(0, 1e-3));
      expect(output.M12, closeTo(0, 1e-3));
    });

  });
}
