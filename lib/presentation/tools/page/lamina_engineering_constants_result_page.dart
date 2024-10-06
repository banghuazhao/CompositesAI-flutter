import 'package:composite_calculator/models/lamina_engineering_constants_input.dart';
import 'package:composite_calculator/models/lamina_engineering_constants_output.dart';
import 'package:composite_calculator/calculators/lamina_engineering_constants_calculator.dart';
import 'package:composite_calculator/models/analysis_type.dart' as CC;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/widget/result_plane_compliance_matrix.dart';
import 'package:swiftcomp/presentation/tools/widget/result_plane_stiffness_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/number.dart';

import '../../tools/model/thermal_model.dart';

class LaminaEngineeringConstantsResultPage extends StatefulWidget {
  final TransverselyIsotropicMaterial transverselyIsotropicMaterial;
  final bool isElastic;
  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();

  LaminaEngineeringConstantsResultPage(
      {Key? key,
      required this.transverselyIsotropicMaterial,
      required this.isElastic})
      : super(key: key);

  @override
  _LaminaEngineeringConstantsResultPageState createState() =>
      _LaminaEngineeringConstantsResultPageState();
}

class _LaminaEngineeringConstantsResultPageState
    extends State<LaminaEngineeringConstantsResultPage> {

  double layupAngle = 0.0;

  LaminaEngineeringConstantsOutput output = LaminaEngineeringConstantsOutput();

  List<FlSpot> E_x_datas = [];
  List<FlSpot> nu_xy_datas = [];
  List<FlSpot> E_y_datas = [];
  List<FlSpot> G_xy_datas = [];
  List<FlSpot> eta_x_xy_datas = [];
  List<FlSpot> eta_y_xy_datas = [];

  List<FlSpot> alpha_xx_datas = [];
  List<FlSpot> alpha_yy_datas = [];
  List<FlSpot> alpha_xy_datas = [];

  calculateNewAngle() {
    output = calculateResult(layupAngle);
  }

  initChartData() {
    for (var i = -90; i <= 90; i++) {
      double angle = i.toDouble();

      LaminaEngineeringConstantsOutput output = calculateResult(angle);

      E_x_datas.add(FlSpot(angle, output.E1));
      E_y_datas.add(FlSpot(angle, output.E2));
      G_xy_datas.add(FlSpot(angle, output.G12));
      nu_xy_datas.add(FlSpot(angle, output.nu12));
      eta_x_xy_datas.add(FlSpot(angle, output.eta1_12));
      eta_y_xy_datas.add(FlSpot(angle, output.eta2_12));

      if (!widget.isElastic) {
        alpha_xx_datas.add(FlSpot(angle, output.alpha_11));
        alpha_yy_datas.add(FlSpot(angle, output.alpha_22));
        alpha_xy_datas.add(FlSpot(angle, output.alpha_12));
      }
    }
  }

  LaminaEngineeringConstantsOutput calculateResult(double layupAngle) {
    double e1 = widget.transverselyIsotropicMaterial.e1!;
    double e2 = widget.transverselyIsotropicMaterial.e2!;
    double g12 = widget.transverselyIsotropicMaterial.g12!;
    double nu12 = widget.transverselyIsotropicMaterial.nu12!;

    if (widget.isElastic) {
      LaminaEngineeringConstantsInput input = LaminaEngineeringConstantsInput(
          analysisType: CC.AnalysisType.elastic,
          E1: e1,
          E2: e2,
          G12: g12,
          nu12: nu12,
          layupAngle: layupAngle);
      return LaminaEngineeringConstantsCalculator.calculate(input);
    } else {
      LaminaEngineeringConstantsInput input = LaminaEngineeringConstantsInput(
        analysisType: CC.AnalysisType.elastic,
        E1: e1,
        E2: e2,
        G12: g12,
        nu12: nu12,
        layupAngle: layupAngle,
        alpha11: widget.transverselyIsotropicCTE.alpha11!,
        alpha22: widget.transverselyIsotropicCTE.alpha22!,
        alpha12: widget.transverselyIsotropicCTE.alpha12!,
      );
      return LaminaEngineeringConstantsCalculator.calculate(input);
    }
  }

  @override
  void initState() {
    calculateNewAngle();
    initChartData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
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
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).Results),
        ),
        body: SafeArea(
            child: StaggeredGridView.countBuilder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                crossAxisCount: 8,
                itemCount: 4,
                staggeredTileBuilder: (int index) => StaggeredTile.fit(
                    MediaQuery.of(context).size.width > 600 ? 4 : 8),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (BuildContext context, int index) {
                  List<Widget> children = [
                    _engineeringConstantsRow("Ex", output.E1, E_x_datas),
                    const Divider(),
                    _engineeringConstantsRow("Ey", output.E2, E_y_datas),
                    const Divider(),
                    _engineeringConstantsRow("Gxy", output.G12, G_xy_datas),
                    const Divider(),
                    _engineeringConstantsRow("νxy", output.nu12, nu_xy_datas),
                    const Divider(),
                    _engineeringConstantsRow(
                        "ηx,xy", output.eta1_12, eta_x_xy_datas),
                    const Divider(),
                    _engineeringConstantsRow(
                        "ηy,xy", output.eta2_12, eta_y_xy_datas)
                  ];
                  if (!widget.isElastic) {
                    List<Widget> moreChildren = [
                      const Divider(),
                      _engineeringConstantsRow(
                          "ɑxx", output.alpha_11, alpha_xx_datas),
                      const Divider(),
                      _engineeringConstantsRow(
                          "ɑyy", output.alpha_22, alpha_yy_datas),
                      const Divider(),
                      _engineeringConstantsRow(
                          "ɑxy", output.alpha_12, alpha_xy_datas)
                    ];
                    children.addAll(moreChildren);
                  }
                  return [
                    layupAngleSlider(),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(children: children),
                      ),
                    ),
                    ResultPlaneStiffnessMatrix(
                      Q_bar: output.Q,
                    ),
                    ResultPlaneComplianceMatrix(
                      S_bar: output.S,
                    )
                  ][index];
                })));
  }

  _engineeringConstantsRow(
      String constant, double value, List<FlSpot> chartDatas) {
    double width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Text(
              constant,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(
              height: 8,
            ),
            SizedBox(
                width: width - 180 - 90,
                child: Center(
                  child: _getValue(value),
                ))
          ],
        ),
        Container(
          width: 180,
          height: 80,
          child: LineChart(LineChartData(
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(
                  x: layupAngle,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 1)
            ]),
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
                show: false,
                rightTitles: SideTitles(showTitles: false),
                topTitles: SideTitles(showTitles: false),
                bottomTitles: SideTitles(showTitles: false)),
            // borderData: borderData,
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                colors: [Theme.of(context).colorScheme.primary],
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                spots: chartDatas,
              ),
            ],
          )),
        )
      ],
    );
  }

  _getValue(double value) {
    return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
      return Text(value.toStringAsExponential(precs.precision),
          style: Theme.of(context).textTheme.bodySmall);
    });
  }

  layupAngleSlider() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              S.of(context).Layup_Angle +
                  ": ${doubleToString(layupAngle, keepDecimal: 0)}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Slider(
            value: layupAngle,
            min: -90,
            max: 90,
            divisions: 180,
            onChanged: (double value) {
              layupAngle = value;
              calculateNewAngle();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
