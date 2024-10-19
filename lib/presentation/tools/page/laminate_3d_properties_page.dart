import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  OrthotropicMaterial orthotropicMaterial = OrthotropicMaterial();

  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
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
      LaminaConstantsRow(
        material: transverselyIsotropicMaterial,
        validate: validate,
        isPlaneStress: false,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
            material: transverselyIsotropicCTE, validate: validate),
      LayupSequenceRow(layupSequence: layupSequence, validate: validate),
      LayerThicknessPage(layerThickness: layerThickness, validate: validate),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.laminate_3d_properties, context))
    ];
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValid() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }

    if (analysisType == AnalysisType.thermalElastic &&
        !transverselyIsotropicCTE.isValid()) {
      return;
    }

    Laminate3DPropertiesInput input = Laminate3DPropertiesInput(
      analysisType: analysisType,
      E1: transverselyIsotropicMaterial.e1 ?? 0,
      E2: transverselyIsotropicMaterial.e2 ?? 0,
      G12: transverselyIsotropicMaterial.g12 ?? 0,
      nu12: transverselyIsotropicMaterial.nu12 ?? 0,
      nu23: transverselyIsotropicMaterial.nu23 ?? 0,
      layupSequence: layupSequence.stringValue,
      layerThickness: layerThickness.value ?? 0,
      alpha11: transverselyIsotropicCTE.alpha11 ?? 0,
      alpha22: transverselyIsotropicCTE.alpha22 ?? 0,
      alpha12: transverselyIsotropicCTE.alpha12 ?? 0,
    );

    Laminate3DPropertiesOutput output =
        Laminate3DPropertiesCalculator.calculate(input);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Laminate3DPropertiesResultPage(output: output)));
  }
}
