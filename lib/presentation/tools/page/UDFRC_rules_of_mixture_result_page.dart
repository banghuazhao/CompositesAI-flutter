import 'package:composite_calculator/utils/matrix_to_list_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/widget/orthotropic_properties_widget.dart';
import 'package:swiftcomp/presentation/tools/widget/result_6by6_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';

class RulesOfMixtureResultPage extends StatefulWidget {
  final Matrix Cv;
  final Matrix Cr;
  final Matrix Ch;
  final Matrix Sv;
  final Matrix Sr;
  final Matrix Sh;
  final OrthotropicMaterial voigtConstants;
  final OrthotropicMaterial reussConstants;
  final OrthotropicMaterial hybridConstants;

  const RulesOfMixtureResultPage(
      {Key? key,
      required this.Cv,
      required this.Cr,
      required this.Ch,
      required this.Sv,
      required this.Sr,
      required this.Sh,
      required this.voigtConstants,
      required this.reussConstants,
      required this.hybridConstants})
      : super(key: key);

  @override
  _RulesOfMixtureResultPageState createState() => _RulesOfMixtureResultPageState();
}

class _RulesOfMixtureResultPageState extends State<RulesOfMixtureResultPage> {
  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ToolSettingPage()));
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
              itemCount: 12,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return [
                  Text(
                    "Voigt Rules of Mixture",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Result6By6Matrix(
                    matrix: widget.Cv.toListOfLists(),
                    title: "Effective 3D Stiffness Matrix",
                  ),
                  Result6By6Matrix(
                    matrix: widget.Sv.toListOfLists(),
                    title: "Effective 3D Compliance Matrix",
                  ),
                  OrthotropicPropertiesWidget(
                    title: S.of(context).Engineering_Constants,
                    orthotropicMaterial: widget.voigtConstants,
                  ),
                  Text(
                    "Reuss Rules of Mixture",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Result6By6Matrix(
                    matrix: widget.Cr.toListOfLists(),
                    title: "Effective 3D Stiffness Matrix",
                  ),
                  Result6By6Matrix(
                    matrix: widget.Sr.toListOfLists(),
                    title: "Effective 3D Compliance Matrix",
                  ),
                  OrthotropicPropertiesWidget(
                    title: S.of(context).Engineering_Constants,
                    orthotropicMaterial: widget.reussConstants,
                  ),
                  Text(
                    "Hybrid Rules of Mixture",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Result6By6Matrix(
                    matrix: widget.Ch.toListOfLists(),
                    title: "Effective 3D Stiffness Matrix",
                  ),
                  Result6By6Matrix(
                    matrix: widget.Sh.toListOfLists(),
                    title: "Effective 3D Compliance Matrix",
                  ),
                  OrthotropicPropertiesWidget(
                    title: S.of(context).Engineering_Constants,
                    orthotropicMaterial: widget.hybridConstants,
                  ),
                ][index];
              }),
        ));
  }
}
