import 'package:composite_calculator/models/analysis_type.dart';
import 'package:composite_calculator/models/tensor_type.dart';

class LaminaStressStrainInput {
  AnalysisType analysisType;
  double E1;
  double E2;
  double G12;
  double nu12;
  double layupAngle;

  double alpha11;
  double alpha22;
  double alpha12;
  double deltaT;

  TensorType tensorType;

  double sigma11;
  double sigma22;
  double sigma12;

  double epsilon11;
  double epsilon22;
  double gamma12;

  LaminaStressStrainInput({
    this.analysisType = AnalysisType.elastic,
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.layupAngle = 0,
    this.alpha11 = 0,
    this.alpha22 = 0,
    this.alpha12 = 0,
    this.deltaT = 0,
    this.tensorType = TensorType.stress,
    this.sigma11 = 0,
    this.sigma22 = 0,
    this.sigma12 = 0,
    this.epsilon11 = 0,
    this.epsilon22 = 0,
    this.gamma12 = 0,
  });

  // Factory method to create an instance with default values
  factory LaminaStressStrainInput.withDefaults() {
    return LaminaStressStrainInput(
      E1: 150000,
      E2: 10000,
      G12: 5000,
      nu12: 0.3,
      layupAngle: 45,
      sigma11: 0.1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_type': analysisType.toJson(),
      'E1': E1,
      'E2': E2,
      'G12': G12,
      'nu12': nu12,
      'layup_angle': layupAngle,
      'alpha11': alpha11,
      'alpha22': alpha22,
      'alpha12': alpha12,
      'deltaT': deltaT,
      'tensorType': tensorType,
      'sigma11': sigma11,
      'sigma22': sigma22,
      'sigma12': sigma12,
      'epsilon11': epsilon11,
      'epsilon22': epsilon22,
      'gamma12': gamma12,
    };
  }

  // Factory method to create an instance from a JSON map
  factory LaminaStressStrainInput.fromJson(Map<String, dynamic> json) {
    return LaminaStressStrainInput(
      analysisType: AnalysisType.values.firstWhere(
        (e) =>
            e.toString() ==
            'AnalysisType.' + (json['analysis_type'] ?? 'elastic'),
        orElse: () => AnalysisType.elastic, // Default value if not found
      ),
      E1: (json['E1'] ?? 0).toDouble(),
      E2: (json['E2'] ?? 0).toDouble(),
      G12: (json['G12'] ?? 0).toDouble(),
      nu12: (json['nu12'] ?? 0).toDouble(),
      layupAngle: (json['layup_angle'] ?? 0).toDouble(),
      alpha11: (json['alpha11'] ?? 0).toDouble(),
      alpha22: (json['alpha22'] ?? 0).toDouble(),
      alpha12: (json['alpha12'] ?? 0).toDouble(),
      deltaT: (json['deltaT'] ?? 0).toDouble(),
      tensorType: TensorType.values.firstWhere(
        (e) => e.toString() == 'TensorType.' + (json['tensorType'] ?? 'stress'),
        orElse: () => TensorType.stress, // Default value if not found
      ),
      sigma11: (json['sigma11'] ?? 0).toDouble(),
      sigma22: (json['sigma22'] ?? 0).toDouble(),
      sigma12: (json['sigma12'] ?? 0).toDouble(),
      epsilon11: (json['epsilon11'] ?? 0).toDouble(),
      epsilon22: (json['epsilon22'] ?? 0).toDouble(),
      gamma12: (json['gamma12'] ?? 0).toDouble(),
    );
  }
}
