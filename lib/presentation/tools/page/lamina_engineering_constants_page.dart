import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_engineering_constants_result_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/analysis_type_row.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/lamina_constants_row.dart';

import '../../tools/model/thermal_model.dart';
import '../widget/transversely_thermal_constants_row.dart';

class LaminaEngineeringConstantsPage extends StatefulWidget {
  const LaminaEngineeringConstantsPage({Key? key}) : super(key: key);

  @override
  _LaminaEngineeringConstantsPageState createState() =>
      _LaminaEngineeringConstantsPageState();
}

class _LaminaEngineeringConstantsPageState
    extends State<LaminaEngineeringConstantsPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial =
      TransverselyIsotropicMaterial();
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();
  AnalysisType analysisType = AnalysisType.elastic;
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
          title: Text(S.of(context).Lamina_engineering_constants),
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
          isPlaneStress: true),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
          material: transverselyIsotropicCTE,
          validate: validate,
        ),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.lamina_engineering_constants, context))
    ];
  }

  void _calculate() {
    if (transverselyIsotropicMaterial.isValidInPlane()) {
      if (analysisType == AnalysisType.thermalElastic &&
          !transverselyIsotropicCTE.isValid()) {
        return;
      }

      var resultPage = LaminaEngineeringConstantsResultPage(
        analysisType: analysisType,
        transverselyIsotropicMaterial: transverselyIsotropicMaterial,
        transverselyIsotropicCTE: transverselyIsotropicCTE,
      );

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => resultPage));
    }
  }
}
