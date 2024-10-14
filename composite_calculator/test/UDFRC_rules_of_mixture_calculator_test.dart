import 'package:composite_calculator/calculators/laminate_3d_properties_calculator.dart';
import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/laminate_3d_properties_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UDFRCRulesOfMixtureCalculator Tests', () {
    test('Default input test case', () {
      // Arrange: Create input data with default values
      var input = UDFRCRulesOfMixtureInput.withDefaults();

      // Act: Calculate the output using the calculator
      var output = UDFRCRulesOfMixtureCalculator.calculate(input);

      // Assert:
      List<List<double>> expectedVoigtStiffness = [
        [
          49663.80608250527,
          3336.796145739233,
          3336.7961457392335,
          0.0,
          0.0,
          0.0
        ],
        [
          3336.7961457392335,
          7164.619090635349,
          2949.8042758205343,
          0.0,
          0.0,
          0.0
        ],
        [
          3336.796145739233,
          2949.8042758205343,
          7164.619090635349,
          0.0,
          0.0,
          0.0
        ],
        [0.0, 0.0, 0.0, 2107.4074074074074, 0.0, 0.0],
        [0.0, 0.0, 0.0, 0.0, 2407.4074074074074, 0.0],
        [0.0, 0.0, 0.0, 0.0, 0.0, 2407.4074074074074]
      ];

      List<List<double>> expectedVoigtCompliance = [
        [
          2.1069417741194078e-05,
          -6.950900645997087e-06,
          -6.950900645997087e-06,
          0.0,
          0.0,
          0.0
        ],
        [
          -6.950900645997089e-06,
          0.00017035666447795232,
          -6.690168350095812e-05,
          0.0,
          0.0,
          0.0
        ],
        [
          -6.950900645997084e-06,
          -6.690168350095812e-05,
          0.0001703566644779523,
          0.0,
          0.0,
          0.0
        ],
        [0.0, 0.0, 0.0, 0.00047451669595782075, 0.0, 0.0],
        [0.0, 0.0, 0.0, 0.0, 0.00041538461538461537, 0.0],
        [0.0, 0.0, 0.0, 0.0, 0.0, 0.00041538461538461537]
      ];

      for (int i = 0; i < output.voigtRulesOfMixture.stiffness.length; i++) {
        for (int j = 0;
            j < output.voigtRulesOfMixture.stiffness[i].length;
            j++) {
          expect(output.voigtRulesOfMixture.stiffness[i][j],
              closeTo(expectedVoigtStiffness[i][j], 1e-3));
        }
      }
      for (int i = 0; i < output.voigtRulesOfMixture.compliance.length; i++) {
        for (int j = 0;
            j < output.voigtRulesOfMixture.compliance[i].length;
            j++) {
          expect(output.voigtRulesOfMixture.compliance[i][j],
              closeTo(expectedVoigtCompliance[i][j], 1e-3));
        }
      }

      expect(output.voigtRulesOfMixture.engineeringConstants["E1"],
          closeTo(47462.1563957527, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["E2"],
          closeTo(5870.037447988545, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["E3"],
          closeTo(5870.037447988546, 1e-3));

      expect(output.voigtRulesOfMixture.engineeringConstants["G12"],
          closeTo(2407.4074074074074, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["G13"],
          closeTo(2407.4074074074074, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["G23"],
          closeTo(2107.4074074074074, 1e-3));

      expect(output.voigtRulesOfMixture.engineeringConstants["nu12"],
          closeTo(0.32990473355165223, 1e-5));
      expect(output.voigtRulesOfMixture.engineeringConstants["nu13"],
          closeTo(0.32990473355165223, 1e-5));
      expect(output.voigtRulesOfMixture.engineeringConstants["nu23"],
          closeTo(0.392715387484101, 1e-5));
    });

    test('Custom input test case', () {
      // Arrange: Create custom input data
      var input = UDFRCRulesOfMixtureInput(
          analysisType: AnalysisType.thermalElastic,
          E1_fiber: 150000,
          E2_fiber: 10000,
          G12_fiber: 5000,
          nu12_fiber: 0.3,
          nu23_fiber: 0.25,
          alpha11_fiber: 0.1,
          E_matrix: 3500,
          nu_matrix: 0.35,
          alpha_matrix: 0.02,
          fiberVolumeFraction: 0.3);

      // Act: Calculate the output using the calculator
      var output = UDFRCRulesOfMixtureCalculator.calculate(input);

      // Assert:
      expect(output.voigtRulesOfMixture.engineeringConstants["alpha11"],
          closeTo(9.5829e-2, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["alpha22"],
          closeTo(-3.4089e-3, 1e-3));
      expect(output.voigtRulesOfMixture.engineeringConstants["alpha33"],
          closeTo(-3.4089e-3, 1e-3));
    });
  });
}
