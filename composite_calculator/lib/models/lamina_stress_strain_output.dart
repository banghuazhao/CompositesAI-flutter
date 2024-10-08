import 'package:composite_calculator/models/analysis_type.dart';
import 'package:composite_calculator/models/tensor_type.dart';

class LaminaStressStrainOutput {
  TensorType tensorType;

  double sigma11;
  double sigma22;
  double sigma12;

  double epsilon11;
  double epsilon22;
  double gamma12;

  List<List<double>> Q;
  List<List<double>> S;

  LaminaStressStrainOutput({
    this.tensorType = TensorType.stress,
    this.sigma11 = 0,
    this.sigma22 = 0,
    this.sigma12 = 0,
    this.epsilon11 = 0,
    this.epsilon22 = 0,
    this.gamma12 = 0,
    List<List<double>>? Q, // Make it nullable and initialize later
    List<List<double>>? S, // Make it nullable and initialize later
  })  : Q = Q ?? [],
        S = S ?? [];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'Q': Q,
      'S': S,
    };
    if (tensorType == TensorType.stress) {
      result.addAll({
        'sigma11': sigma11,
        'sigma22': sigma22,
        'sigma12': sigma12,
      });
    } else {
      result.addAll({
        'epsilon11': epsilon11,
        'epsilon22': epsilon22,
        'gamma12': gamma12,
      });
    }
    return result;
  }
}
