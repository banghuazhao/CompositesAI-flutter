import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/linalg.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/in_plane_properties_model.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/page/laminate_plate_properties_result_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/analysis_type_row.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layer_thickness_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';

import '../../tools/model/thermal_model.dart';
import '../widget/transversely_thermal_constants_row.dart';
import 'package:vector_math/vector_math.dart' as VMath;

class LaminatePlatePropertiesPage extends StatefulWidget {
  const LaminatePlatePropertiesPage({Key? key}) : super(key: key);

  @override
  _LaminatePlatePropertiesPageState createState() =>
      _LaminatePlatePropertiesPageState();
}

class _LaminatePlatePropertiesPageState
    extends State<LaminatePlatePropertiesPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
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
          title: Text(S.of(context).Laminate_plate_properties),
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
                        isPlaneStress: true,
                      ),
                      if (!isElastic)
                        TransverselyThermalConstantsRow(
                          material: transverselyIsotropicCTE,
                          validate: validate,
                        ),
                      LayupSequenceRow(
                          layupSequence: layupSequence, validate: validate),
                      LayerThicknessPage(
                          layerThickness: layerThickness, validate: validate),
                      DescriptionItem(
                          content: DescriptionModels.getDescription(
                              DescriptionType.Laminate_plate_properties,
                              context))
                    ][index];
                  })),
        ));
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValidInPlane() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }
    if (!isElastic && !transverselyIsotropicCTE.isValid()) {
      return;
    }
    Matrix A = Matrix.fill(3, 3);
    Matrix B = Matrix.fill(3, 3);
    Matrix D = Matrix.fill(3, 3);
    double thickness = layerThickness.value!;
    int nPly = layupSequence.layups!.length;

    List<double> bzi = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    double e1 = transverselyIsotropicMaterial.e1!;
    double e2 = transverselyIsotropicMaterial.e2!;
    double g12 = transverselyIsotropicMaterial.g12!;
    double nu12 = transverselyIsotropicMaterial.nu12!;

    for (int i = 0; i < nPly; i++) {
      double layup = layupSequence.layups![i];

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

    double h = nPly * thickness;

    Matrix Ses = A.inverse() * h;
    Matrix Sesf = D.inverse() * (pow(h, 3) / 12);

    InPlanePropertiesModel inPlanePropertiesModel = InPlanePropertiesModel();
    inPlanePropertiesModel.e1 = 1 / Ses[0][0];
    inPlanePropertiesModel.e2 = 1 / Ses[1][1];
    inPlanePropertiesModel.g12 = 1 / Ses[2][2];
    inPlanePropertiesModel.nu12 = -1 / Ses[0][0] * Ses[0][1];
    inPlanePropertiesModel.eta121 = -1 / Ses[2][2] * Ses[0][2];
    inPlanePropertiesModel.eta122 = -1 / Ses[2][2] * Ses[1][2];

    InPlanePropertiesModel flexuralPropertiesModel = InPlanePropertiesModel();
    flexuralPropertiesModel.e1 = 1 / Sesf[0][0];
    flexuralPropertiesModel.e2 = 1 / Sesf[1][1];
    flexuralPropertiesModel.g12 = 1 / Sesf[2][2];
    flexuralPropertiesModel.nu12 = -1 / Sesf[0][0] * Sesf[0][1];
    flexuralPropertiesModel.eta121 = -1 / Sesf[2][2] * Sesf[0][2];
    flexuralPropertiesModel.eta122 = -1 / Sesf[2][2] * Sesf[1][2];

    if (!isElastic) {
      double alpha11 = transverselyIsotropicCTE.alpha11!;
      double alpha22 = transverselyIsotropicCTE.alpha22!;
      double alpha12 = transverselyIsotropicCTE.alpha12!;

      Matrix temp_eff = Matrix.fill(3, 1);
      Matrix temp_flex = Matrix.fill(3, 1);

      for (int i = 0; i < nPly; i++) {
        double layup = layupSequence.layups![i];

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
        temp_flex += Qe * R_epsilon_e * cteVector * (thickness * bzi[i] * bzi[i] + thickness * thickness * thickness / 12);
      }

      Matrix cteVector_effective = A.inverse() * temp_eff;
      Matrix cteVector_flexural = D.inverse() * temp_flex;

      inPlanePropertiesModel.alpha11 = cteVector_effective[0][0];
      inPlanePropertiesModel.alpha22 = cteVector_effective[1][0];
      inPlanePropertiesModel.alpha12 = cteVector_effective[2][0];

      flexuralPropertiesModel.alpha11 = cteVector_flexural[0][0];
      flexuralPropertiesModel.alpha22 = cteVector_flexural[1][0];
      flexuralPropertiesModel.alpha12 = cteVector_flexural[2][0];
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LaminatePlatePropertiesResultPage(
                  A: A,
                  B: B,
                  D: D,
                  inPlanePropertiesModel: inPlanePropertiesModel,
                  flexuralPropertiesModel: flexuralPropertiesModel,
                )));
  }
}
