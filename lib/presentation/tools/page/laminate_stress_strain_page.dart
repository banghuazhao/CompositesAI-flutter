import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/laminar_stress_strain_input.dart';
import 'package:composite_calculator/models/tensor_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/linalg.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/laminate_stress_strain_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layer_thickness_row.dart';
import 'package:swiftcomp/presentation/tools/widget/layup_sequence_row.dart';

import 'laminate_stress_strain_result_page.dart';

class LaminateStressStrainPage extends StatefulWidget {
  const LaminateStressStrainPage({Key? key}) : super(key: key);

  @override
  _LaminateStressStrainPageState createState() =>
      _LaminateStressStrainPageState();
}

class _LaminateStressStrainPageState extends State<LaminateStressStrainPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial = TransverselyIsotropicMaterial();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  MechanicalTensor mechanicalTensor = LaminateStress();
  bool validate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
                Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S
              .of(context)
              .Laminar_stressstrain),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              validate = true;
            });
            _calculate();
          },
          label: Text(S
              .of(context)
              .Calculate),
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
                  staggeredTileBuilder: (int index) =>
                      StaggeredTile.fit(MediaQuery
                          .of(context)
                          .size
                          .width > 600 ? 4 : 8),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (BuildContext context, int index) {
                    return itemList[index];
                  })),
        ));
  }

  List<Widget> get itemList {
    return [
      LaminaContantsRow(
        material: transverselyIsotropicMaterial,
        validate: validate,
        isPlaneStress: true,
      ),
      LayupSequenceRow(layupSequence: layupSequence, validate: validate),
      LayerThicknessPage(layerThickness: layerThickness, validate: validate),
      LaminateStressStrainRow(
        mechanicalTensor: mechanicalTensor,
        validate: validate,
        callback: (value) {
          setState(() {
            if (value == "Stress Resultants") {
              mechanicalTensor = LaminateStress();
            } else {
              mechanicalTensor = LaminateStrain();
            }
          });
        },
      ),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.laminate_stress_strain, context))
    ];
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValidInPlane() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid() ||
        !mechanicalTensor.isValid()) {
      return;
    }
    LaminarStressStrainInput input = LaminarStressStrainInput(
      E1: transverselyIsotropicMaterial.e1 ?? 0,
      E2: transverselyIsotropicMaterial.e2 ?? 0,
      G12: transverselyIsotropicMaterial.g12 ?? 0,
      nu12: transverselyIsotropicMaterial.nu12 ?? 0,
      layupSequence: layupSequence.stringValue,
      layerThickness: layerThickness.value ?? 0,
    );

    MechanicalTensor resultTensor;
    if (mechanicalTensor is LaminateStress) {
      input.tensorType = TensorType.stress;
      input.N11 = (mechanicalTensor as LaminateStress).N11 ?? 0;
      input.N22 = (mechanicalTensor as LaminateStress).N22 ?? 0;
      input.N12 = (mechanicalTensor as LaminateStress).N12 ?? 0;
      input.M11 = (mechanicalTensor as LaminateStress).M11 ?? 0;
      input.M22 = (mechanicalTensor as LaminateStress).M22 ?? 0;
      input.M12 = (mechanicalTensor as LaminateStress).M12 ?? 0;
    } else {
      input.epsilon11 = (mechanicalTensor as LaminateStrain).epsilon11 ?? 0;
      input.epsilon22 = (mechanicalTensor as LaminateStrain).epsilon22 ?? 0;
      input.epsilon12 = (mechanicalTensor as LaminateStrain).epsilon12 ?? 0;
      input.kappa11 = (mechanicalTensor as LaminateStrain).kappa11 ?? 0;
      input.kappa22 = (mechanicalTensor as LaminateStrain).kappa22 ?? 0;
      input.kappa12 = (mechanicalTensor as LaminateStrain).kappa12 ?? 0;
    }

    List<Matrix> QMatrices = LaminarStressStrainCalculator.getQMatrices(
        input);
    LaminarStressStrainOutput output = LaminarStressStrainCalculator.calculate(
        input);


    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LaminateStressStrainResultPage(
                  inputTensor: mechanicalTensor,
                  output: output,
                  thickness: input.layerThickness,
                  Q: QMatrices,
                )));
  }
}
