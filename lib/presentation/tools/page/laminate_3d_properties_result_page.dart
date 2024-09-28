import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/widget/orthotropic_properties_widget.dart';
import 'package:swiftcomp/presentation/tools/widget/result_6by6_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';

class Laminate3DPropertiesResultPage extends StatefulWidget {
  final Matrix C;
  final Matrix S;
  final OrthotropicMaterial orthotropicMaterial;

  const Laminate3DPropertiesResultPage(
      {Key? key, required this.C, required this.S, required this.orthotropicMaterial})
      : super(key: key);

  @override
  _Laminate3DPropertiesResultPageState createState() => _Laminate3DPropertiesResultPageState();
}

class _Laminate3DPropertiesResultPageState extends State<Laminate3DPropertiesResultPage> {
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
              itemCount: 3,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return [
                  Result6By6Matrix(
                    matrix: widget.C,
                    title: "Effective 3D Stiffness Matrix",
                  ),
                  Result6By6Matrix(
                    matrix: widget.S,
                    title: "Effective 3D Compliance Matrix",
                  ),
                  OrthotropicPropertiesWidget(
                    title: S.of(context).Engineering_Constants,
                    orthotropicMaterial: widget.orthotropicMaterial,
                  ),
                ][index];
              }),
        ));
  }
}
