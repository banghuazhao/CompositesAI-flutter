import 'material_model.dart';

class TransverselyIsotropicCTE extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.transverselyIsotropic;

  double? alpha11;
  double? alpha22;
  double? alpha12;

  TransverselyIsotropicCTE();

  isValid() {
    if (alpha11 != null && alpha22 != null) {
      return true;
    }
    return false;
  }
}

class IsotropicCTE extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.isotropic;

  double? alpha;

  IsotropicCTE();

  isValid() {
    if (alpha != null) {
      return true;
    }
    return false;
  }
}
