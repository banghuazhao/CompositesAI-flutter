import 'package:composite_calculator/models/analysis_type.dart';

class LaminaEngineeringConstantsOutput {
  AnalysisType analysisType;

  double E1;
  double E2;
  double G12;
  double nu12;
  double eta1_12;
  double eta2_12;
  List<List<double>> Q;
  List<List<double>> S;

  double alpha_11 = 0;
  double alpha_22 = 0;
  double alpha_12 = 0;

  LaminaEngineeringConstantsOutput({
    this.analysisType = AnalysisType.elastic,
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.eta1_12 = 0,
    this.eta2_12 = 0,
    List<List<double>>? Q, // Make it nullable and initialize later
    List<List<double>>? S, // Make it nullable and initialize later
    this.alpha_11 = 0,
    this.alpha_22 = 0,
    this.alpha_12 = 0,
  })  : Q = Q ?? [],
        S = S ?? [];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'analysis_type': analysisType.toJson(),
      'E_1': E1,
      'E_2': E2,
      'G_12': G12,
      'nu_12': nu12,
      'eta_1_12': eta1_12,
      'eta_2_12': eta2_12,
      'Q': Q,
      'S': S,
    };
    if (analysisType == AnalysisType.thermalElastic) {
      result.addAll({
        'alpha_11': alpha_11,
        'alpha_22': alpha_22,
        'alpha_12': alpha_12,
      });
    }
    return result;
  }
}
