import 'unit_system.dart';

validateModulus(double? value) {
  if (value == null) {
    return "Not a number";
  } else if (value <= 0) {
    return "Not > 0";
  } else {
    return null;
  }
}

validateCTEs(double? value) {
  if (value == null) {
    return "Not a number";
  } else {
    return null;
  }
}

validateIsotropicPoissonRatio(double? value) {
  if (value == null) {
    return "Not a number";
  } else if (value <= -1.0 || value >= 0.5) {
    return "Not in (-1.0, 0.5)";
  } else {
    return null;
  }
}

validatePoissonRatio(double? value) {
  if (value == null) {
    return "Not a number";
  } else {
    return null;
  }
}

/// Modulus validation that also catches values entered in the wrong unit,
/// e.g. 150000 typed for E1 when the field expects GPa.
String? validateModulusIn(double? value, Units units) {
  final basic = validateModulus(value);
  if (basic != null) return basic;
  if (value! > units.maxPlausibleModulus) {
    return 'Too large for ${units.modulus}; check units';
  }
  return null;
}

String? validateStrength(double? value) {
  if (value == null) return "Not a number";
  if (value <= 0) return "Not > 0";
  return null;
}
