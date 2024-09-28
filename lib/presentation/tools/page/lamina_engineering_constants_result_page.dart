import 'dart:math';

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
import 'package:vector_math/vector_math.dart' as VMath;

import '../../tools/model/thermal_model.dart';

class LaminaEngineeringConstantsResultPage extends StatefulWidget {
  final TransverselyIsotropicMaterial transverselyIsotropicMaterial;
  final bool isElastic;
  TransverselyIsotropicCTE transverselyIsotropicCTE = TransverselyIsotropicCTE();

  LaminaEngineeringConstantsResultPage(
      {Key? key, required this.transverselyIsotropicMaterial,
      required this.isElastic})
      : super(key: key);

  @override
  _LaminaEngineeringConstantsResultPageState createState() =>
      _LaminaEngineeringConstantsResultPageState();
}

class _LaminaEngineeringConstantsResultPageState
    extends State<LaminaEngineeringConstantsResultPage> {
  late VMath.Matrix3 Q_bar;
  late VMath.Matrix3 S_bar;
  double layupAngle = 0.0;

  double E_x = 0.0;
  double nu_xy = 0.0;
  double E_y = 0.0;
  double G_xy = 0.0;
  double eta_x_xy = 0.0;
  double eta_y_xy = 0.0;
  
  double alpha_xx = 0;
  double alpha_yy = 0;
  double alpha_xy = 0;


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
    double e1 = widget.transverselyIsotropicMaterial.e1!;
    double e2 = widget.transverselyIsotropicMaterial.e2!;
    double g12 = widget.transverselyIsotropicMaterial.g12!;
    double nu12 = widget.transverselyIsotropicMaterial.nu12!;
    double angleRadian = VMath.radians(layupAngle);
    var S = VMath.Matrix3.fromList([1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
    var Q = VMath.Matrix3.fromList([1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
    Q.invert();
    double s = sin(angleRadian);
    double c = cos(angleRadian);
    var T_epsilon = VMath.Matrix3.fromList(
        [c * c, s * s, s * c, s * s, c * c, -s * c, -2 * s * c, 2 * s * c, c * c - s * s]);
    var T_sigma = VMath.Matrix3.fromList(
        [c * c, s * s, 2 * s * c, s * s, c * c, -2 * s * c, -s * c, s * c, c * c - s * s]);
    Q_bar = T_epsilon.transposed() * Q * T_epsilon;
    S_bar = T_sigma.transposed() * S * T_sigma;
    E_x = 1 / S_bar[0];
    E_y = 1 / S_bar[4];
    G_xy = 1 / S_bar[8];
    nu_xy = -S_bar[1] * E_x;
    eta_x_xy = S_bar[6] * E_x;
    eta_y_xy = S_bar[7] * E_y;

    if (!widget.isElastic) {
      var R_epsilon_e = VMath.Matrix3.fromList(
          [c * c, s * s, -s * c, s * s, c * c, s * c, 2 * s * c, -2 * s * c, c * c - s * s]);
      double alpha11 = widget.transverselyIsotropicCTE.alpha11!;
      double alpha22 = widget.transverselyIsotropicCTE.alpha22!;
      double alpha12 = widget.transverselyIsotropicCTE.alpha12!;
      var cteVector = VMath.Vector3.array([alpha11, alpha22, 2 * alpha12]);
      var alpha_p = R_epsilon_e * cteVector;
      alpha_xx = alpha_p[0];
      alpha_yy = alpha_p[1];
      alpha_xy = alpha_p[2] / 2;
    }
  }

  initChartData() {
    double e1 = widget.transverselyIsotropicMaterial.e1!;
    double e2 = widget.transverselyIsotropicMaterial.e2!;
    double g12 = widget.transverselyIsotropicMaterial.g12!;
    double nu12 = widget.transverselyIsotropicMaterial.nu12!;
    var S = VMath.Matrix3.fromList([1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
    var Q = VMath.Matrix3.fromList([1 / e1, -nu12 / e1, 0, -nu12 / e1, 1 / e2, 0, 0, 0, 1 / g12]);
    Q.invert();

    for (var i = -90; i <= 90; i++) {
      print(i);
      double angle = i.toDouble();
      double angleRadian = VMath.radians(angle);
      double s = sin(angleRadian);
      double c = cos(angleRadian);
      var T_epsilon = VMath.Matrix3.fromList(
          [c * c, s * s, s * c, s * s, c * c, -s * c, -2 * s * c, 2 * s * c, c * c - s * s]);
      var T_sigma = VMath.Matrix3.fromList(
          [c * c, s * s, 2 * s * c, s * s, c * c, -2 * s * c, -s * c, s * c, c * c - s * s]);
      VMath.Matrix3 S_bar_temp = T_sigma.transposed() * S * T_sigma;

      double E_x_temp = 1 / S_bar_temp[0];
      double E_y_temp = 1 / S_bar_temp[4];
      double G_xy_temp = 1 / S_bar_temp[8];
      double nu_xy_temp = -S_bar_temp[1] * E_x_temp;
      double eta_x_xy_temp = S_bar_temp[6] * E_x_temp;
      double eta_y_xy_temp = S_bar_temp[7] * E_y_temp;

      E_x_datas.add(FlSpot(angle, E_x_temp));
      E_y_datas.add(FlSpot(angle, E_y_temp));
      G_xy_datas.add(FlSpot(angle, G_xy_temp));
      nu_xy_datas.add(FlSpot(angle, nu_xy_temp));
      eta_x_xy_datas.add(FlSpot(angle, eta_x_xy_temp));
      eta_y_xy_datas.add(FlSpot(angle, eta_y_xy_temp));

      if (!widget.isElastic) {
        var R_epsilon_e = VMath.Matrix3.fromList(
            [c * c, s * s, -s * c, s * s, c * c, s * c, 2 * s * c, -2 * s * c, c * c - s * s]);
        double alpha11 = widget.transverselyIsotropicCTE.alpha11!;
        double alpha22 = widget.transverselyIsotropicCTE.alpha22!;
        double alpha12 = widget.transverselyIsotropicCTE.alpha12!;
        var cteVector = VMath.Vector3.array([alpha11, alpha22, 2 * alpha12]);
        var alpha_p = R_epsilon_e * cteVector;
        double alpha_xx_temp = alpha_p[0];
        double alpha_yy_temp = alpha_p[1];
        double alpha_xy_temp = alpha_p[2] / 2;
        alpha_xx_datas.add(FlSpot(angle, alpha_xx_temp));
        alpha_yy_datas.add(FlSpot(angle, alpha_yy_temp));
        alpha_xy_datas.add(FlSpot(angle, alpha_xy_temp));
      }
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
                    context, MaterialPageRoute(builder: (context) => const ToolSettingPage()));
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).Results),
        ),
        body: SafeArea(
            child: StaggeredGridView.countBuilder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                crossAxisCount: 8,
                itemCount: 4,
                staggeredTileBuilder: (int index) =>
                    StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (BuildContext context, int index) {
                  List<Widget> children = [
                  _engineeringConstantsRow("Ex", E_x, E_x_datas),
                  const Divider(),
                  _engineeringConstantsRow("Ey", E_y, E_y_datas),
                  const Divider(),
                  _engineeringConstantsRow("Gxy", G_xy, G_xy_datas),
                  const Divider(),
                  _engineeringConstantsRow("νxy", nu_xy, nu_xy_datas),
                  const Divider(),
                  _engineeringConstantsRow("ηx,xy", eta_x_xy, eta_x_xy_datas),
                  const Divider(),
                  _engineeringConstantsRow("ηy,xy", eta_y_xy, eta_y_xy_datas)
                  ];
                  if (!widget.isElastic) {
                    List<Widget> moreChildren = [
                    const Divider(),
                    _engineeringConstantsRow("ɑxx", alpha_xx, alpha_xx_datas),
                    const Divider(),
                    _engineeringConstantsRow("ɑyy", alpha_yy, alpha_yy_datas),
                    const Divider(),
                    _engineeringConstantsRow("ɑxy", alpha_xy, alpha_xy_datas)
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
                        child: Column(
                          children: children
                        ),
                      ),
                    ),
                    ResultPlaneStiffnessMatrix(
                      Q_bar: Q_bar,
                    ),
                    ResultPlaneComplianceMatrix(
                      S_bar: S_bar,
                    )
                  ][index];
                })));
  }

  _engineeringConstantsRow(String constant, double value, List<FlSpot> chartDatas) {
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
                  x: layupAngle, color: Theme.of(context).colorScheme.primary, strokeWidth: 1)
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
              S.of(context).Layup_Angle + ": ${doubleToString(layupAngle, keepDecimal: 0)}",
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
