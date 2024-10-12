import 'analysis_type.dart';

class InPlaneProperties {
  AnalysisType analysisType;
  double E1;
  double E2;
  double G12;
  double nu12;
  double eta121;
  double eta122;
  double alpha11;
  double alpha22;
  double alpha12;

  InPlaneProperties({
    this.analysisType = AnalysisType.elastic,
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.eta121 = 0,
    this.eta122 = 0,
    this.alpha11 = 0,
    this.alpha22 = 0,
    this.alpha12 = 0,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'E1': E1,
      'E2': E2,
      'G12': G12,
      'nu12': nu12,
      'eta121': eta121,
      'eta122': eta122,
    };
    if (analysisType == AnalysisType.thermalElastic) {
      result.addAll({
        'alpha11': alpha11,
        'alpha22': alpha22,
        'alpha12': alpha12,
      });
    }
    return result;
  }
}
