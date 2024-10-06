import 'package:composite_calculator/models/analysis_type.dart';

class LaminaEngineeringConstantsInput {
  AnalysisType analysisType;
  double E1;
  double E2;
  double G12;
  double nu12;
  double layupAngle;

  double alpha11;
  double alpha22;
  double alpha12;

  LaminaEngineeringConstantsInput({
    this.analysisType = AnalysisType.elastic,
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.layupAngle = 0,
    this.alpha11 = 0,
    this.alpha22 = 0,
    this.alpha12 = 0,
  });

  // Factory method to create an instance with default values
  factory LaminaEngineeringConstantsInput.withDefaults() {
    return LaminaEngineeringConstantsInput(
      E1: 150000,
      E2: 10000,
      G12: 5000,
      nu12: 0.3,
      layupAngle: 45,
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
    };
  }

  // Factory method to create an instance from a JSON map
  factory LaminaEngineeringConstantsInput.fromJson(Map<String, dynamic> json) {
    return LaminaEngineeringConstantsInput(
      analysisType: AnalysisType.values.firstWhere(
        (e) =>
            e.toString() ==
            'AnalysisType.' + (json['analysis_type'] ?? "elastic"),
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
    );
  }
}
