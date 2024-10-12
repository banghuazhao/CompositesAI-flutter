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
