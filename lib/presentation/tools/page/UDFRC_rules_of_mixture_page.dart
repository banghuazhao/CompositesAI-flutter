import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/volume_fraction_model.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_result_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/isotropic_material_row.dart';
import 'package:swiftcomp/presentation/tools/widget/isotropic_thermal_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/transversely_isotropic_row.dart';
import 'package:swiftcomp/presentation/tools/widget/volume_fraction_row.dart';

import '../../tools/model/thermal_model.dart';
import '../../tools/widget/analysis_type_row.dart';
import '../widget/transversely_thermal_constants_row.dart';

class RulesOfMixturePage extends StatefulWidget {
  const RulesOfMixturePage({Key? key}) : super(key: key);

  @override
  _RulesOfMixturePageState createState() => _RulesOfMixturePageState();
}

class _RulesOfMixturePageState extends State<RulesOfMixturePage> {
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial fiberMaterial = TransverselyIsotropicMaterial();
  IsotropicMaterial matrixMaterial = IsotropicMaterial();
  VolumeFraction fiberVolumeFraction = VolumeFraction();
  bool validate = false;

  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();

  IsotropicCTE isotropicCTE = IsotropicCTE();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).UDFRC_Properties),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              validate = true;
            });
            _calculate();
          },
          label: Text(S.of(context).Calculate),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (_) {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
              child: StaggeredGridView.countBuilder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  crossAxisCount: 8,
                  itemCount: itemList.length,
                  staggeredTileBuilder: (int index) => StaggeredTile.fit(
                      MediaQuery.of(context).size.width > 600 ? 4 : 8),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (BuildContext context, int index) {
                    return itemList[index];
                  })),
        ));
  }

  List<Widget> get itemList {
    return [
      AnalysisTypeRow(
        analysisType: analysisType,
        onChanged: (newValue) {
          setState(() {
            analysisType = newValue;
          });
        },
      ),
      TransverselyIsotropicRow(
        material: fiberMaterial,
        validate: validate,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
            material: transverselyIsotropicCTE,
            title: "Fiber CTEs",
            shouldConsider12: false,
            validate: validate),
      IsotropicMaterialRow(
        title: "Matrix Properties",
        material: matrixMaterial,
        validate: validate,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        IsotropicThermalConstantsRow(
            material: isotropicCTE, title: "Matrix CTE", validate: validate),
      VolumeFractionRow(
          volumeFraction: fiberVolumeFraction, validate: validate),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.UDFRC_rules_of_mixtures, context))
    ];
  }

  void _calculate() {
    if (fiberMaterial.isValid() &&
        matrixMaterial.isValid() &&
        fiberVolumeFraction.isValid()) {
      if (analysisType == AnalysisType.thermalElastic &&
          !transverselyIsotropicCTE.isValid() &&
          !isotropicCTE.isValid()) {
        return;
      }

      double Vf = fiberVolumeFraction.value!;
      // double Ef = fiberMaterial.e1!;
      // double nuf = fiberMaterial.nu12!;
      // double Gf = Ef / (2 * (1 + nuf));
      double ef1 = fiberMaterial.e1!;
      double ef2 = fiberMaterial.e2!;
      double ef3 = fiberMaterial.e2!;
      double gf12 = fiberMaterial.g12!;
      double gf13 = fiberMaterial.g12!;
      double gf23 = fiberMaterial.e2! / (2 * (1 + fiberMaterial.nu23!));
      double nuf12 = fiberMaterial.nu12!;
      double nuf13 = fiberMaterial.nu12!;
      double nuf23 = fiberMaterial.nu23!;

      double Vm = 1 - Vf;
      double Em = matrixMaterial.e!;
      double num = matrixMaterial.nu!;
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

      OrthotropicMaterial voigtEngineeringConstants = OrthotropicMaterial();
      voigtEngineeringConstants.e1 = 1 / SVs[0][0];
      voigtEngineeringConstants.e2 = 1 / SVs[1][1];
      voigtEngineeringConstants.e3 = 1 / SVs[2][2];
      voigtEngineeringConstants.g12 = 1 / SVs[5][5];
      voigtEngineeringConstants.g13 = 1 / SVs[4][4];
      voigtEngineeringConstants.g23 = 1 / SVs[3][3];
      voigtEngineeringConstants.nu12 = -1 / SVs[0][0] * SVs[0][1];
      voigtEngineeringConstants.nu13 = -1 / SVs[0][0] * SVs[0][2];
      voigtEngineeringConstants.nu23 = -1 / SVs[1][1] * SVs[1][2];

      OrthotropicMaterial reussEngineeringConstants = OrthotropicMaterial();
      reussEngineeringConstants.e1 = 1 / SRs[0][0];
      reussEngineeringConstants.e2 = 1 / SRs[1][1];
      reussEngineeringConstants.e3 = 1 / SRs[2][2];
      reussEngineeringConstants.g12 = 1 / SRs[5][5];
      reussEngineeringConstants.g13 = 1 / SRs[4][4];
      reussEngineeringConstants.g23 = 1 / SRs[3][3];
      reussEngineeringConstants.nu12 = -1 / SRs[0][0] * SRs[0][1];
      reussEngineeringConstants.nu13 = -1 / SRs[0][0] * SRs[0][2];
      reussEngineeringConstants.nu23 = -1 / SRs[1][1] * SRs[1][2];

      OrthotropicMaterial hybridEngineeringConstants = OrthotropicMaterial();
      hybridEngineeringConstants.e1 = SHs_Temp[0][0];

      hybridEngineeringConstants.nu12 = SHs_Temp[0][1];
      hybridEngineeringConstants.nu13 = SHs_Temp[0][2];

      hybridEngineeringConstants.g12 = 1 / SHs_Temp[5][5];
      hybridEngineeringConstants.g13 = 1 / SHs_Temp[4][4];
      hybridEngineeringConstants.g23 = 1 / SHs_Temp[3][3];

      hybridEngineeringConstants.e2 = 1 /
          (SHs_Temp[1][1] +
              hybridEngineeringConstants.nu12! *
                  hybridEngineeringConstants.nu12! /
                  hybridEngineeringConstants.e1!);

      hybridEngineeringConstants.e3 = 1 /
          (SHs_Temp[2][2] +
              hybridEngineeringConstants.nu13! *
                  hybridEngineeringConstants.nu13! /
                  hybridEngineeringConstants.e1!);

      hybridEngineeringConstants.nu23 = -hybridEngineeringConstants.e2! *
          (SHs_Temp[1][2] +
              hybridEngineeringConstants.nu12! *
                  hybridEngineeringConstants.nu12! /
                  hybridEngineeringConstants.e1!);

      double eh1 = hybridEngineeringConstants.e1!;
      double eh2 = hybridEngineeringConstants.e2!;
      double eh3 = hybridEngineeringConstants.e3!;
      double gh12 = hybridEngineeringConstants.g12!;
      double gh13 = hybridEngineeringConstants.g13!;
      double gh23 = hybridEngineeringConstants.g23!;
      double nuh12 = hybridEngineeringConstants.nu12!;
      double nuh13 = hybridEngineeringConstants.nu13!;
      double nuh23 = hybridEngineeringConstants.nu23!;

      Matrix Shs = Matrix([
        [1 / eh1, -nuh12 / eh1, -nuh13 / eh1, 0, 0, 0],
        [-nuh12 / eh1, 1 / eh2, -nuh23 / eh2, 0, 0, 0],
        [-nuh12 / eh1, -nuh23 / eh2, 1 / eh3, 0, 0, 0],
        [0, 0, 0, 1 / gh23, 0, 0],
        [0, 0, 0, 0, 1 / gh13, 0],
        [0, 0, 0, 0, 0, 1 / gh12]
      ]);

      Matrix Chs = Shs.inverse();

      if (analysisType == AnalysisType.thermalElastic) {
        double alpha11_f = transverselyIsotropicCTE.alpha11!;
        double alpha22_f = transverselyIsotropicCTE.alpha22!;
        Matrix cteVector_f = Matrix([
          [alpha11_f],
          [alpha22_f],
          [alpha22_f],
          [0],
          [0],
          [0]
        ]);

        double alpha_m = isotropicCTE.alpha!;
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
        voigtEngineeringConstants.alpha11 = alpha_V[0][0];
        voigtEngineeringConstants.alpha22 = alpha_V[1][0];
        voigtEngineeringConstants.alpha33 = alpha_V[2][0];

        reussEngineeringConstants.alpha11 = alpha_R[0][0];
        reussEngineeringConstants.alpha22 = alpha_R[1][0];
        reussEngineeringConstants.alpha33 = alpha_R[2][0];

        double alpha11_h = (Vf * ef1 * alpha11_f + Vm * em1 * alpha_m) / eh1;
        hybridEngineeringConstants.alpha11 = alpha11_h;
        double alpha22_h = (Vf * (alpha11_f * nuf12 + alpha22_f) +
            Vm * alpha_m * (1 + num) -
            alpha11_h * nuh12);
        hybridEngineeringConstants.alpha22 = alpha22_h;
        hybridEngineeringConstants.alpha33 = alpha22_h;
      }

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RulesOfMixtureResultPage(
                  Cv: CVs,
                  Cr: CRs,
                  Ch: Chs,
                  Sv: SVs,
                  Sr: SRs,
                  Sh: Shs,
                  voigtConstants: voigtEngineeringConstants,
                  reussConstants: reussEngineeringConstants,
                  hybridConstants: hybridEngineeringConstants)));
    }
  }
}
