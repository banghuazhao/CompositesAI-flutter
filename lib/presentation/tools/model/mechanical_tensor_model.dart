abstract class MechanicalTensor {
  isValid();
}

class PlaneStress extends MechanicalTensor {
  double? sigma11;
  double? sigma22;
  double? sigma12;

  PlaneStress();

  PlaneStress.from(this.sigma11, this.sigma22, this.sigma12);

  @override
  isValid() {
    return (sigma11 != null && sigma22 != null && sigma12 != null);
  }
}

class PlaneStrain extends MechanicalTensor {
  double? epsilon11;
  double? epsilon22;
  double? gamma12;

  PlaneStrain();

  PlaneStrain.from(this.epsilon11, this.epsilon22, this.gamma12);

  @override
  isValid() {
    return (epsilon11 != null && epsilon22 != null && gamma12 != null);
  }
}

class LaminateStress extends MechanicalTensor {
  double? N11;
  double? N22;
  double? N12;
  double? M11;
  double? M22;
  double? M12;

  LaminateStress();

  LaminateStress.from(
      this.N11, this.N22, this.N12, this.M11, this.M22, this.M12);

  @override
  isValid() {
    return (N11 != null &&
        N22 != null &&
        N12 != null &&
        M11 != null &&
        M22 != null &&
        M12 != null);
  }

  @override
  String toString() {
    return "N11: $N11, N22: $N22, N12: $N12, M11: $M11, M22: $M22, M12: $M12";
  }
}

class LaminateStrain extends MechanicalTensor {
  double? epsilon11;
  double? epsilon22;
  double? epsilon12;
  double? kappa11;
  double? kappa22;
  double? kappa12;

  LaminateStrain();

  LaminateStrain.from(this.epsilon11, this.epsilon22, this.epsilon12,
      this.kappa11, this.kappa22, this.kappa12);

  @override
  isValid() {
    return (epsilon11 != null &&
        epsilon22 != null &&
        epsilon12 != null &&
        kappa11 != null &&
        kappa22 != null &&
        kappa12 != null);
  }

  @override
  String toString() {
    return "epsilon11: $epsilon11, epsilon22: $epsilon22, epsilon12: $epsilon12, kappa11: $kappa11, kappa22: $kappa22, kappa12: $kappa12";
  }
}
