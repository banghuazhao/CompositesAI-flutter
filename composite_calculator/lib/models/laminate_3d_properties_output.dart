class Laminate3DPropertiesOutput {
  List<List<double>> stiffness;
  List<List<double>> compliance;

  Map<String, double> engineeringConstants;

  Laminate3DPropertiesOutput({
    this.stiffness = const [],
    this.compliance = const [],
    Map<String, double>?
        engineeringConstants, // Make it nullable and initialize later
  }) : engineeringConstants = engineeringConstants ?? {};

  Map<String, dynamic> toJson() {
    return {
      'stiffness': stiffness,
      'compliance': compliance,
      'engineeringConstants': engineeringConstants
    };
  }
}
