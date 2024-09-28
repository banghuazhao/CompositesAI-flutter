import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/in_plane_properties_model.dart';
import 'package:swiftcomp/presentation/tools/widget/result_3by3_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class LaminatePlatePropertiesResultPage extends StatefulWidget {
  final Matrix A;
  final Matrix B;
  final Matrix D;
  final InPlanePropertiesModel inPlanePropertiesModel;
  final InPlanePropertiesModel flexuralPropertiesModel;

  const LaminatePlatePropertiesResultPage(
      {Key? key,
      required this.A,
      required this.B,
      required this.D,
      required this.inPlanePropertiesModel,
      required this.flexuralPropertiesModel})
      : super(key: key);

  @override
  _LaminatePlatePropertiesResultPageState createState() =>
      _LaminatePlatePropertiesResultPageState();
}

class _LaminatePlatePropertiesResultPageState extends State<LaminatePlatePropertiesResultPage> {
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
              itemCount: 5,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return [
                  Result3By3Matrix(
                    matrix: widget.A,
                    title: "A Matrix",
                  ),
                  Result3By3Matrix(
                    matrix: widget.B,
                    title: "B Matrix",
                  ),
                  Result3By3Matrix(
                    matrix: widget.D,
                    title: "D Matrix",
                  ),
                  InPlanePropertiesWidget(
                    title: "In-Plane Properties",
                    explain: "In-Plane properties are only valid for symmetric laminates only.",
                    inPlanePropertiesModel: widget.inPlanePropertiesModel,
                  ),
                  InPlanePropertiesWidget(
                    title: "Flexural Properties",
                    explain: "Flexural properties are only valid for symmetric laminates only.",
                    inPlanePropertiesModel: widget.flexuralPropertiesModel,
                  )
                ][index];
              }),
        ));
  }
}

class InPlanePropertiesWidget extends StatelessWidget {
  final String title;
  final String? explain;
  final InPlanePropertiesModel inPlanePropertiesModel;
  const InPlanePropertiesWidget(
      {Key? key, required this.title, required this.explain, required this.inPlanePropertiesModel})
      : super(key: key);

  _propertyRow(BuildContext context, String title, double? value) {
    return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
      return SizedBox(
        height: 40,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            getValue(value, precs.precision),
            style: Theme.of(context).textTheme.bodySmall,
          )
        ]),
      );
    });
  }

  String getValue(double? value, int precision) {
    String valueString = "";
    if (value != null) {
      valueString = value == 0 ? "0" : value.toStringAsExponential(precision).toString();
    }
    return valueString;
  }

  double calculateHeight() {
    if (inPlanePropertiesModel.alpha11 != null) {
      return 40 * 9 + 20;
    } else {
      return 40 * 6 + 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (explain != null)
                  IconButton(
                    onPressed: () {
                      Dialog dialog = Dialog(
                        insetPadding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)), //this right here
                        child: Container(
                            padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                            child: Text(explain!)),
                      );
                      showDialog(context: context, builder: (BuildContext context) => dialog);
                    },
                    icon: Icon(
                      Icons.help_outline_rounded,
                      color: Colors.grey,
                    ),
                  )
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: calculateHeight(),
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _propertyRow(context, "E1", inPlanePropertiesModel.e1),
                const Divider(height: 1),
                _propertyRow(context, "E2", inPlanePropertiesModel.e2),
                const Divider(height: 1),
                _propertyRow(context, "G12", inPlanePropertiesModel.g12),
                const Divider(height: 1),
                _propertyRow(context, "ν12", inPlanePropertiesModel.nu12),
                const Divider(height: 1),
                _propertyRow(context, "η12,1", inPlanePropertiesModel.eta121),
                const Divider(height: 1),
                _propertyRow(context, "η12,2", inPlanePropertiesModel.eta122),
                if (inPlanePropertiesModel.alpha11 != null)
                  const Divider(height: 1),
                if (inPlanePropertiesModel.alpha11 != null)
                  _propertyRow(context, "ɑ11", inPlanePropertiesModel.alpha11),
                if (inPlanePropertiesModel.alpha22 != null)
                  const Divider(height: 1),
                if (inPlanePropertiesModel.alpha22 != null)
                  _propertyRow(context, "ɑ22", inPlanePropertiesModel.alpha22),
                if (inPlanePropertiesModel.alpha12 != null)
                  const Divider(height: 1),
                if (inPlanePropertiesModel.alpha12 != null)
                  _propertyRow(context, "ɑ12", inPlanePropertiesModel.alpha12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
