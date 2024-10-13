import 'package:composite_calculator/models/tensor_type.dart';

import 'analysis_type.dart';

class LaminarStressStrainInput {
  double E1;
  double E2;
  double G12;
  double nu12;
  String layupSequence;
  double layerThickness;

  TensorType tensorType;

  double N11;
  double N22;
  double N12;
  double M11;
  double M22;
  double M12;

  double epsilon11;
  double epsilon22;
  double epsilon12;
  double kappa11;
  double kappa22;
  double kappa12;

  LaminarStressStrainInput({
    this.E1 = 0,
    this.E2 = 0,
    this.G12 = 0,
    this.nu12 = 0,
    this.layupSequence = "",
    this.layerThickness = 0,
    this.tensorType = TensorType.stress,
    this.N11 = 0,
    this.N22 = 0,
    this.N12 = 0,
    this.M11 = 0,
    this.M22 = 0,
    this.M12 = 0,
    this.epsilon11 = 0,
    this.epsilon22 = 0,
    this.epsilon12 = 0,
    this.kappa11 = 0,
    this.kappa22 = 0,
    this.kappa12 = 0,
  });

  // Factory method to create an instance with default values
  factory LaminarStressStrainInput.withDefaults() {
    return LaminarStressStrainInput(
      E1: 150000,
      E2: 10000,
      G12: 5000,
      nu12: 0.3,
      layupSequence: "[0/90/45/-45]s",
      layerThickness: 0.125,
      tensorType: TensorType.stress,
      N11: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'E1': E1,
      'E2': E2,
      'G12': G12,
      'nu12': nu12,
      'layup_sequence': layupSequence,
      'layer_thickness': layerThickness,
      'tensorType': tensorType,
      'N11': N11,
      'N22': N22,
      'N12': N12,
      'M11': M11,
      'M22': M22,
      'M12': M12,
      'epsilon11': epsilon11,
      'epsilon22': epsilon22,
      'epsilon12': epsilon12,
      'kappa11': kappa11,
      'kappa22': kappa22,
      'kappa12': kappa12,
    };
  }

  // Factory method to create an instance from a JSON map
  factory LaminarStressStrainInput.fromJson(Map<String, dynamic> json) {
    return LaminarStressStrainInput(
      E1: (json['E1'] ?? 0).toDouble(),
      E2: (json['E2'] ?? 0).toDouble(),
      G12: (json['G12'] ?? 0).toDouble(),
      nu12: (json['nu12'] ?? 0).toDouble(),
      layupSequence: (json['layup_sequence'] ?? "").toString(),
      layerThickness: (json['layer_thickness'] ?? 0).toDouble(),
      tensorType: TensorType.values.firstWhere(
        (e) => e.toString() == 'TensorType.' + (json['tensorType'] ?? 'stress'),
        orElse: () => TensorType.stress, // Default value if not found
      ),
      N11: (json['N11'] ?? 0).toDouble(),
      N22: (json['N22'] ?? 0).toDouble(),
      N12: (json['N12'] ?? 0).toDouble(),
      M11: (json['M11'] ?? 0).toDouble(),
      M22: (json['M22'] ?? 0).toDouble(),
      M12: (json['M12'] ?? 0).toDouble(),
      epsilon11: (json['epsilon11'] ?? 0).toDouble(),
      epsilon22: (json['epsilon22'] ?? 0).toDouble(),
      epsilon12: (json['epsilon12'] ?? 0).toDouble(),
      kappa11: (json['kappa11'] ?? 0).toDouble(),
      kappa22: (json['kappa22'] ?? 0).toDouble(),
      kappa12: (json['kappa12'] ?? 0).toDouble(),
    );
  }
}
