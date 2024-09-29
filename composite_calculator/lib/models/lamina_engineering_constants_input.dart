class LaminaEngineeringConstantsInput {
  final double E1;
  final double E2;
  final double G12;
  final double nu12;
  final double layupAngle;

  LaminaEngineeringConstantsInput({
    required this.E1,
    required this.E2,
    required this.G12,
    required this.nu12,
    required this.layupAngle,
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
      'E1': E1,
      'E2': E2,
      'G12': G12,
      'nu12': nu12,
      'layup_angle': layupAngle,
    };
  }
}