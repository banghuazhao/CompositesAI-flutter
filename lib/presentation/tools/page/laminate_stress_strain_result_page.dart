import 'dart:math';

import 'package:composite_calculator/composite_calculator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/widget/legacy_staggered_grid.dart';
import 'package:linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

import '../model/calc_report.dart';
import '../model/unit_system.dart';
import '../widget/report_export_button.dart';

class LaminateStressStrainResultPage extends StatefulWidget {
  final MechanicalTensor inputTensor;
  final LaminarStressStrainOutput output;
  final double thickness;
  final List<Matrix> Q;
  final List<ReportSection> inputs;

  const LaminateStressStrainResultPage(
      {Key? key,
      required this.inputTensor,
      required this.output,
      required this.thickness,
      required this.Q,
      this.inputs = const []})
      : super(key: key);

  @override
  _LaminateStressStrainResultPageState createState() =>
      _LaminateStressStrainResultPageState();
}

class _LaminateStressStrainResultPageState
    extends State<LaminateStressStrainResultPage> {
  List<FlSpot> epsilon11_datas = [];
  List<FlSpot> epsilon22_datas = [];
  List<FlSpot> epsilon12_datas = [];
  List<FlSpot> sigma11_datas = [];
  List<FlSpot> sigma22_datas = [];
  List<FlSpot> sigma12_datas = [];

  initChartData() {
    Matrix epsilon = Matrix.fill(3, 1);
    Matrix kappa = Matrix.fill(3, 1);
    if (widget.inputTensor is LaminateStrain) {
      epsilon[0][0] = (widget.inputTensor as LaminateStrain).epsilon11!;
      epsilon[1][0] = (widget.inputTensor as LaminateStrain).epsilon22!;
      epsilon[2][0] = (widget.inputTensor as LaminateStrain).epsilon12!;
      kappa[0][0] = (widget.inputTensor as LaminateStrain).kappa11!;
      kappa[1][0] = (widget.inputTensor as LaminateStrain).kappa22!;
      kappa[2][0] = (widget.inputTensor as LaminateStrain).kappa12!;
    } else {
      epsilon[0][0] = widget.output.epsilon11;
      epsilon[1][0] = widget.output.epsilon22;
      epsilon[2][0] = widget.output.epsilon12;
      kappa[0][0] = widget.output.kappa11;
      kappa[1][0] = widget.output.kappa22;
      kappa[2][0] = widget.output.kappa12;
    }

    double totalThickness = widget.Q.length * widget.thickness;
    for (var i = 0; i < widget.Q.length; i++) {
      double x3Start = widget.thickness * i - totalThickness / 2;
      double x3End = widget.thickness * (i + 1) - totalThickness / 2;

      Matrix epsilon_e_Start = epsilon + kappa * x3Start;
      Matrix epsilon_e_End = epsilon + kappa * x3End;

      Matrix sigma_e_Start = widget.Q[i] * epsilon_e_Start;
      Matrix sigma_e_End = widget.Q[i] * epsilon_e_End;

      epsilon11_datas.add(FlSpot(x3Start, epsilon_e_Start[0][0]));
      epsilon11_datas.add(FlSpot(x3End, epsilon_e_End[0][0]));

      epsilon22_datas.add(FlSpot(x3Start, epsilon_e_Start[1][0]));
      epsilon22_datas.add(FlSpot(x3End, epsilon_e_End[1][0]));

      epsilon12_datas.add(FlSpot(x3Start, epsilon_e_Start[2][0]));
      epsilon12_datas.add(FlSpot(x3End, epsilon_e_End[2][0]));
      sigma11_datas.add(FlSpot(x3Start, sigma_e_Start[0][0]));
      sigma11_datas.add(FlSpot(x3End, sigma_e_End[0][0]));

      sigma22_datas.add(FlSpot(x3Start, sigma_e_Start[1][0]));
      sigma22_datas.add(FlSpot(x3End, sigma_e_End[1][0]));

      sigma12_datas.add(FlSpot(x3Start, sigma_e_Start[2][0]));
      sigma12_datas.add(FlSpot(x3End, sigma_e_End[2][0]));
    }
  }

  @override
  void initState() {
    super.initState();
    initChartData();
    setState(() {});
  }

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
              itemCount: resultItems.length,
              staggeredTileBuilder: (int index) => StaggeredTile.fit(
                  MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return resultItems[index];
              }),
        ));
  }

  CalcReport _buildReport() {
    final units = context.read<UnitSettings>().units;
    final tensor = resultTensor;
    List<(double, double)> points(List<FlSpot> spots) =>
        [for (final spot in spots) (spot.x, spot.y)];
    final plyRows = <List<Object?>>[
      for (var i = 0; i < sigma11_datas.length; i++)
        [
          i ~/ 2 + 1,
          i.isEven ? 'Bottom' : 'Top',
          sigma11_datas[i].x,
          epsilon11_datas[i].y,
          epsilon22_datas[i].y,
          epsilon12_datas[i].y,
          sigma11_datas[i].y,
          sigma22_datas[i].y,
          sigma12_datas[i].y,
        ],
    ];
    return CalcReport(
      title: S.of(context).Laminar_stressstrain,
      units: units,
      inputs: widget.inputs,
      results: [
        tensor is LaminateStress
            ? ValuesSection('Stress resultants', [
                ReportEntry('N11', tensor.N11, units.forceResultant),
                ReportEntry('N22', tensor.N22, units.forceResultant),
                ReportEntry('N12', tensor.N12, units.forceResultant),
                ReportEntry('M11', tensor.M11, units.momentResultant),
                ReportEntry('M22', tensor.M22, units.momentResultant),
                ReportEntry('M12', tensor.M12, units.momentResultant),
              ])
            : ValuesSection('Midplane strains and curvatures', [
                ReportEntry('ε11', (tensor as LaminateStrain).epsilon11),
                ReportEntry('ε22', tensor.epsilon22),
                ReportEntry('ε12', tensor.epsilon12),
                ReportEntry('κ11', tensor.kappa11, units.curvature),
                ReportEntry('κ22', tensor.kappa22, units.curvature),
                ReportEntry('κ12', tensor.kappa12, units.curvature),
              ]),
        TableSection(
          'Ply strains and stresses (laminate axes)',
          headers: [
            'Ply',
            'Surface',
            'z (${units.length})',
            'ε11',
            'ε22',
            'ε12',
            'σ11 (${units.stress})',
            'σ22 (${units.stress})',
            'σ12 (${units.stress})',
          ],
          rows: plyRows,
        ),
        ChartSection(
          'Strains through the thickness',
          xLabel: 'z (${units.length})',
          yLabel: 'Strain',
          series: [
            ChartSeries('ε11', points(epsilon11_datas)),
            ChartSeries('ε22', points(epsilon22_datas)),
            ChartSeries('ε12', points(epsilon12_datas)),
          ],
        ),
        ChartSection(
          'Stresses through the thickness',
          xLabel: 'z (${units.length})',
          yLabel: 'Stress (${units.stress})',
          series: [
            ChartSeries('σ11', points(sigma11_datas)),
            ChartSeries('σ22', points(sigma22_datas)),
            ChartSeries('σ12', points(sigma12_datas)),
          ],
        ),
      ],
    );
  }

  List<Widget> get resultItems {
    final units = context.watch<UnitSettings>().units;
    final stress = units.stress;
    return [
      ResultStressStrainWidget(
        mechanicalTensor: resultTensor,
        units: units,
      ),
      LaminarStressStrainLineChat(
        title: "ε11 through the thickness",
        data: epsilon11_datas,
      ),
      LaminarStressStrainLineChat(
        title: "ε22 through the thickness",
        data: epsilon22_datas,
      ),
      LaminarStressStrainLineChat(
        title: "ε12 through the thickness",
        data: epsilon12_datas,
      ),
      LaminarStressStrainLineChat(
        title: "σ11 ($stress) through the thickness",
        data: sigma11_datas,
      ),
      LaminarStressStrainLineChat(
        title: "σ22 ($stress) through the thickness",
        data: sigma22_datas,
      ),
      LaminarStressStrainLineChat(
        title: "σ12 ($stress) through the thickness",
        data: sigma12_datas,
      )
    ];
  }

  MechanicalTensor get resultTensor {
    if (widget.output.tensorType == TensorType.stress) {
      return LaminateStress(
        N11: widget.output.N11,
        N22: widget.output.N22,
        N12: widget.output.N12,
        M11: widget.output.M11,
        M22: widget.output.M22,
        M12: widget.output.M12,
      );
    } else {
      return LaminateStrain(
        epsilon11: widget.output.epsilon11,
        epsilon22: widget.output.epsilon22,
        epsilon12: widget.output.epsilon12,
        kappa11: widget.output.kappa11,
        kappa22: widget.output.kappa22,
        kappa12: widget.output.kappa12,
      );
    }
  }
}

class ResultStressStrainWidget extends StatelessWidget {
  final MechanicalTensor mechanicalTensor;
  final Units units;

  const ResultStressStrainWidget(
      {Key? key, required this.mechanicalTensor, this.units = Units.si})
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

  @override
  Widget build(BuildContext context) {
    bool isStress = (mechanicalTensor is LaminateStress);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              "Result",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: 240 + 20,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _propertyRow(
                    context,
                    isStress ? withUnit("N11", units.forceResultant) : "ϵ11",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N11
                        : (mechanicalTensor as LaminateStrain).epsilon11),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? withUnit("N22", units.forceResultant) : "ϵ22",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N22
                        : (mechanicalTensor as LaminateStrain).epsilon22),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? withUnit("N12", units.forceResultant) : "ϵ12",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N12
                        : (mechanicalTensor as LaminateStrain).epsilon12),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress
                        ? withUnit("M11", units.momentResultant)
                        : withUnit("𝞳11", units.curvature),
                    isStress
                        ? (mechanicalTensor as LaminateStress).M11
                        : (mechanicalTensor as LaminateStrain).kappa11),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress
                        ? withUnit("M22", units.momentResultant)
                        : withUnit("𝞳22", units.curvature),
                    isStress
                        ? (mechanicalTensor as LaminateStress).M22
                        : (mechanicalTensor as LaminateStrain).kappa22),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress
                        ? withUnit("M12", units.momentResultant)
                        : withUnit("𝞳12", units.curvature),
                    isStress
                        ? (mechanicalTensor as LaminateStress).M12
                        : (mechanicalTensor as LaminateStrain).kappa12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaminarStressStrainLineChat extends StatelessWidget {
  final String title;
  final List<FlSpot> data;

  const LaminarStressStrainLineChat(
      {Key? key, required this.title, required this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double minX = data[0].x;
    double maxX = data.last.x;
    double minY = (data.map((e) => e.y)).reduce(min);
    double maxY = (data.map((e) => e.y)).reduce(max);
    if (maxX == minX) {
      maxX = minX + 1;
    }
    double deltaY = maxY - minY;
    if (deltaY == 0 || ((deltaY / minY).abs() < 0.001)) {
      maxY = minY + 1;
    }

    double horizontalInterval = (maxX - minX) / 4;
    double verticalInterval = (maxY - minY) / 4;
    print("minX, maxX, minY, maxY: $minX, $maxX, $minY, $maxY");
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(children: [
        ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(5, 0, 25, 10),
          height: 200,
          child: LineChart(LineChartData(
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              horizontalInterval:
                  verticalInterval > 0 ? verticalInterval : null,
              verticalInterval:
                  horizontalInterval > 0 ? horizontalInterval : null,
              drawHorizontalLine: true,
              drawVerticalLine: true,
            ),
            titlesData: FlTitlesData(
              show: true,
              // rightTitles: SideTitles(showTitles: false),
              // topTitles: SideTitles(showTitles: false),
              // leftTitles: SideTitles(
              //     showTitles: true,
              //     reservedSize: 50,
              //     interval: verticalInterval > 0 ? verticalInterval : null,
              //     getTextStyles: (context, value) => const TextStyle(
              //           fontSize: 10,
              //         ),
              //     getTitles: (value) {
              //       return value.toStringAsExponential(2);
              //     }),
              // bottomTitles: SideTitles(
              //     showTitles: true,
              //     interval: horizontalInterval > 0 ? horizontalInterval : null,
              //     getTextStyles: (context, value) => const TextStyle(
              //           fontSize: 10,
              //         ),
              //     getTitles: (value) {
              //       return value.toStringAsExponential(2);
              //     }),
            ),
            borderData: FlBorderData(
                show: true,
                border: const Border(
                    left: BorderSide(color: Colors.grey),
                    bottom: BorderSide(color: Colors.grey))),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                isCurved: false,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                spots: data,
              ),
            ],
          )),
        )
      ]),
    );
  }
}
