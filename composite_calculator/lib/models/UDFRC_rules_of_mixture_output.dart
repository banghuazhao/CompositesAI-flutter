class UDFRCRulesOfMixtureOutput {
  ThreeDimensionalPropertiesOutput voigtRulesOfMixture;
  ThreeDimensionalPropertiesOutput reussRulesOfMixture;
  ThreeDimensionalPropertiesOutput hybirdRulesOfMixture;

  UDFRCRulesOfMixtureOutput({
    ThreeDimensionalPropertiesOutput? voigtRulesOfMixture,
    ThreeDimensionalPropertiesOutput? reussRulesOfMixture,
    ThreeDimensionalPropertiesOutput? hybridRulesOfMixture,
  })  : voigtRulesOfMixture =
            voigtRulesOfMixture ?? ThreeDimensionalPropertiesOutput(),
        reussRulesOfMixture =
            reussRulesOfMixture ?? ThreeDimensionalPropertiesOutput(),
        hybirdRulesOfMixture =
            hybridRulesOfMixture ?? ThreeDimensionalPropertiesOutput();

  Map<String, dynamic> toJson() {
    return {
      'voigtRulesOfMixture': voigtRulesOfMixture.toJson(),
      'reussRulesOfMixture': reussRulesOfMixture.toJson(),
      'hybridRulesOfMixture': hybirdRulesOfMixture.toJson()
    };
  }
}

class ThreeDimensionalPropertiesOutput {
  List<List<double>> stiffness;
  List<List<double>> compliance;

  Map<String, double> engineeringConstants;

  ThreeDimensionalPropertiesOutput({
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
