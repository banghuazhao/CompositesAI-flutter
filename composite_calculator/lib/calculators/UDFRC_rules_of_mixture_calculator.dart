import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:linalg/matrix.dart';

import '../models/UDFRC_rules_of_mixture_input.dart';
import '../models/UDFRC_rules_of_mixture_output.dart';
import '../models/analysis_type.dart';

class UDFRCRulesOfMixtureCalculator {
  static UDFRCRulesOfMixtureOutput calculate(UDFRCRulesOfMixtureInput input) {
    double Vf = input.fiberVolumeFraction;
    double ef1 = input.E1_fiber;
    double ef2 = input.E2_fiber;
    double ef3 = ef2;
    double gf12 = input.G12_fiber;
    double gf13 = gf12;
    double gf23 = ef2 / (2 * (1 + input.nu23_fiber));
    double nuf12 = input.nu12_fiber;
    double nuf13 = input.nu12_fiber;
    double nuf23 = input.nu23_fiber;

    double Vm = 1 - Vf;
    double Em = input.E_matrix;
    double num = input.nu_matrix;
    double Gm = Em / (2 * (1 + num));
    double em1 = Em;
    double em2 = Em;
    double em3 = Em;
    double gm12 = Gm;
    double gm13 = Gm;
    double gm23 = Gm;
    double num12 = num;
    double num13 = num;
    double num23 = num;

    Matrix Sf = Matrix([
      [1 / ef1, -nuf12 / ef1, -nuf13 / ef1, 0, 0, 0],
      [-nuf12 / ef1, 1 / ef2, -nuf23 / ef2, 0, 0, 0],
      [-nuf12 / ef1, -nuf23 / ef2, 1 / ef3, 0, 0, 0],
      [0, 0, 0, 1 / gf23, 0, 0],
      [0, 0, 0, 0, 1 / gf13, 0],
      [0, 0, 0, 0, 0, 1 / gf12]
    ]);
    Matrix SHf_Temp = Matrix([
      [ef1, nuf12, nuf13, 0, 0, 0],
      [
        -nuf12,
        1 / ef2 - nuf12 * nuf12 / ef1,
        -nuf23 / ef2 - nuf13 * nuf13 / ef1,
        0,
        0,
        0
      ],
      [
        -nuf23,
        -nuf23 / ef2 - nuf12 * nuf12 / ef1,
        1 / ef3 - nuf13 * nuf13 / ef1,
        0,
        0,
        0
      ],
      [0, 0, 0, 1 / gf23, 0, 0],
      [0, 0, 0, 0, 1 / gf13, 0],
      [0, 0, 0, 0, 0, 1 / gf12]
    ]);

    Matrix Sm = Matrix([
      [1 / em1, -num12 / em1, -num13 / em1, 0, 0, 0],
      [-num12 / em1, 1 / em2, -num23 / em2, 0, 0, 0],
      [-num12 / em1, -num23 / em2, 1 / em3, 0, 0, 0],
      [0, 0, 0, 1 / gm23, 0, 0],
      [0, 0, 0, 0, 1 / gm13, 0],
      [0, 0, 0, 0, 0, 1 / gm12]
    ]);
    Matrix SHm_Temp = Matrix([
      [em1, num12, num13, 0, 0, 0],
      [
        -num12,
        1 / em2 - num12 * num12 / em1,
        -num23 / em2 - num13 * num13 / em1,
        0,
        0,
        0
      ],
      [
        -num23,
        -num23 / em2 - num12 * num12 / em1,
        1 / em3 - num13 * num13 / em1,
        0,
        0,
        0
      ],
      [0, 0, 0, 1 / gm23, 0, 0],
      [0, 0, 0, 0, 1 / gm13, 0],
      [0, 0, 0, 0, 0, 1 / gm12]
    ]);

    Matrix Cf = Sf.inverse();
    Matrix Cm = Sm.inverse();

    Matrix CVs = Cf * Vf + Cm * Vm;
    Matrix SVs = CVs.inverse();

    Matrix SRs = Sf * Vf + Sm * Vm;
    Matrix CRs = SRs.inverse();

    Matrix SHs_Temp = SHf_Temp * Vf + SHm_Temp * Vm;

    UDFRCRulesOfMixtureOutput output = UDFRCRulesOfMixtureOutput();

    output.voigtRulesOfMixture.engineeringConstants['E1'] = 1 / SVs[0][0];
    output.voigtRulesOfMixture.engineeringConstants['E2'] = 1 / SVs[1][1];
    output.voigtRulesOfMixture.engineeringConstants['E3'] = 1 / SVs[2][2];
    output.voigtRulesOfMixture.engineeringConstants['G12'] = 1 / SVs[5][5];
    output.voigtRulesOfMixture.engineeringConstants['G13'] = 1 / SVs[4][4];
    output.voigtRulesOfMixture.engineeringConstants['G23'] = 1 / SVs[3][3];
    output.voigtRulesOfMixture.engineeringConstants['nu12'] =
        -1 / SVs[0][0] * SVs[0][1];
    output.voigtRulesOfMixture.engineeringConstants['nu13'] =
        -1 / SVs[0][0] * SVs[0][2];
    output.voigtRulesOfMixture.engineeringConstants['nu23'] =
        -1 / SVs[1][1] * SVs[1][2];

    output.reussRulesOfMixture.engineeringConstants['E1'] = 1 / SRs[0][0];
    output.reussRulesOfMixture.engineeringConstants['E2'] = 1 / SRs[1][1];
    output.reussRulesOfMixture.engineeringConstants['E3'] = 1 / SRs[2][2];
    output.reussRulesOfMixture.engineeringConstants['G12'] = 1 / SRs[5][5];
    output.reussRulesOfMixture.engineeringConstants['G13'] = 1 / SRs[4][4];
    output.reussRulesOfMixture.engineeringConstants['G23'] = 1 / SRs[3][3];
    output.reussRulesOfMixture.engineeringConstants['nu12'] =
        -1 / SRs[0][0] * SRs[0][1];
    output.reussRulesOfMixture.engineeringConstants['nu13'] =
        -1 / SRs[0][0] * SRs[0][2];
    output.reussRulesOfMixture.engineeringConstants['nu23'] =
        -1 / SRs[1][1] * SRs[1][2];

    double eh1 = SHs_Temp[0][0];

    double nuh12 = SHs_Temp[0][1];
    double nuh13 = SHs_Temp[0][2];

    double gh12 = 1 / SHs_Temp[5][5];
    double gh13 = 1 / SHs_Temp[4][4];
    double gh23 = 1 / SHs_Temp[3][3];

    double eh2 = 1 / (SHs_Temp[1][1] + nuh12 * nuh12 / eh1);
    double eh3 = 1 / (SHs_Temp[2][2] + nuh13 * nuh13 / eh1);

    double nuh23 = -eh2 * (SHs_Temp[1][2] + nuh12 * nuh12 / eh1);

    output.hybirdRulesOfMixture.engineeringConstants['E1'] = eh1;
    output.hybirdRulesOfMixture.engineeringConstants['E2'] = eh2;
    output.hybirdRulesOfMixture.engineeringConstants['E3'] = eh3;
    output.hybirdRulesOfMixture.engineeringConstants['G12'] = gh12;
    output.hybirdRulesOfMixture.engineeringConstants['G13'] = gh13;
    output.hybirdRulesOfMixture.engineeringConstants['G23'] = gh23;
    output.hybirdRulesOfMixture.engineeringConstants['nu12'] = nuh12;
    output.hybirdRulesOfMixture.engineeringConstants['nu13'] = nuh13;
    output.hybirdRulesOfMixture.engineeringConstants['nu23'] = nuh23;

    Matrix Shs = Matrix([
      [1 / eh1, -nuh12 / eh1, -nuh13 / eh1, 0, 0, 0],
      [-nuh12 / eh1, 1 / eh2, -nuh23 / eh2, 0, 0, 0],
      [-nuh12 / eh1, -nuh23 / eh2, 1 / eh3, 0, 0, 0],
      [0, 0, 0, 1 / gh23, 0, 0],
      [0, 0, 0, 0, 1 / gh13, 0],
      [0, 0, 0, 0, 0, 1 / gh12]
    ]);

    Matrix Chs = Shs.inverse();

    output.voigtRulesOfMixture.stiffness = CVs.toListOfLists();
    output.voigtRulesOfMixture.compliance = SVs.toListOfLists();

    output.reussRulesOfMixture.stiffness = CRs.toListOfLists();
    output.reussRulesOfMixture.compliance = SRs.toListOfLists();

    output.hybirdRulesOfMixture.stiffness = Chs.toListOfLists();
    output.hybirdRulesOfMixture.compliance = Shs.toListOfLists();

    if (input.analysisType == AnalysisType.thermalElastic) {
      double alpha11_f = input.alpha11_fiber;
      double alpha22_f = input.alpha22_fiber;
      Matrix cteVector_f = Matrix([
        [alpha11_f],
        [alpha22_f],
        [alpha22_f],
        [0],
        [0],
        [0]
      ]);

      double alpha_m = input.alpha_matrix;
      Matrix cteVector_m = Matrix([
        [alpha_m],
        [alpha_m],
        [alpha_m],
        [0],
        [0],
        [0]
      ]);

      Matrix alpha_V =
          CVs.inverse() * (Cf * Vf * cteVector_f + Cm * Vm * cteVector_m);
      Matrix alpha_R = (cteVector_f * Vf + cteVector_m * Vm);
      output.voigtRulesOfMixture.engineeringConstants["alpha11"] =
          alpha_V[0][0];
      output.voigtRulesOfMixture.engineeringConstants["alpha22"] =
          alpha_V[1][0];
      output.voigtRulesOfMixture.engineeringConstants["alpha33"] =
          alpha_V[2][0];

      output.reussRulesOfMixture.engineeringConstants["alpha11"] =
          alpha_R[0][0];
      output.reussRulesOfMixture.engineeringConstants["alpha22"] =
          alpha_R[1][0];
      output.reussRulesOfMixture.engineeringConstants["alpha33"] =
          alpha_R[2][0];

      double alpha11_h = (Vf * ef1 * alpha11_f + Vm * em1 * alpha_m) / eh1;
      output.hybirdRulesOfMixture.engineeringConstants["alpha11"] = alpha11_h;
      double alpha22_h = (Vf * (alpha11_f * nuf12 + alpha22_f) +
          Vm * alpha_m * (1 + num) -
          alpha11_h * nuh12);
      output.hybirdRulesOfMixture.engineeringConstants["alpha22"] = alpha22_h;
      output.hybirdRulesOfMixture.engineeringConstants["alpha33"] = alpha22_h;
    }

    return output;
  }
}
