import 'dart:math';

import 'package:composite_calculator/models/tensor_type.dart';
import 'package:linalg/matrix.dart';

import '../models/laminar_stress_strain_input.dart';
import '../models/laminar_stress_strain_output.dart';
import '../utils/layup_parser.dart';

class LaminarStressStrainCalculator {
  static LaminarStressStrainOutput calculate(LaminarStressStrainInput input) {
    Matrix A = Matrix.fill(3, 3);
    Matrix B = Matrix.fill(3, 3);
    Matrix D = Matrix.fill(3, 3);
    double thickness = input.layerThickness;
    List<double> layups = LayupParser.parse(input.layupSequence) ?? [];
    int nPly = layups.length;
    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;

    List<double> bzi = [];
    List<Matrix> Q = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    for (int i = 0; i < nPly; i++) {
      double layup = layups[i];

      double angleRadian = layup * pi / 180;
      double s = sin(angleRadian);
      double c = cos(angleRadian);

      Matrix Sep = Matrix([
        [1 / e1, -nu12 / e1, 0],
        [-nu12 / e1, 1 / e2, 0],
        [0, 0, 1 / g12]
      ]);

      Matrix Qep = Sep.inverse();

      Matrix Rsigmae = Matrix([
        [c * c, s * s, -2 * s * c],
        [s * s, c * c, 2 * s * c],
        [s * c, -s * c, c * c - s * s]
      ]);

      Matrix Qe = Rsigmae * Qep * Rsigmae.transpose();

      Q.add(Qe);

      A += Qe * thickness;
      B += Qe * thickness * bzi[i];
      D += Qe * (thickness * bzi[i] * bzi[i] + pow(thickness, 3) / 12);
    }

    Matrix ABD = Matrix([
      [A[0][0], A[0][1], A[0][2], B[0][0], B[0][1], B[0][2]],
      [A[1][0], A[1][1], A[1][2], B[1][0], B[1][1], B[1][2]],
      [A[2][0], A[2][1], A[2][2], B[2][0], B[2][1], B[2][2]],
      [B[0][0], B[0][1], B[0][2], D[0][0], D[0][1], D[0][2]],
      [B[1][0], B[1][1], B[1][2], D[1][0], D[1][1], D[1][2]],
      [B[2][0], B[2][1], B[2][2], D[2][0], D[2][1], D[2][2]]
    ]);

    Matrix ABD_inverese = ABD.inverse();

    LaminarStressStrainOutput output;
    if (input.tensorType == TensorType.stress) {
      Matrix stressVector = Matrix([
        [input.N11],
        [input.N22],
        [input.N12],
        [input.M11],
        [input.M22],
        [input.M12],
      ]);
      Matrix strainVector = ABD_inverese * stressVector;
      output = LaminarStressStrainOutput(
          tensorType: TensorType.strain,
          epsilon11: strainVector[0][0],
          epsilon22: strainVector[1][0],
          epsilon12: strainVector[2][0],
          kappa11: strainVector[3][0],
          kappa22: strainVector[4][0],
          kappa12: strainVector[5][0]);
    } else {
      Matrix strainVector = Matrix([
        [input.epsilon11],
        [input.epsilon22],
        [input.epsilon12],
        [input.kappa11],
        [input.kappa22],
        [input.kappa12]
      ]);
      Matrix stressVector = ABD * strainVector;
      output = LaminarStressStrainOutput(
          tensorType: TensorType.stress,
          N11: stressVector[0][0],
          N22: stressVector[1][0],
          N12: stressVector[2][0],
          M11: stressVector[3][0],
          M22: stressVector[4][0],
          M12: stressVector[5][0]);
    }

    return output;
  }

  static List<Matrix> getQMatrices(LaminarStressStrainInput input) {
    double thickness = input.layerThickness;
    List<double> layups = LayupParser.parse(input.layupSequence) ?? [];
    int nPly = layups.length;
    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;

    List<double> bzi = [];
    List<Matrix> Q = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    for (int i = 0; i < nPly; i++) {
      double layup = layups[i];

      double angleRadian = layup * pi / 180;
      double s = sin(angleRadian);
      double c = cos(angleRadian);

      Matrix Sep = Matrix([
        [1 / e1, -nu12 / e1, 0],
        [-nu12 / e1, 1 / e2, 0],
        [0, 0, 1 / g12]
      ]);

      Matrix Qep = Sep.inverse();

      Matrix Rsigmae = Matrix([
        [c * c, s * s, -2 * s * c],
        [s * s, c * c, 2 * s * c],
        [s * c, -s * c, c * c - s * s]
      ]);

      Matrix Qe = Rsigmae * Qep * Rsigmae.transpose();

      Q.add(Qe);
    }
    return Q;
  }
}
