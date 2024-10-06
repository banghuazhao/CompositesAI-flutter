import 'dart:math';

import 'package:composite_calculator/models/analysis_type.dart';
import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:linalg/linalg.dart';
import 'package:linalg/matrix.dart';

import '../models/lamina_engineering_constants_input.dart';
import '../models/lamina_engineering_constants_output.dart';

class LaminaEngineeringConstantsCalculator {
  static LaminaEngineeringConstantsOutput calculate(
      LaminaEngineeringConstantsInput input) {
    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;
    double layupAngle = input.layupAngle;

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

    double E_x = 1 / S_bar[0][0];
    double E_y = 1 / S_bar[1][1];
    double G_xy = 1 / S_bar[2][2];
    double nu_xy = -S_bar[0][1] * E_x;
    double eta_x_xy = S_bar[2][0] * E_x;
    double eta_y_xy = S_bar[2][1] * E_y;

    LaminaEngineeringConstantsOutput output = LaminaEngineeringConstantsOutput(
        analysisType: input.analysisType,
        E1: E_x,
        E2: E_y,
        G12: G_xy,
        nu12: nu_xy,
        eta1_12: eta_x_xy,
        eta2_12: eta_y_xy,
        Q: Q_bar.toListOfLists(),
        S: S_bar.toListOfLists());

    if (input.analysisType == AnalysisType.thermalElastic) {
      double alpha11 = input.alpha11;
      double alpha22 = input.alpha22;
      double alpha12 = input.alpha12;

      Matrix R_epsilon_e = Matrix([
        [c * c, s * s, -s * c],
        [s * s, c * c, s * c],
        [2 * s * c, -2 * s * c, c * c - s * s]
      ]);

      Matrix cteVector = Matrix([
        [alpha11],
        [alpha22],
        [2 * alpha12]
      ]);
      Matrix alpha_p = R_epsilon_e * cteVector;
      double alpha_xx = alpha_p[0][0];
      double alpha_yy = alpha_p[1][0];
      double alpha_xy = alpha_p[2][0] / 2;
      output.alpha_11 = alpha_xx;
      output.alpha_22 = alpha_yy;
      output.alpha_12 = alpha_xy;
    }

    return output;
  }
}
