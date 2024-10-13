import 'dart:math';

import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/utils/layup_parser.dart';
import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:linalg/linalg.dart';
import 'package:linalg/matrix.dart';

import '../models/laminate_3d_properties_input.dart';
import '../models/laminate_3d_properties_output.dart';

class Laminate3DPropertiesCalculator {
  static Laminate3DPropertiesOutput calculate(
      Laminate3DPropertiesInput input) {
    double thickness = input.layerThickness;
    List<double> layups = LayupParser.parse(input.layupSequence) ?? [];
    int nPly = layups.length;
    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;
    double nu23 = input.nu23;
    double e3 = e2;
    double g13 = g12;
    double g23 = e2 / (2 * (1 + nu23));
    double nu13 = nu12;

    List<double> bzi = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    Matrix C = Matrix.fill(6, 6);
    Matrix alpha_temp = Matrix.fill(3, 1);
    Matrix Q_start = Matrix.fill(3, 3);

    for (int i = 0; i < nPly; i++) {
      double layup = layups[i];

      double angleRadian = layup * pi / 180;
      double s = sin(angleRadian);
      double c = cos(angleRadian);
      Matrix Sp = Matrix([
        [1 / e1, -nu12 / e1, -nu13 / e1, 0, 0, 0],
        [-nu12 / e1, 1 / e2, -nu23 / e2, 0, 0, 0],
        [-nu13 / e1, -nu23 / e2, 1 / e3, 0, 0, 0],
        [0, 0, 0, 1 / g23, 0, 0],
        [0, 0, 0, 0, 1 / g13, 0],
        [0, 0, 0, 0, 0, 1 / g12]
      ]);

      Matrix Cp = Sp.inverse();

      Matrix Rsigma = Matrix([
        [c * c, s * s, 0, 0, 0, -2 * s * c],
        [s * s, c * c, 0, 0, 0, 2 * s * c],
        [0, 0, 1, 0, 0, 0],
        [0, 0, 0, c, s, 0],
        [0, 0, 0, -s, c, 0],
        [s * c, -s * c, 0, 0, 0, c * c - s * s]
      ]);
      Matrix C_single = Rsigma * Cp * Rsigma.transpose();
      C += C_single;

      if (input.analysisType == AnalysisType.thermalElastic) {
        double alpha11 = input.alpha11;
        double alpha22 = input.alpha22;
        double alpha12 = input.alpha12;
        Matrix cteVector = Matrix([
          [alpha11],
          [alpha22],
          [2 * alpha12]
        ]);
        Matrix S_single = C_single.inverse();
        Matrix Se = Matrix([
          [S_single[0][0], S_single[0][1], S_single[0][5]],
          [S_single[0][1], S_single[1][1], S_single[1][5]],
          [S_single[0][5], S_single[1][5], S_single[5][5]]
        ]);
        Matrix Q = Se.inverse();
        Q_start += Q;

        Matrix R_epsilon_e = Matrix([
          [c * c, s * s, -s * c],
          [s * s, c * c, s * c],
          [2 * s * c, -2 * s * c, c * c - s * s]
        ]);

        alpha_temp += Q * R_epsilon_e * cteVector;
      }
    }

    C = C * (1 / nPly);
    Matrix S = C.inverse();

    Laminate3DPropertiesOutput output = Laminate3DPropertiesOutput();
    output.stiffness = C.toListOfLists();
    output.compliance = S.toListOfLists();

    output.engineeringConstants["E1"] = 1 / S[0][0];
    output.engineeringConstants["E2"] = 1 / S[1][1];
    output.engineeringConstants["E3"] = 1 / S[2][2];
    output.engineeringConstants["G12"] = 1 / S[5][5];
    output.engineeringConstants["G13"] = 1 / S[4][4];
    output.engineeringConstants["G23"] = 1 / S[3][3];
    output.engineeringConstants["nu12"] = -1 / S[0][0] * S[0][1];
    output.engineeringConstants["nu13"] = -1 / S[0][0] * S[0][2];
    output.engineeringConstants["nu23"] = -1 / S[1][1] * S[1][2];

    if (input.analysisType == AnalysisType.thermalElastic) {
      Q_start = Q_start * (1 / nPly);
      alpha_temp = alpha_temp * (1 / nPly);
      Matrix alpha_CTE = Q_start.inverse() * alpha_temp;
      output.engineeringConstants["alpha11"] = alpha_CTE[0][0];
      output.engineeringConstants["alpha22"] = alpha_CTE[1][0];
      output.engineeringConstants["alpha12"] = alpha_CTE[2][0];
    }

    return output;
  }
}
