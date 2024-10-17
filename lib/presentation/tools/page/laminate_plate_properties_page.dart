import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
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

class LaminatePlatePropertiesPage extends StatefulWidget {
  const LaminatePlatePropertiesPage({Key? key}) : super(key: key);

  @override
  _LaminatePlatePropertiesPageState createState() =>
      _LaminatePlatePropertiesPageState();
}

class _LaminatePlatePropertiesPageState
    extends State<LaminatePlatePropertiesPage> {
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  bool validate = false;

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
      LaminaContantsRow(
        material: transverselyIsotropicMaterial,
        validate: validate,
        isPlaneStress: true,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
          material: transverselyIsotropicCTE,
          validate: validate,
        ),
      LayupSequenceRow(layupSequence: layupSequence, validate: validate),
      LayerThicknessPage(layerThickness: layerThickness, validate: validate),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.Laminate_plate_properties, context))
    ];
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValidInPlane() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }
    if (analysisType == AnalysisType.thermalElastic &&
        !transverselyIsotropicCTE.isValid()) {
      return;
    }

    LaminatePlatePropertiesInput input = LaminatePlatePropertiesInput(
      analysisType: analysisType,
      E1: transverselyIsotropicMaterial.e1 ?? 0,
      E2: transverselyIsotropicMaterial.e2 ?? 0,
      G12: transverselyIsotropicMaterial.g12 ?? 0,
      nu12: transverselyIsotropicMaterial.nu12 ?? 0,
      layupSequence: layupSequence.stringValue,
      layerThickness: layerThickness.value ?? 0,
      alpha11: transverselyIsotropicCTE.alpha11 ?? 0,
      alpha22: transverselyIsotropicCTE.alpha22 ?? 0,
      alpha12: transverselyIsotropicCTE.alpha12 ?? 0,
    );

    LaminatePlatePropertiesOutput output =
        LaminatePlatePropertiesCalculator.calculate(input);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LaminatePlatePropertiesResultPage(
                  output: output,
                )));
  }
}
