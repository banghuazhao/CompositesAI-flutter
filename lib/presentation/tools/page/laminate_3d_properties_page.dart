import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/linalg.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/analysis_type_row.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layer_thickness_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';
import 'package:swiftcomp/presentation/tools/widget/transversely_thermal_constants_row.dart';

import '../../tools/model/thermal_model.dart';
import 'laminate_3d_properties_result_page.dart';

class Laminate3DPropertiesPage extends StatefulWidget {
  const Laminate3DPropertiesPage({Key? key}) : super(key: key);

  @override
  _Laminate3DPropertiesPageState createState() =>
      _Laminate3DPropertiesPageState();
}

class _Laminate3DPropertiesPageState extends State<Laminate3DPropertiesPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  OrthotropicMaterial orthotropicMaterial =
  OrthotropicMaterial();

  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  bool validate = false;
  bool isElastic = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).Laminate_3D_properties),
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
                  itemCount: isElastic ? 5 : 6,
                  staggeredTileBuilder: (int index) => StaggeredTile.fit(
                      MediaQuery.of(context).size.width > 600 ? 4 : 8),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (BuildContext context, int index) {
                    return [
                      AnalysisType(callback: (type) {
                        isElastic = type == "Elastic";
                      }),
                      LaminaContantsRow(
                        material: transverselyIsotropicMaterial,
                        validate: validate,
                        isPlaneStress: false,
                      ),
                      if (!isElastic)
                        TransverselyThermalConstantsRow(
                            material: transverselyIsotropicCTE,
                            validate: validate),
                      LayupSequenceRow(
                          layupSequence: layupSequence, validate: validate),
                      LayerThicknessPage(
                          layerThickness: layerThickness, validate: validate),
                      DescriptionItem(
                          content: DescriptionModels.getDescription(
                              DescriptionType.laminate_3d_properties, context))
                    ][index];
                  })),
        ));
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValid() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }

    if (!isElastic && !transverselyIsotropicCTE.isValid()) {
      return;
    }

    double thickness = layerThickness.value!;
    int nPly = layupSequence.layups!.length;

    List<double> bzi = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    Matrix C = Matrix.fill(6, 6);
    Matrix alpha_temp = Matrix.fill(3, 1);
    Matrix Q_start = Matrix.fill(3, 3);

    for (int i = 0; i < nPly; i++) {
      double layup = layupSequence.layups![i];
      double e1 = transverselyIsotropicMaterial.e1!;
      double e2 = transverselyIsotropicMaterial.e2!;
      double g12 = transverselyIsotropicMaterial.g12!;
      double nu12 = transverselyIsotropicMaterial.nu12!;
      double nu23 = transverselyIsotropicMaterial.nu23!;
      double e3 = e2;
      double g13 = g12;
      double g23 = e2 / (2 * (1 + nu23));
      double nu13 = nu12;
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

      if (!isElastic) {
        double alpha11 = transverselyIsotropicCTE.alpha11!;
        double alpha22 = transverselyIsotropicCTE.alpha22!;
        double alpha12 = transverselyIsotropicCTE.alpha12!;
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

    OrthotropicMaterial orthotropicMaterial = OrthotropicMaterial();
    orthotropicMaterial.e1 = 1 / S[0][0];
    orthotropicMaterial.e2 = 1 / S[1][1];
    orthotropicMaterial.e3 = 1 / S[2][2];
    orthotropicMaterial.g12 = 1 / S[5][5];
    orthotropicMaterial.g13 = 1 / S[4][4];
    orthotropicMaterial.g23 = 1 / S[3][3];
    orthotropicMaterial.nu12 = -1 / S[0][0] * S[0][1];
    orthotropicMaterial.nu13 = -1 / S[0][0] * S[0][2];
    orthotropicMaterial.nu23 = -1 / S[1][1] * S[1][2];

    if (!isElastic) {
      Q_start = Q_start * (1 / nPly);
      alpha_temp = alpha_temp * (1 / nPly);
      Matrix alpha_CTE = Q_start.inverse() * alpha_temp;
      orthotropicMaterial.alpha11 = alpha_CTE[0][0];
      orthotropicMaterial.alpha22 = alpha_CTE[1][0];
      orthotropicMaterial.alpha12 = alpha_CTE[2][0];
    }

    print(C);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Laminate3DPropertiesResultPage(
                  C: C,
                  S: S,
                  orthotropicMaterial: orthotropicMaterial,
                )));
  }
}
