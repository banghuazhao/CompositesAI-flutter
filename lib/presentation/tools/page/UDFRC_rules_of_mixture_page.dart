import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/UDFRC_rules_of_mixture_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

      UDFRCRulesOfMixtureInput input = UDFRCRulesOfMixtureInput(
        analysisType: analysisType,
        E1_fiber: fiberMaterial.e1 ?? 0,
        E2_fiber: fiberMaterial.e2 ?? 0,
        G12_fiber: fiberMaterial.g12 ?? 0,
        nu12_fiber: fiberMaterial.nu12 ?? 0,
        nu23_fiber: fiberMaterial.nu23 ?? 0,
        alpha11_fiber: transverselyIsotropicCTE.alpha11 ?? 0,
        alpha22_fiber: transverselyIsotropicCTE.alpha22 ?? 0,
        E_matrix: matrixMaterial.e ?? 0,
        nu_matrix: matrixMaterial.nu ?? 0,
        alpha_matrix: isotropicCTE.alpha ?? 0,
        fiberVolumeFraction: fiberVolumeFraction.value ?? 0,
      );

      UDFRCRulesOfMixtureOutput output =
          UDFRCRulesOfMixtureCalculator.calculate(input);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RulesOfMixtureResultPage(output: output)));
    }
  }
}
