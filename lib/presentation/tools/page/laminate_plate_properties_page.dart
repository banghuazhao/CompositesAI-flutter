import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/calc_report.dart';
import 'package:swiftcomp/presentation/tools/model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_inputs_mixin.dart';
import 'package:swiftcomp/presentation/tools/widget/legacy_staggered_grid.dart';
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
    extends State<LaminatePlatePropertiesPage> with LaminaInputsMixin {
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  bool validate = false;

  @override
  TransverselyIsotropicMaterial get laminaMaterial =>
      transverselyIsotropicMaterial;

  @override
  TransverselyIsotropicCTE? get laminaCte => transverselyIsotropicCTE;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined),
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
      LaminaConstantsRow(
        material: transverselyIsotropicMaterial,
        validate: validate,
        isPlaneStress: true,
        revision: inputRevision,
        onMaterialSelected: applyLibraryMaterial,
        saveCurrent: saveCurrentMaterial,
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
          material: transverselyIsotropicCTE,
          validate: validate,
          revision: inputRevision,
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
        !laminaModuliPlausible() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }
    if (analysisType == AnalysisType.thermalElastic &&
        !transverselyIsotropicCTE.isValid()) {
      return;
    }

    final units = this.units;
    // Scale moduli into the stress unit so A, B and D come out in N/mm, N and
    // N·mm (kip/in, kip, kip·in); effective moduli are scaled back below.
    const toStress = Units.modulusToStress;
    LaminatePlatePropertiesInput input = LaminatePlatePropertiesInput(
      analysisType: analysisType,
      E1: (transverselyIsotropicMaterial.e1 ?? 0) * toStress,
      E2: (transverselyIsotropicMaterial.e2 ?? 0) * toStress,
      G12: (transverselyIsotropicMaterial.g12 ?? 0) * toStress,
      nu12: transverselyIsotropicMaterial.nu12 ?? 0,
      layupSequence: layupSequence.stringValue,
      layerThickness: layerThickness.value ?? 0,
      alpha11: transverselyIsotropicCTE.alpha11 ?? 0,
      alpha22: transverselyIsotropicCTE.alpha22 ?? 0,
      alpha12: transverselyIsotropicCTE.alpha12 ?? 0,
    );

    LaminatePlatePropertiesOutput output =
        LaminatePlatePropertiesCalculator.calculate(input);
    for (final properties in [
      output.inPlaneProperties,
      output.flexuralProperties,
    ]) {
      properties
        ..E1 /= toStress
        ..E2 /= toStress
        ..G12 /= toStress;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LaminatePlatePropertiesResultPage(
                  output: output,
                  inputs: [
                    ReportInputs.lamina(transverselyIsotropicMaterial, units),
                    if (analysisType == AnalysisType.thermalElastic)
                      ReportInputs.cte(transverselyIsotropicCTE, units),
                    ReportInputs.layup(layupSequence.stringValue,
                        layerThickness.value, units),
                  ],
                )));
  }
}
