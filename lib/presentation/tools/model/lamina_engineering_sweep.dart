import 'package:composite_calculator/composite_calculator.dart';

import 'calculator_result_validation.dart';
import 'material_model.dart';
import 'thermal_model.dart';

/// Calculates and validates the complete slider range before opening results.
/// Slider changes then select the same validated data used by charts/exports.
class LaminaEngineeringSweep {
  LaminaEngineeringSweep._(this.results);

  final List<LaminaEngineeringConstantsOutput> results;

  factory LaminaEngineeringSweep.calculate({
    required AnalysisType analysisType,
    required TransverselyIsotropicMaterial material,
    required TransverselyIsotropicCTE cte,
  }) {
    final results = <LaminaEngineeringConstantsOutput>[];
    for (var angle = -90; angle <= 90; angle++) {
      final result = LaminaEngineeringConstantsCalculator.calculate(
        LaminaEngineeringConstantsInput(
          analysisType: analysisType,
          E1: material.e1!,
          E2: material.e2!,
          G12: material.g12!,
          nu12: material.nu12!,
          layupAngle: angle.toDouble(),
          alpha11: cte.alpha11 ?? 0,
          alpha22: cte.alpha22 ?? 0,
          alpha12: cte.alpha12 ?? 0,
        ),
      );
      if (!CalculatorResultValidation.engineeringConstants(result)) {
        throw StateError('Non-finite engineering constants');
      }
      results.add(result);
    }
    final series = <List<double>>[
      [for (final result in results) result.E1],
      [for (final result in results) result.E2],
      [for (final result in results) result.G12],
      [for (final result in results) result.nu12],
      [for (final result in results) result.eta1_12],
      [for (final result in results) result.eta2_12],
      if (analysisType == AnalysisType.thermalElastic) ...[
        [for (final result in results) result.alpha_11],
        [for (final result in results) result.alpha_22],
        [for (final result in results) result.alpha_12],
      ],
    ];
    for (final values in series) {
      final minimum = values.reduce((a, b) => a < b ? a : b);
      final maximum = values.reduce((a, b) => a > b ? a : b);
      if (!(maximum - minimum).isFinite) {
        throw StateError('Unrepresentable chart range');
      }
    }
    return LaminaEngineeringSweep._(List.unmodifiable(results));
  }

  LaminaEngineeringConstantsOutput atAngle(int angle) => results[angle + 90];
}
