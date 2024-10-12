import 'dart:math';

import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/in-plane-properties.dart';
import 'package:composite_calculator/utils/layup_parser.dart';
import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:linalg/linalg.dart';
import 'package:linalg/matrix.dart';

import '../models/laminate_plate_properties_input.dart';
import '../models/laminate_plate_properties_output.dart';

class LaminatePlatePropertiesCalculator {
  static LaminatePlatePropertiesOutput calculate(
      LaminatePlatePropertiesInput input) {
    Matrix A = Matrix.fill(3, 3);
    Matrix B = Matrix.fill(3, 3);
    Matrix D = Matrix.fill(3, 3);

    double e1 = input.E1;
    double e2 = input.E2;
    double g12 = input.G12;
    double nu12 = input.nu12;
    double thickness = input.layerThickness;
    String layupSequence = input.layupSequence;
    List<double> layups = LayupParser.parse(layupSequence) ?? [];
    int nPly = layups.length;

    List<double> bzi = [];
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

      A += Qe * thickness;
      B += Qe * thickness * bzi[i];
      D += Qe * (thickness * bzi[i] * bzi[i] + pow(thickness, 3) / 12);
    }

    LaminatePlatePropertiesOutput output = LaminatePlatePropertiesOutput(
      A: A.toListOfLists(),
      B: B.toListOfLists(),
      D: D.toListOfLists(),
    );

    double h = nPly * thickness;

    Matrix Ses = A.inverse() * h;
    Matrix Sesf = D.inverse() * (pow(h, 3) / 12);

    output.inPlaneProperties = InPlaneProperties(
      analysisType: input.analysisType,
      E1: 1 / Ses[0][0],
      E2: 1 / Ses[1][1],
      G12: 1 / Ses[2][2],
      nu12: -1 / Ses[0][0] * Ses[0][1],
      eta121: -1 / Ses[2][2] * Ses[0][2],
      eta122: -1 / Ses[2][2] * Ses[1][2],
    );

    output.flexuralProperties = InPlaneProperties(
      analysisType: input.analysisType,
      E1: 1 / Sesf[0][0],
      E2: 1 / Sesf[1][1],
      G12: 1 / Sesf[2][2],
      nu12: -1 / Sesf[0][0] * Sesf[0][1],
      eta121: -1 / Sesf[2][2] * Sesf[0][2],
      eta122: -1 / Sesf[2][2] * Sesf[1][2],
    );

    if (input.analysisType == AnalysisType.thermalElastic) {
      double alpha11 = input.alpha11;
      double alpha22 = input.alpha22;
      double alpha12 = input.alpha12;

      Matrix temp_eff = Matrix.fill(3, 1);
      Matrix temp_flex = Matrix.fill(3, 1);

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

        temp_eff += Qe * R_epsilon_e * cteVector * thickness;
        temp_flex += Qe *
            R_epsilon_e *
            cteVector *
            (thickness * bzi[i] * bzi[i] +
                thickness * thickness * thickness / 12);
      }

      Matrix cteVector_effective = A.inverse() * temp_eff;
      Matrix cteVector_flexural = D.inverse() * temp_flex;

      output.inPlaneProperties.alpha11 = cteVector_effective[0][0];
      output.inPlaneProperties.alpha22 = cteVector_effective[1][0];
      output.inPlaneProperties.alpha12 = cteVector_effective[2][0];

      output.flexuralProperties.alpha11 = cteVector_flexural[0][0];
      output.flexuralProperties.alpha22 = cteVector_flexural[1][0];
      output.flexuralProperties.alpha12 = cteVector_flexural[2][0];
    }

    return output;
  }
}
