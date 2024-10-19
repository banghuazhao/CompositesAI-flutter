import 'package:composite_calculator/composite_calculator.dart';
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

import '../../tools/widget/delta_temperature_row.dart';
import '../widget/transversely_thermal_constants_row.dart';

class LaminaStressStrainPage extends StatefulWidget {
  LaminaStressStrainPage({Key? key}) : super(key: key);

  @override
  _LaminaStressStrainPageState createState() => _LaminaStressStrainPageState();
}

class _LaminaStressStrainPageState extends State<LaminaStressStrainPage> {
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  LayupAngle layupAngle = LayupAngle();
  DeltaTemperature deltaTemperature = DeltaTemperature();
  MechanicalTensor mechanicalTensor = PlaneStress();
  bool validate = false;

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
            itemCount: itemList.length,
            staggeredTileBuilder: (int index) => StaggeredTile.fit(
                MediaQuery.of(context).size.width > 600 ? 4 : 8),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemBuilder: (BuildContext context, int index) {
              return itemList[index];
            },
          ),
        ),
      ),
    );
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
      LaminaConstantsRow(
        material: transverselyIsotropicMaterial,
        validate: validate,
        isPlaneStress: true,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
          material: transverselyIsotropicCTE,
          validate: validate,
        ),
      if (analysisType == AnalysisType.thermalElastic)
        DeltaTemperatureRow(
          deltaTemperature: deltaTemperature,
          validate: validate,
        ),
      LayupAngleRow(
        layupAngle: layupAngle,
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
    ];
  }

  void _calculate() {
    if (transverselyIsotropicMaterial.isValidInPlane() &&
        layupAngle.isValid() &&
        mechanicalTensor.isValid()) {
      if (analysisType == AnalysisType.thermalElastic &&
          !transverselyIsotropicCTE.isValid()) {
        return;
      }

      LaminaStressStrainInput input = LaminaStressStrainInput(
        analysisType: analysisType,
        E1: transverselyIsotropicMaterial.e1 ?? 0,
        E2: transverselyIsotropicMaterial.e2 ?? 0,
        G12: transverselyIsotropicMaterial.g12 ?? 0,
        nu12: transverselyIsotropicMaterial.nu12 ?? 0,
        layupAngle: layupAngle.value ?? 0,
        alpha11: transverselyIsotropicCTE.alpha11 ?? 0,
        alpha22: transverselyIsotropicCTE.alpha22 ?? 0,
        alpha12: transverselyIsotropicCTE.alpha12 ?? 0,
        deltaT: deltaTemperature.value ?? 0,
      );

      if (mechanicalTensor is PlaneStrain) {
        double epsilon11 = (mechanicalTensor as PlaneStrain).epsilon11!;
        double epsilon22 = (mechanicalTensor as PlaneStrain).epsilon22!;
        double gamma12 = (mechanicalTensor as PlaneStrain).gamma12!;
        input.tensorType = TensorType.strain;
        input.epsilon11 = epsilon11;
        input.epsilon22 = epsilon22;
        input.gamma12 = gamma12;
      } else {
        double sigma11 = (mechanicalTensor as PlaneStress).sigma11!;
        double sigma22 = (mechanicalTensor as PlaneStress).sigma22!;
        double sigma12 = (mechanicalTensor as PlaneStress).sigma12!;
        input.tensorType = TensorType.stress;
        input.sigma11 = sigma11;
        input.sigma22 = sigma22;
        input.sigma12 = sigma12;
      }

      LaminaStressStrainOutput output =
          LaminaStressStrainCalculator.calculate(input);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LaminaStressStrainResult(output: output)));
    }
  }
}
