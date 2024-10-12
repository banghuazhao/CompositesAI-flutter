import 'dart:math';

import 'package:composite_calculator/models/analysis_type.dart';
import 'package:composite_calculator/models/tensor_type.dart';
import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:linalg/linalg.dart';
import 'package:linalg/matrix.dart';

import '../models/lamina_stress_strain_input.dart';
import '../models/lamina_stress_strain_output.dart';

class LaminaStressStrainCalculator {
  static LaminaStressStrainOutput calculate(LaminaStressStrainInput input) {
    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;
    double layupAngle = input.layupAngle;

    double alpha11 = input.alpha11;
    double alpha22 = input.alpha22;
    double alpha12 = input.alpha12;
    double deltaT = input.deltaT;

    double angleRadian = layupAngle * pi / 180;
    double s = sin(angleRadian);
    double c = cos(angleRadian);

    var S = Matrix([
      [1 / e1, -nu12 / e1, 0],
      [-nu12 / e1, 1 / e2, 0],
      [0, 0, 1 / g12]
    ]);
    var Q = S.inverse();

    Matrix T_epsilon = Matrix([
      [c * c, s * s, -s * c],
      [s * s, c * c, s * c],
      [2 * s * c, -2 * s * c, c * c - s * s]
    ]);

    Matrix T_sigma = Matrix([
      [c * c, s * s, -2 * s * c],
      [s * s, c * c, 2 * s * c],
      [s * c, -s * c, c * c - s * s]
    ]);

    Matrix Q_bar = T_sigma.transpose() * Q * T_sigma;
    Matrix S_bar = T_epsilon.transpose() * S * T_epsilon;

    TensorType tensorType = input.tensorType;
    AnalysisType analysisType = input.analysisType;

    if (tensorType == TensorType.stress) {
      double sigma11 = input.sigma11;
      double sigma22 = input.sigma22;
      double sigma12 = input.sigma12;
      var stressVector = Matrix([
        [sigma11],
        [sigma22],
        [sigma12]
      ]);

      Matrix strainVector;
      if (analysisType == AnalysisType.elastic) {
        strainVector = S_bar * stressVector;
      } else {
        double alpha11DeltaT = alpha11 * deltaT;
        double alpha22DeltaT = alpha22 * deltaT;
        double alpha12DeltaT = alpha12 * deltaT;
        var cteVector = Matrix([
          [alpha11DeltaT],
          [alpha22DeltaT],
          [2 * alpha12DeltaT]
        ]);
        var R_epsilon_e = Matrix([
          [c * c, s * s, -s * c],
          [s * s, c * c, s * c],
          [2 * s * c, -2 * s * c, c * c - s * s]
        ]);
        strainVector = S_bar * stressVector + R_epsilon_e * cteVector;
      }
      return LaminaStressStrainOutput(
        tensorType: TensorType.strain,
        epsilon11: strainVector[0][0],
        epsilon22: strainVector[1][0],
        gamma12: strainVector[2][0],
        Q: Q_bar.toListOfLists(),
        S: S_bar.toListOfLists(),
      );
    } else {
      double epsilon11 = input.epsilon11;
      double epsilon22 = input.epsilon22;
      double gamma12 = input.gamma12;
      var strainVector = Matrix([
        [epsilon11],
        [epsilon22],
        [gamma12]
      ]);

      Matrix stressVector;
      if (analysisType == AnalysisType.elastic) {
        stressVector = Q_bar * strainVector;
      } else {
        double alpha11DeltaT = alpha11 * deltaT;
        double alpha22DeltaT = alpha22 * deltaT;
        double alpha12DeltaT = alpha12 * deltaT;
        var cteVector = Matrix([
          [alpha11DeltaT],
          [alpha22DeltaT],
          [2 * alpha12DeltaT]
        ]);
        var R_epsilon_e = Matrix([
          [c * c, s * s, -s * c],
          [s * s, c * c, s * c],
          [2 * s * c, -2 * s * c, c * c - s * s]
        ]);
        stressVector = Q_bar * (strainVector - R_epsilon_e * cteVector);
      }
      return LaminaStressStrainOutput(
        tensorType: TensorType.stress,
        sigma11: stressVector[0][0],
        sigma22: stressVector[1][0],
        sigma12: stressVector[2][0],
        Q: Q_bar.toListOfLists(),
        S: S_bar.toListOfLists(),
      );
    }
  }
}
