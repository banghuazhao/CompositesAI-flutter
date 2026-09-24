import 'package:composite_calculator/composite_calculator.dart';
import 'package:composite_calculator/models/in-plane-properties.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/widget/legacy_staggered_grid.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/widget/result_3by3_matrix.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

import '../model/calc_report.dart';
import '../model/unit_system.dart';
import '../widget/report_export_button.dart';

class LaminatePlatePropertiesResultPage extends StatefulWidget {
  final LaminatePlatePropertiesOutput output;
  final List<ReportSection> inputs;

  const LaminatePlatePropertiesResultPage(
      {Key? key, required this.output, this.inputs = const []})
      : super(key: key);

  @override
  _LaminatePlatePropertiesResultPageState createState() =>
      _LaminatePlatePropertiesResultPageState();
}

class _LaminatePlatePropertiesResultPageState
    extends State<LaminatePlatePropertiesResultPage> {
  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            ReportExportButton(buildReport: _buildReport),
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ResultPrecisionPage()));
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

  CalcReport _buildReport() {
    final units = context.read<UnitSettings>().units;
    ValuesSection properties(String title, InPlaneProperties p) {
      return ValuesSection(title, [
        ReportEntry('E1', p.E1, units.modulus),
        ReportEntry('E2', p.E2, units.modulus),
        ReportEntry('G12', p.G12, units.modulus),
        ReportEntry('ν12', p.nu12),
        ReportEntry('η12,1', p.eta121),
        ReportEntry('η12,2', p.eta122),
        if (p.analysisType == AnalysisType.thermalElastic) ...[
          ReportEntry('ɑ11', p.alpha11, units.cte),
          ReportEntry('ɑ22', p.alpha22, units.cte),
          ReportEntry('ɑ12', p.alpha12, units.cte),
        ],
      ]);
    }

    return CalcReport(
      title: S.of(context).Laminate_plate_properties,
      units: units,
      inputs: widget.inputs,
      results: [
        MatrixSection('A Matrix', widget.output.A, unit: units.aMatrix),
        MatrixSection('B Matrix', widget.output.B, unit: units.bMatrix),
        MatrixSection('D Matrix', widget.output.D, unit: units.dMatrix),
        properties('In-plane properties', widget.output.inPlaneProperties),
        properties('Flexural properties', widget.output.flexuralProperties),
      ],
      notes: const [
        'In-plane and flexural properties are valid for symmetric laminates only.',
      ],
    );
  }

  List<Widget> get resultList {
    final units = context.watch<UnitSettings>().units;
    return [
      Result3By3Matrix(
        title: "A Matrix",
        matrixList: widget.output.A,
        unit: units.aMatrix,
      ),
      Result3By3Matrix(
        title: "B Matrix",
        matrixList: widget.output.B,
        unit: units.bMatrix,
      ),
      Result3By3Matrix(
        title: "D Matrix",
        matrixList: widget.output.D,
        unit: units.dMatrix,
      ),
      InPlanePropertiesWidget(
        title: "In-Plane Properties",
        explain:
            "In-Plane properties are only valid for symmetric laminates only.",
        inPlaneProperties: widget.output.inPlaneProperties,
      ),
      InPlanePropertiesWidget(
        title: "Flexural Properties",
        explain:
            "Flexural properties are only valid for symmetric laminates only.",
        inPlaneProperties: widget.output.flexuralProperties,
      )
    ];
  }
}

class InPlanePropertiesWidget extends StatelessWidget {
  final String title;
  final String? explain;
  final InPlaneProperties inPlaneProperties;

  const InPlanePropertiesWidget(
      {Key? key,
      required this.title,
      required this.explain,
      required this.inPlaneProperties})
      : super(key: key);

  _propertyRow(BuildContext context, String title, double? value) {
    return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
      return SizedBox(
        height: 40,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
      valueString =
          value == 0 ? "0" : value.toStringAsExponential(precision).toString();
    }
    return valueString;
  }

  double calculateHeight() {
    if (inPlaneProperties.analysisType == AnalysisType.thermalElastic) {
      return 40 * 9 + 20;
    } else {
      return 40 * 6 + 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    String modulus(String label) => withUnit(label, units.modulus);
    String cte(String label) => withUnit(label, units.cte);
    List<Widget> list = [
      _propertyRow(context, modulus("E1"), inPlaneProperties.E1),
      const Divider(height: 1),
      _propertyRow(context, modulus("E2"), inPlaneProperties.E2),
      const Divider(height: 1),
      _propertyRow(context, modulus("G12"), inPlaneProperties.G12),
      const Divider(height: 1),
      _propertyRow(context, "ν12", inPlaneProperties.nu12),
      const Divider(height: 1),
      _propertyRow(context, "η12,1", inPlaneProperties.eta121),
      const Divider(height: 1),
      _propertyRow(context, "η12,2", inPlaneProperties.eta122),
    ];

    if (inPlaneProperties.analysisType == AnalysisType.thermalElastic) {
      list.addAll([
        const Divider(height: 1),
        _propertyRow(context, cte("ɑ11"), inPlaneProperties.alpha11),
        const Divider(height: 1),
        _propertyRow(context, cte("ɑ22"), inPlaneProperties.alpha22),
        const Divider(height: 1),
        _propertyRow(context, cte("ɑ12"), inPlaneProperties.alpha12),
      ]);
    }

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
                            borderRadius: BorderRadius.circular(12.0)),
                        //this right here
                        child: Container(
                            padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                            child: Text(explain!)),
                      );
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => dialog);
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
              children: list,
            ),
          ),
        ],
      ),
    );
  }
}
