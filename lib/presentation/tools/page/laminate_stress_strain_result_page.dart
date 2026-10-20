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
        component: 'ε11',
        depthUnit: units.length,
      ),
      LaminarStressStrainLineChat(
        title: "ε22 through the thickness",
        data: epsilon22_datas,
        component: 'ε22',
        depthUnit: units.length,
      ),
      LaminarStressStrainLineChat(
        title: "ε12 through the thickness",
        data: epsilon12_datas,
        component: 'ε12',
        depthUnit: units.length,
      ),
      LaminarStressStrainLineChat(
        title: "σ11 ($stress) through the thickness",
        data: sigma11_datas,
        component: 'σ11',
        depthUnit: units.length,
        valueUnit: stress,
      ),
      LaminarStressStrainLineChat(
        title: "σ22 ($stress) through the thickness",
        data: sigma22_datas,
        component: 'σ22',
        depthUnit: units.length,
        valueUnit: stress,
      ),
      LaminarStressStrainLineChat(
        title: "σ12 ($stress) through the thickness",
        data: sigma12_datas,
        component: 'σ12',
        depthUnit: units.length,
        valueUnit: stress,
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

class LaminarStressStrainLineChat extends StatefulWidget {
  final String title;
  final List<FlSpot> data;
  final String component;
  final String depthUnit;
  final String valueUnit;

  const LaminarStressStrainLineChat(
      {Key? key,
      required this.title,
      required this.data,
      required this.component,
      required this.depthUnit,
      this.valueUnit = ''})
      : super(key: key);

  @override
  State<LaminarStressStrainLineChat> createState() =>
      _LaminarStressStrainLineChatState();
}

class _LaminarStressStrainLineChatState
    extends State<LaminarStressStrainLineChat> {
  final _rendererKey = GlobalKey();
  int? _selectedIndex;
  int _dataLength = 0;
  double _minimumX = 0;
  double _maximumX = 1;
  double _minimumY = 0;
  double _maximumY = 1;

  @override
  void initState() {
    super.initState();
    _updateBounds();
  }

  @override
  void didUpdateWidget(covariant LaminarStressStrainLineChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || widget.data.length != _dataLength) {
      _selectedIndex = null;
      _updateBounds();
    }
  }

  void _updateBounds() {
    final data = widget.data;
    _dataLength = data.length;
    if (data.isEmpty) return;
    _minimumX = data.first.x;
    _maximumX = data.last.x;
    _minimumY = data.map((point) => point.y).reduce(min);
    _maximumY = data.map((point) => point.y).reduce(max);
    if (_maximumX == _minimumX) _maximumX = _minimumX + 1;
    final range = _maximumY - _minimumY;
    if (range == 0 || (range / _minimumY).abs() < 0.001) {
      _maximumY = _minimumY + 1;
    }
  }

  void _selectIndex(int? index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _inspectAt(Offset globalPosition, double minimum, double maximum) {
    final box = _rendererKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.width <= 0) return;
    final local = box.globalToLocal(globalPosition);
    // Include the plot borders: the outermost ply surfaces lie exactly there.
    if (local.dx < 0 ||
        local.dx > box.size.width ||
        local.dy < 0 ||
        local.dy > box.size.height) {
      _selectIndex(null);
      return;
    }
    final depth = minimum + (maximum - minimum) * local.dx / box.size.width;
    final data = widget.data;
    // The samples are ordered from bottom to top. Binary search keeps hover
    // work bounded even for a large laminate; each depth has at most two sides.
    var lower = 0;
    var upper = data.length;
    while (lower < upper) {
      final middle = lower + (upper - lower) ~/ 2;
      if (data[middle].x < depth) {
        lower = middle + 1;
      } else {
        upper = middle;
      }
    }
    final next = lower.clamp(0, data.length - 1).toInt();
    final previous = (lower - 1).clamp(0, data.length - 1).toInt();
    _selectIndex(
        (data[previous].x - depth).abs() <= (data[next].x - depth).abs()
            ? previous
            : next);
  }

  List<int> _surfaceIndices(int selected) {
    final data = widget.data;
    if (selected > 0 && data[selected - 1].x == data[selected].x) {
      return [selected - 1, selected];
    }
    if (selected + 1 < data.length &&
        data[selected + 1].x == data[selected].x) {
      return [selected, selected + 1];
    }
    return [selected];
  }

  String _inspectionText(List<int> indices, S? strings, int precision) {
    String number(double value) =>
        CalcReport.formatNumber(value, precision: precision);
    final depth = number(widget.data[indices.first].x);
    return [
      strings?.Calculator_chart_depth(depth, widget.depthUnit) ??
          'Depth: $depth ${widget.depthUnit}',
      for (final index in indices) ...[
        () {
          final surface = index.isEven
              ? strings?.Calculator_surface_bottom ?? 'Bottom'
              : strings?.Calculator_surface_top ?? 'Top';
          final ply = index ~/ 2 + 1;
          return strings?.Calculator_chart_ply_surface(ply, surface) ??
              'Ply $ply · $surface';
        }(),
        '${widget.component}: ${number(widget.data[index].y)}'
            '${widget.valueUnit.isEmpty ? '' : ' ${widget.valueUnit}'}',
      ],
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return const SizedBox.shrink();
    final strings = S.maybeOf(context);
    // Optional lookup keeps this chart usable in isolated widget previews.
    final precision = (context.watch<NumberPrecisionHelper?>()?.precision ?? 5)
        .clamp(0, 20)
        .toInt();
    final scheme = Theme.of(context).colorScheme;
    const chartTitles = FlTitlesData();
    const tooltipPadding = EdgeInsets.all(8);
    const chartPadding = EdgeInsets.fromLTRB(5, 0, 25, 10);
    var tooltipStyle = DefaultTextStyle.of(context)
        .style
        .merge(
          TextStyle(color: scheme.onInverseSurface, fontSize: 12),
        )
        .copyWith(inherit: false);
    if (MediaQuery.boldTextOf(context)) {
      tooltipStyle = tooltipStyle.copyWith(fontWeight: FontWeight.bold);
    }
    final minX = _minimumX;
    final maxX = _maximumX;
    final minY = _minimumY;
    final maxY = _maximumY;

    double horizontalInterval = (maxX - minX) / 4;
    double verticalInterval = (maxY - minY) / 4;
    final selected = _selectedIndex;
    final selectedSurfaces =
        selected == null ? <int>[] : _surfaceIndices(selected);
    final inspection = selectedSurfaces.isEmpty
        ? null
        : _inspectionText(selectedSurfaces, strings, precision);
    final bar = LineChartBarData(
      isCurved: false,
      color: scheme.primary,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      showingIndicators: selectedSurfaces,
      spots: data,
    );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(children: [
        ListTile(
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            strings?.Calculator_chart_inspection_hint ??
                'Tap a point or hover to inspect ply values',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          // Measure using the same style, width and text scaler as fl_chart.
          // Browser font metrics can wrap to more lines than native metrics.
          final contentWidth = max(
              20.0,
              min(
                220.0,
                constraints.maxWidth -
                    chartPadding.horizontal -
                    chartTitles.leftTitles.sideTitles.reservedSize -
                    chartTitles.rightTitles.sideTitles.reservedSize -
                    tooltipPadding.horizontal -
                    8,
              ));
          final scaler = MediaQuery.textScalerOf(context);
          var height = 200.0 * max(1.0, scaler.scale(12) / 12);
          if (inspection != null) {
            final painter = TextPainter(
              text: TextSpan(text: inspection, style: tooltipStyle),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout(maxWidth: contentWidth);
            height = max(
                height,
                painter.height +
                    tooltipPadding.vertical +
                    chartTitles.topTitles.sideTitles.reservedSize +
                    chartTitles.bottomTitles.sideTitles.reservedSize +
                    chartPadding.vertical +
                    8);
            painter.dispose();
          }
          return Container(
            padding: chartPadding,
            height: height,
            child: Semantics(
              label: inspection,
              child: MouseRegion(
                onHover: (event) => _inspectAt(event.position, minX, maxX),
                onExit: (_) => _selectIndex(null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _inspectAt(details.globalPosition, minX, maxX),
                  onTapCancel: () => _selectIndex(null),
                  // A tap-only detector lets the surrounding result list retain
                  // vertical drags; fl_chart's own pan recognizer is bypassed.
                  child: IgnorePointer(
                      child: LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              enabled: false,
                              handleBuiltInTouches: false,
                              touchTooltipData: LineTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                maxContentWidth: contentWidth,
                                tooltipPadding: tooltipPadding,
                                getTooltipColor: (_) => scheme.inverseSurface,
                                getTooltipItems: (spots) => [
                                  for (var i = 0; i < spots.length; i++)
                                    inspection == null
                                        ? null
                                        : LineTooltipItem(
                                            inspection,
                                            tooltipStyle,
                                            textAlign: TextAlign.left,
                                            textDirection:
                                                Directionality.of(context),
                                          ),
                                ],
                              ),
                            ),
                            showingTooltipIndicators: selected == null
                                ? []
                                : [
                                    ShowingTooltipIndicators(
                                        [LineBarSpot(bar, 0, data[selected])]),
                                  ],
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: verticalInterval > 0
                                  ? verticalInterval
                                  : null,
                              verticalInterval: horizontalInterval > 0
                                  ? horizontalInterval
                                  : null,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                            ),
                            titlesData: chartTitles,
                            borderData: FlBorderData(
                                show: true,
                                border: const Border(
                                    left: BorderSide(color: Colors.grey),
                                    bottom: BorderSide(color: Colors.grey))),
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [bar],
                          ),
                          chartRendererKey: _rendererKey,
                          duration: Duration.zero)),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }
}
