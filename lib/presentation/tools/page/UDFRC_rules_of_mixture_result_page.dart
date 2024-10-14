import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/widget/orthotropic_properties_widget.dart';
import 'package:swiftcomp/presentation/tools/widget/result_6by6_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';

class RulesOfMixtureResultPage extends StatefulWidget {
  final UDFRCRulesOfMixtureOutput output;

  const RulesOfMixtureResultPage({Key? key, required this.output})
      : super(key: key);

  @override
  _RulesOfMixtureResultPageState createState() =>
      _RulesOfMixtureResultPageState();
}

class _RulesOfMixtureResultPageState extends State<RulesOfMixtureResultPage> {
  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ToolSettingPage()));
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          title: Text(S.of(context).Results),
        ),
        body: SafeArea(
          child: StaggeredGridView.countBuilder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              crossAxisCount: 8,
              itemCount: resultList.length,
              staggeredTileBuilder: (int index) => StaggeredTile.fit(
                  MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return resultList[index];
              }),
        ));
  }

  List<Widget> get resultList {
    return [
      Text(
        "Voigt Rules of Mixture",
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Result6By6Matrix(
        matrix: widget.output.voigtRulesOfMixture.stiffness,
        title: "Effective 3D Stiffness Matrix",
      ),
      Result6By6Matrix(
        matrix: widget.output.voigtRulesOfMixture.compliance,
        title: "Effective 3D Compliance Matrix",
      ),
      OrthotropicPropertiesWidget(
        title: S.of(context).Engineering_Constants,
        orthotropicMaterial: createOrthotropicMaterial(
            widget.output.voigtRulesOfMixture.engineeringConstants),
      ),
      Text(
        "Reuss Rules of Mixture",
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Result6By6Matrix(
        matrix: widget.output.reussRulesOfMixture.stiffness,
        title: "Effective 3D Stiffness Matrix",
      ),
      Result6By6Matrix(
        matrix: widget.output.reussRulesOfMixture.compliance,
        title: "Effective 3D Compliance Matrix",
      ),
      OrthotropicPropertiesWidget(
        title: S.of(context).Engineering_Constants,
        orthotropicMaterial: createOrthotropicMaterial(
            widget.output.reussRulesOfMixture.engineeringConstants),
      ),
      Text(
        "Hybrid Rules of Mixture",
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Result6By6Matrix(
        matrix: widget.output.hybirdRulesOfMixture.stiffness,
        title: "Effective 3D Stiffness Matrix",
      ),
      Result6By6Matrix(
        matrix: widget.output.hybirdRulesOfMixture.compliance,
        title: "Effective 3D Compliance Matrix",
      ),
      OrthotropicPropertiesWidget(
        title: S.of(context).Engineering_Constants,
        orthotropicMaterial: createOrthotropicMaterial(
            widget.output.hybirdRulesOfMixture.engineeringConstants),
      ),
    ];
  }

  OrthotropicMaterial createOrthotropicMaterial(
      Map<String, double> materialMap) {
    return OrthotropicMaterial(
      e1: materialMap["E1"],
      e2: materialMap["E2"],
      e3: materialMap["E3"],
      g12: materialMap["G12"],
      g13: materialMap["G13"],
      g23: materialMap["G23"],
      nu12: materialMap["nu12"],
      nu13: materialMap["nu13"],
      nu23: materialMap["nu23"],
      alpha11: materialMap["alpha11"],
      alpha22: materialMap["alpha22"],
      alpha12: materialMap["alpha33"],
    );
  }
}
