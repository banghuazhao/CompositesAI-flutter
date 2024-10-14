import 'package:composite_calculator/models/analysis_type.dart';

class UDFRCRulesOfMixtureInput {
  AnalysisType analysisType;
  double E1_fiber;
  double E2_fiber;
  double G12_fiber;
  double nu12_fiber;
  double nu23_fiber;
  double alpha11_fiber;
  double alpha22_fiber;
  double E_matrix;
  double nu_matrix;
  double alpha_matrix;
  double fiberVolumeFraction;

  UDFRCRulesOfMixtureInput({
    this.analysisType = AnalysisType.elastic,
    this.E1_fiber = 0,
    this.E2_fiber = 0,
    this.G12_fiber = 0,
    this.nu12_fiber = 0,
    this.nu23_fiber = 0,
    this.alpha11_fiber = 0,
    this.alpha22_fiber = 0,
    this.E_matrix = 0,
    this.nu_matrix = 0,
    this.alpha_matrix = 0,
    this.fiberVolumeFraction = 0,
  });

  // Factory method to create an instance with default values
  factory UDFRCRulesOfMixtureInput.withDefaults() {
    return UDFRCRulesOfMixtureInput(
        E1_fiber: 150000,
        E2_fiber: 10000,
        G12_fiber: 5000,
        nu12_fiber: 0.3,
        nu23_fiber: 0.25,
        E_matrix: 3500,
        nu_matrix: 0.35,
        fiberVolumeFraction: 0.3
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_type': analysisType.toJson(),
      'E1_fiber': E1_fiber,
      'E2_fiber': E2_fiber,
      'G12_fiber': G12_fiber,
      'nu12_fiber': nu12_fiber,
      'nu23_fiber': nu23_fiber,
      'alpha11_fiber': alpha11_fiber,
      'alpha22_fiber': alpha22_fiber,
      'E_matrix': E_matrix,
      'nu_matrix': nu_matrix,
      'alpha_matrix': alpha_matrix,
      'fiberVolumeFraction': fiberVolumeFraction,
    };
  }

  // Factory method to create an instance from a JSON map
  factory UDFRCRulesOfMixtureInput.fromJson(Map<String, dynamic> json) {
    return UDFRCRulesOfMixtureInput(
      analysisType: AnalysisType.values.firstWhere(
        (e) =>
            e.toString() ==
            'AnalysisType.' + (json['analysis_type'] ?? "elastic"),
        orElse: () => AnalysisType.elastic, // Default value if not found
      ),
      E1_fiber: (json['E1_fiber'] ?? 0).toDouble(),
      E2_fiber: (json['E2_fiber'] ?? 0).toDouble(),
      G12_fiber: (json['G12_fiber'] ?? 0).toDouble(),
      nu12_fiber: (json['nu12_fiber'] ?? 0).toDouble(),
      alpha11_fiber: (json['alpha11_fiber'] ?? 0).toDouble(),
      alpha22_fiber: (json['alpha22_fiber'] ?? 0).toDouble(),
      E_matrix: (json['E_matrix'] ?? 0).toDouble(),
      nu_matrix: (json['nu_matrix'] ?? 0).toDouble(),
      alpha_matrix: (json['alpha_matrix'] ?? 0).toDouble(),
      fiberVolumeFraction: (json['fiberVolumeFraction'] ?? 0).toDouble(),
    );
  }
}
