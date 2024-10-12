import 'analysis_type.dart';

class LaminatePlatePropertiesInput {
  AnalysisType analysisType;
  double E1;
  double E2;
  double G12;
  double nu12;
  String layupSequence;
  double layerThickness;

  double alpha11;
  double alpha22;
  double alpha12;

  LaminatePlatePropertiesInput({
    this.analysisType = AnalysisType.elastic,
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.layupSequence = "",
    this.layerThickness = 0,
    this.alpha11 = 0,
    this.alpha22 = 0,
    this.alpha12 = 0,
  });

  // Factory method to create an instance with default values
  factory LaminatePlatePropertiesInput.withDefaults() {
    return LaminatePlatePropertiesInput(
      E1: 150000,
      E2: 10000,
      G12: 5000,
      nu12: 0.3,
      layupSequence: "[0/90/45/-45]s",
      layerThickness: 0.125
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_type': analysisType.toJson(),
      'E1': E1,
      'E2': E2,
      'G12': G12,
      'nu12': nu12,
      'layup_sequence': layupSequence,
      'layer_thickness': layerThickness,
      'alpha11': alpha11,
      'alpha22': alpha22,
      'alpha12': alpha12,
    };
  }

  // Factory method to create an instance from a JSON map
  factory LaminatePlatePropertiesInput.fromJson(Map<String, dynamic> json) {
    return LaminatePlatePropertiesInput(
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
      layupSequence: (json['layup_sequence'] ?? "").toString(),
      layerThickness: (json['layer_thickness'] ?? 0).toDouble(),
      alpha11: (json['alpha11'] ?? 0).toDouble(),
      alpha22: (json['alpha22'] ?? 0).toDouble(),
      alpha12: (json['alpha12'] ?? 0).toDouble(),
    );
  }
}