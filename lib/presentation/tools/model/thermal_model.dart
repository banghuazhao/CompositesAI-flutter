import 'material_model.dart';

class TransverselyIsotropicCTE extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.transverselyIsotropic;

  double? alpha11;
  double? alpha22;
  double? alpha12;

  TransverselyIsotropicCTE();

  bool isValid({bool includeShear = true}) => [
        alpha11,
        alpha22,
        if (includeShear) alpha12
      ].every((value) => value?.isFinite ?? false);
}

class IsotropicCTE extends MechanicalMaterial {
  @override
  MechanicalMaterialType type = MechanicalMaterialType.isotropic;

  double? alpha;

  IsotropicCTE();

  bool isValid() => alpha?.isFinite ?? false;
}
