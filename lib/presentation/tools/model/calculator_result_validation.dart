import 'dart:math' as math;

import 'package:composite_calculator/composite_calculator.dart';
import 'package:linalg/matrix.dart';

import 'failure_criteria.dart';

/// Checks numerical results before they reach result widgets, charts or exports.
/// This leaves the calculators' formulas and valid finite results unchanged.
class CalculatorResultValidation {
  const CalculatorResultValidation._();

  static bool laminaStressStrain(LaminaStressStrainOutput output) =>
      _matrix(output.Q, 3) &&
      _matrix(output.S, 3) &&
      [
        output.sigma11,
        output.sigma22,
        output.sigma12,
        output.epsilon11,
        output.epsilon22,
        output.gamma12
      ].every((value) => value.isFinite);

  static bool engineeringConstants(LaminaEngineeringConstantsOutput output) =>
      _matrix(output.Q, 3) &&
      _matrix(output.S, 3) &&
      [
        output.E1,
        output.E2,
        output.G12,
        output.nu12,
        output.eta1_12,
        output.eta2_12,
        if (output.analysisType == AnalysisType.thermalElastic) ...[
          output.alpha_11,
          output.alpha_22,
          output.alpha_12,
        ]
      ].every((value) => value.isFinite);

  static bool rulesOfMixture(UDFRCRulesOfMixtureOutput output) => [
        output.voigtRulesOfMixture,
        output.reussRulesOfMixture,
        output.hybirdRulesOfMixture
      ].every((result) =>
          _matrix(result.stiffness, 6) &&
          _matrix(result.compliance, 6) &&
          const [
            'E1',
            'E2',
            'E3',
            'G12',
            'G13',
            'G23',
            'nu12',
            'nu13',
            'nu23'
          ].every(
              (key) => result.engineeringConstants[key]?.isFinite ?? false) &&
          result.engineeringConstants.values.every((value) => value.isFinite));

  static bool _matrix(List<List<double>> values, int size) =>
      values.length == size &&
      values.every(
          (row) => row.length == size && row.every((value) => value.isFinite));

  static bool plate(LaminatePlatePropertiesOutput output) =>
      _matrix(output.A, 3) &&
      _matrix(output.B, 3) &&
      _matrix(output.D, 3) &&
      [output.inPlaneProperties, output.flexuralProperties].every(
          (properties) => properties
              .toJson()
              .values
              .every((value) => value is num && value.isFinite));

  static bool threeDimensional(Laminate3DPropertiesOutput output) =>
      _matrix(output.stiffness, 6) &&
      _matrix(output.compliance, 6) &&
      output.engineeringConstants.isNotEmpty &&
      output.engineeringConstants.values.every((value) => value.isFinite);

  static bool stressStrain(
    LaminarStressStrainInput input,
    LaminarStressStrainOutput output,
    List<Matrix> stiffness,
  ) {
    if (stiffness.isEmpty ||
        !output.toJson().values.every((value) => value.isFinite)) {
      return false;
    }
    final totalThickness = stiffness.length * input.layerThickness;
    if (!totalThickness.isFinite || totalThickness <= 0) return false;
    final strains = input.tensorType == TensorType.strain
        ? [input.epsilon11, input.epsilon22, input.epsilon12]
        : [output.epsilon11, output.epsilon22, output.epsilon12];
    final curvatures = input.tensorType == TensorType.strain
        ? [input.kappa11, input.kappa22, input.kappa12]
        : [output.kappa11, output.kappa22, output.kappa12];
    if (![...strains, ...curvatures].every((value) => value.isFinite)) {
      return false;
    }

    // The result page plots the bottom and top of each ply. Validate those
    // derived values too: finite input factors can still overflow on multiply.
    final minima = List.filled(6, double.infinity);
    final maxima = List.filled(6, double.negativeInfinity);
    for (var ply = 0; ply < stiffness.length; ply++) {
      final q = stiffness[ply];
      if (q.m != 3 || q.n != 3) return false;
      for (var row = 0; row < 3; row++) {
        if (!q[row].every((value) => value.isFinite)) return false;
      }
      for (final surface in [ply, ply + 1]) {
        final z = input.layerThickness * surface - totalThickness / 2;
        if (!z.isFinite) return false;
        final epsilon = [
          for (var i = 0; i < 3; i++) strains[i] + curvatures[i] * z,
        ];
        final stress = [
          for (var row = 0; row < 3; row++)
            q[row][0] * epsilon[0] +
                q[row][1] * epsilon[1] +
                q[row][2] * epsilon[2],
        ];
        final values = [...epsilon, ...stress];
        for (var i = 0; i < values.length; i++) {
          final value = values[i];
          if (!value.isFinite) return false;
          minima[i] = math.min(minima[i], value);
          maxima[i] = math.max(maxima[i], value);
        }
      }
    }
    // Chart axis ranges must also remain representable after subtraction and
    // the result widget's padding for constant (or nearly constant) series.
    for (var i = 0; i < minima.length; i++) {
      var maximum = maxima[i];
      final minimum = minima[i];
      final range = maximum - minimum;
      if (!range.isFinite) return false;
      if (range == 0 || (range / minimum).abs() < 0.001) {
        maximum = minimum + 1;
      }
      if (!maximum.isFinite || maximum <= minimum) return false;
    }
    return true;
  }

  static bool failure(LaminateFailureResult result) =>
      result.points.isNotEmpty &&
      [...result.midplaneStrains, ...result.curvatures]
          .every((value) => value.isFinite) &&
      result.points.every((point) =>
          [point.angle, point.z, ...point.globalStress, ...point.materialStress]
              .every((value) => value.isFinite) &&
          point.results.values.every((criterion) =>
              !criterion.strengthRatio.isNaN &&
              criterion.strengthRatio >= 0 &&
              criterion.failureIndex.isFinite));
}
