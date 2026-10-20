import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/calculator_result_validation.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';

void main() {
  for (final units in [Units.si, Units.us]) {
    for (final analysisType in [
      AnalysisType.elastic,
      AnalysisType.thermalElastic,
    ]) {
      test('plate guard accepts ${analysisType.name} results in ${units.name}',
          () {
        final input = LaminatePlatePropertiesInput(
          analysisType: analysisType,
          E1: units.modulusFromGPa(181) * Units.modulusToStress,
          E2: units.modulusFromGPa(10.3) * Units.modulusToStress,
          G12: units.modulusFromGPa(7.17) * Units.modulusToStress,
          nu12: 0.28,
          layupSequence: '[0/90]s',
          layerThickness: units.lengthFromMm(0.125),
          alpha11: units.cteFromPerC(-0.1e-6),
          alpha22: units.cteFromPerC(30e-6),
          alpha12: 0,
        );

        // Match the page's validation point, before display-unit rescaling.
        final output = LaminatePlatePropertiesCalculator.calculate(input);
        expect(output.inPlaneProperties.E1, greaterThan(0));
        expect(CalculatorResultValidation.plate(output), isTrue);
      });

      test('3D guard accepts ${analysisType.name} results in ${units.name}',
          () {
        // The 3D calculator uses GPa/Msi directly, unlike the plate calculator.
        final input = Laminate3DPropertiesInput(
          analysisType: analysisType,
          E1: units.modulusFromGPa(181),
          E2: units.modulusFromGPa(10.3),
          G12: units.modulusFromGPa(7.17),
          nu12: 0.28,
          nu23: 0.4,
          layupSequence: '[0/90]s',
          layerThickness: units.lengthFromMm(0.125),
          alpha11: units.cteFromPerC(-0.1e-6),
          alpha22: units.cteFromPerC(30e-6),
          alpha12: 0,
        );

        final output = Laminate3DPropertiesCalculator.calculate(input);
        expect(output.stiffness[0][0], greaterThan(0));
        expect(CalculatorResultValidation.threeDimensional(output), isTrue);
      });
    }

    test('stress/strain guard accepts both input modes in ${units.name}', () {
      final input = LaminarStressStrainInput(
        E1: units.modulusFromGPa(181) * Units.modulusToStress,
        E2: units.modulusFromGPa(10.3) * Units.modulusToStress,
        G12: units.modulusFromGPa(7.17) * Units.modulusToStress,
        nu12: 0.28,
        layupSequence: '[0/90]s',
        layerThickness: units.lengthFromMm(0.125),
        tensorType: TensorType.stress,
        // 100 N/mm, expressed as stress times length in the chosen units.
        N11: units.stressFromMPa(100) * units.lengthFromMm(1),
      );
      final stiffness = LaminarStressStrainCalculator.getQMatrices(input);
      final strainOutput = LaminarStressStrainCalculator.calculate(input);
      expect(strainOutput.epsilon11, greaterThan(0));
      expect(
        CalculatorResultValidation.stressStrain(input, strainOutput, stiffness),
        isTrue,
      );

      // The same valid state can be prescribed through the strain input mode.
      input
        ..tensorType = TensorType.strain
        ..epsilon11 = strainOutput.epsilon11
        ..epsilon22 = strainOutput.epsilon22
        ..epsilon12 = strainOutput.epsilon12
        ..kappa11 = strainOutput.kappa11
        ..kappa22 = strainOutput.kappa22
        ..kappa12 = strainOutput.kappa12;
      final stressOutput = LaminarStressStrainCalculator.calculate(input);
      expect(stressOutput.N11, greaterThan(0));
      expect(
        CalculatorResultValidation.stressStrain(input, stressOutput, stiffness),
        isTrue,
      );
    });
  }
}
