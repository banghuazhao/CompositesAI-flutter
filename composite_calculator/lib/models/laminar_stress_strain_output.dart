import 'package:composite_calculator/models/tensor_type.dart';

class LaminarStressStrainOutput {
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

  LaminarStressStrainOutput({
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

  Map<String, double> toJson() {
    Map<String, double> result = {};
    if (tensorType == TensorType.stress) {
      result.addAll({
        'N11': N11,
        'N22': N22,
        'N12': N12,
        'M11': M11,
        'M22': M22,
        'M12': M12,
      });
    } else {
      result.addAll({
        'epsilon11': epsilon11,
        'epsilon22': epsilon22,
        'epsilon12': epsilon12,
        'kappa11': kappa11,
        'kappa22': kappa22,
        'kappa12': kappa12,
      });
    }
    return result;
  }
}
