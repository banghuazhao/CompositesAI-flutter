enum MechanicalMaterialType {
  isotropic,
  transverselyIsotropic,
  orthotropic,
  monoclinic,
  anisotropic,
}

extension MechanicalMaterialTypeName on MechanicalMaterialType {
  String get name {
    switch (this) {
      case MechanicalMaterialType.isotropic:
        return "Isotropic";
      case MechanicalMaterialType.transverselyIsotropic:
        return "Transversely Isotropic";
      case MechanicalMaterialType.orthotropic:
        return "Orthotropic";
      case MechanicalMaterialType.monoclinic:
        return "Monoclinic";
      case MechanicalMaterialType.anisotropic:
        return "Anisotropic";
      default:
        return "";
    }
  }
}

abstract class MechanicalMaterial {
  MechanicalMaterialType type = MechanicalMaterialType.isotropic;
}

class IsotropicMaterial extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.isotropic;

  double? e;
  double? nu;

  IsotropicMaterial();

  isValid() {
    if (e != null && nu != null) {
      if (e! > 0 && nu! >= -1.0 && nu! < 0.5) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return "e: $e, nu: $nu";
  }
}

class TransverselyIsotropicMaterial extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.transverselyIsotropic;

  double? e1;
  double? e2;
  double? g12;
  double? nu12;
  double? nu23;

  TransverselyIsotropicMaterial();

  isValidInPlane() {
    if (e1 != null && e2 != null && g12 != null && nu12 != null) {
      if (e1! > 0 && e2! > 0 && g12! > 0) {
        return true;
      }
    }
    return false;
  }

  isValid() {
    if (e1 != null &&
        e2 != null &&
        g12 != null &&
        nu12 != null &&
        nu23 != null) {
      if (e1! > 0 && e2! > 0 && g12! > 0) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return "e1: $e1, e2: $e2, g12: $g12, nu12: $nu12, nu23: $nu23";
  }
}

class OrthotropicMaterial extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.orthotropic;

  double? e1;
  double? e2;
  double? e3;
  double? g12;
  double? g13;
  double? g23;
  double? nu12;
  double? nu13;
  double? nu23;
  double? alpha11;
  double? alpha22;
  double? alpha33;
  double? alpha12;

  OrthotropicMaterial({
    this.e1,
    this.e2,
    this.e3,
    this.g12,
    this.g13,
    this.g23,
    this.nu12,
    this.nu13,
    this.nu23,
    this.alpha11,
    this.alpha22,
    this.alpha33,
    this.alpha12,
  });

  isValid() {
    if (e1 != null &&
        e2 != null &&
        e2 != null &&
        g12 != null &&
        g13 != null &&
        g23 != null &&
        nu12 != null &&
        nu13 != null &&
        nu23 != null) {
      if (e1! > 0 && e2! > 0 && e3! > 0 && g12! > 0 && g13! > 0 && g23! > 0) {
        return true;
      }
    }
    return false;
  }
}

class MonoclinicMaterial extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.monoclinic;

  double? e1;
  double? e2;
  double? e3;
  double? g12;
  double? g13;
  double? g23;
  double? nu12;
  double? nu13;
  double? nu23;
  double? eta13_23;
  double? eta1_12;
  double? eta2_12;
  double? eta3_12;

  MonoclinicMaterial();

  isValid() {
    if (e1 != null &&
        e2 != null &&
        e2 != null &&
        g12 != null &&
        g13 != null &&
        g23 != null &&
        nu12 != null &&
        nu13 != null &&
        nu23 != null &&
        eta13_23 != null &&
        eta1_12 != null &&
        eta2_12 != null &&
        eta3_12 != null) {
      if (e1! > 0 && e2! > 0 && e3! > 0 && g12! > 0 && g13! > 0 && g23! > 0) {
        return true;
      }
    }
    return false;
  }
}

class AnisotropicMaterial extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.anisotropic;

  double? c11;
  double? c12;
  double? c13;
  double? c14;
  double? c15;
  double? c16;
  double? c22;
  double? c23;
  double? c24;
  double? c25;
  double? c26;
  double? c33;
  double? c34;
  double? c35;
  double? c36;
  double? c44;
  double? c45;
  double? c46;
  double? c55;
  double? c56;
  double? c66;

  AnisotropicMaterial();

  isValid() {
    if (c11 != null &&
        c12 != null &&
        c13 != null &&
        c14 != null &&
        c15 != null &&
        c16 != null &&
        c22 != null &&
        c23 != null &&
        c24 != null &&
        c25 != null &&
        c26 != null &&
        c33 != null &&
        c34 != null &&
        c35 != null &&
        c36 != null &&
        c44 != null &&
        c45 != null &&
        c46 != null &&
        c55 != null &&
        c56 != null &&
        c66 != null) {
      return true;
    }
    return false;
  }
}
