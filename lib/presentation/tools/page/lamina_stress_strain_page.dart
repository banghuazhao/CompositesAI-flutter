import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/angle_model.dart';
import 'package:swiftcomp/presentation/tools/model/delta_t.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/model/thermal_model.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_result_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/analysis_type_row.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_angle_row.dart';
import 'package:swiftcomp/presentation/tools/widget/plane_stress_strain_row.dart';
import 'package:vector_math/vector_math.dart' as VMath;

import '../../tools/widget/delta_temperature_row.dart';
import '../widget/transversely_thermal_constants_row.dart';

class LaminaStressStrainPage extends StatefulWidget {
  LaminaStressStrainPage({Key? key}) : super(key: key);

  @override
  _LaminaStressStrainPageState createState() => _LaminaStressStrainPageState();
}

class _LaminaStressStrainPageState extends State<LaminaStressStrainPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  LayupAngle layupAngle = LayupAngle();
  DeltaTemperature deltaTemperature = DeltaTemperature();
  MechanicalTensor mechanicalTensor = PlaneStress();
  bool validate = false;
  bool isElastic = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(S.of(context).Lamina_stressstrain),
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
            itemCount: isElastic ? 5 : 7,
            staggeredTileBuilder: (int index) => StaggeredTile.fit(
                MediaQuery.of(context).size.width > 600 ? 4 : 8),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemBuilder: (BuildContext context, int index) {
              return [
                AnalysisType(callback: (analysisType) {
                  isElastic = analysisType == "Elastic";
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
                LayupAngleRow(
                  layupAngle: layupAngle,
                  validate: validate,
                ),
                if (!isElastic)
                  DeltaTemperatureRow(
                    deltaTemperature: deltaTemperature,
                    validate: validate,
                  ),
                PlaneStressStrainRow(
                  mechanicalTensor: mechanicalTensor,
                  validate: validate,
                  callback: (value) {
                    setState(() {
                      if (value == "Stress") {
                        mechanicalTensor = PlaneStress();
                      } else {
                        mechanicalTensor = PlaneStrain();
                      }
                    });
                  },
                ),
                DescriptionItem(
                    content: DescriptionModels.getDescription(
                        DescriptionType.lamina_stress_strain, context))
              ][index];
            },
          ),
        ),
      ),
    );
  }

  void _calculate() {
    if (transverselyIsotropicMaterial.isValidInPlane() &&
        layupAngle.isValid() &&
        mechanicalTensor.isValid()) {
      if (!isElastic && !transverselyIsotropicCTE.isValid()) {
        return;
      }
      double e1 = transverselyIsotropicMaterial.e1!;
      double e2 = transverselyIsotropicMaterial.e2!;
      double g12 = transverselyIsotropicMaterial.g12!;
      double nu12 = transverselyIsotropicMaterial.nu12!;
      double angleRadian = VMath.radians(layupAngle.value!);
      var S = VMath.Matrix3.fromList(
          [1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
      var Q = VMath.Matrix3.fromList(
          [1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
      Q.invert();
      double s = sin(angleRadian);
      double c = cos(angleRadian);
      var T_epsilon = VMath.Matrix3.fromList([
        c * c,
        s * s,
        s * c,
        s * s,
        c * c,
        -s * c,
        -2 * s * c,
        2 * s * c,
        c * c - s * s
      ]);
      var T_sigma = VMath.Matrix3.fromList([
        c * c,
        s * s,
        2 * s * c,
        s * s,
        c * c,
        -2 * s * c,
        -s * c,
        s * c,
        c * c - s * s
      ]);
      var Q_bar = T_epsilon.transposed() * Q * T_epsilon;
      var S_bar = T_sigma.transposed() * S * T_sigma;

      MechanicalTensor resultTensor;
      if (mechanicalTensor is PlaneStrain) {
        double epsilon11 = (mechanicalTensor as PlaneStrain).epsilon11!;
        double epsilon22 = (mechanicalTensor as PlaneStrain).epsilon22!;
        double gamma12 = (mechanicalTensor as PlaneStrain).gamma12!;
        var strainVector = VMath.Vector3.array([epsilon11, epsilon22, gamma12]);
        var stressVector;
        if (isElastic) {
          stressVector = Q_bar * strainVector;
        } else {
          double alpha11DeltaT =
              transverselyIsotropicCTE.alpha11! * deltaTemperature.value!;
          double alpha22DeltaT =
              transverselyIsotropicCTE.alpha22! * deltaTemperature.value!;
          double alpha12DeltaT =
              transverselyIsotropicCTE.alpha12! * deltaTemperature.value!;
          var cteVector = VMath.Vector3.array(
              [alpha11DeltaT, alpha22DeltaT, 2 * alpha12DeltaT]);
          var R_epsilon_e = VMath.Matrix3.fromList([
            c * c,
            s * s,
            -s * c,
            s * s,
            c * c,
            s * c,
            2 * s * c,
            -2 * s * c,
            c * c - s * s
          ]);
          stressVector = Q_bar * (strainVector - R_epsilon_e * cteVector);
        }
        resultTensor =
            PlaneStress.from(stressVector[0], stressVector[1], stressVector[2]);
        // print(stressVector);
      } else {
        double sigma11 = (mechanicalTensor as PlaneStress).sigma11!;
        double sigma22 = (mechanicalTensor as PlaneStress).sigma22!;
        double sigma12 = (mechanicalTensor as PlaneStress).sigma12!;
        var stressVector = VMath.Vector3.array([sigma11, sigma22, sigma12]);
        var strainVector;
        if (isElastic) {
          strainVector = S_bar * stressVector;
        } else {
          double alpha11DeltaT =
              transverselyIsotropicCTE.alpha11! * deltaTemperature.value!;
          double alpha22DeltaT =
              transverselyIsotropicCTE.alpha22! * deltaTemperature.value!;
          double alpha12DeltaT =
              transverselyIsotropicCTE.alpha12! * deltaTemperature.value!;
          var cteVector = VMath.Vector3.array(
              [alpha11DeltaT, alpha22DeltaT, 2 * alpha12DeltaT]);
          var R_epsilon_e = VMath.Matrix3.fromList([
            c * c,
            s * s,
            -s * c,
            s * s,
            c * c,
            s * c,
            2 * s * c,
            -2 * s * c,
            c * c - s * s
          ]);
          strainVector = S_bar * stressVector + R_epsilon_e * cteVector;
        }
        resultTensor =
            PlaneStrain.from(strainVector[0], strainVector[1], strainVector[2]);
        // print(strainVector);
      }

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LaminaStressStrainResult(
                  resultTensor: resultTensor, Q_bar: Q_bar, S_bar: S_bar)));
    }
  }
}
