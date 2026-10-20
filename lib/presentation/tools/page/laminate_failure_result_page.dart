import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

import '../model/calc_report.dart';
import '../model/failure_criteria.dart';
import '../model/unit_system.dart';
import '../widget/report_export_button.dart';
import 'laminate_failure_page.dart';

class LaminateFailureResultPage extends StatelessWidget {
  const LaminateFailureResultPage({
    super.key,
    required this.result,
    this.inputs = const [],
  });

  final LaminateFailureResult result;
  final List<ReportSection> inputs;

  static const List<String> _notes = [
    'Strength ratio R: factor on the applied loads that causes failure; '
        'R < 1 means the ply has already failed. Failure index = 1/R.',
    'Stresses are evaluated at the top and bottom surface of each ply, in '
        'material axes (1 = fiber direction). Plies are numbered from the '
        'bottom (most negative z).',
    'Mechanical loads only; thermal residual stresses are not included.',
    'Tsai-Wu uses F12 = -½√(F11·F22). Hashin takes the transverse shear '
        'strength as Yc/2.',
  ];

  CalcReport _buildReport(BuildContext context) {
    final units = context.read<UnitSettings>().units;
    return CalcReport(
      title: laminateFailureTitle,
      units: units,
      inputs: inputs,
      results: [
        TableSection(
          'First-ply failure',
          headers: const [
            'Criterion',
            'Strength ratio R',
            'Critical ply',
            'Angle (°)',
            'Surface',
            'Mode',
          ],
          rows: [
            for (final criterion in FailureCriterion.values)
              () {
                final point = result.critical(criterion);
                final outcome = point.results[criterion]!;
                return <Object?>[
                  criterion.label,
                  outcome.strengthRatio,
                  point.ply,
                  point.angle,
                  point.position,
                  outcome.mode,
                ];
              }(),
          ],
        ),
        ValuesSection('Midplane strains and curvatures', [
          ReportEntry('ε0x', result.midplaneStrains[0]),
          ReportEntry('ε0y', result.midplaneStrains[1]),
          ReportEntry('γ0xy', result.midplaneStrains[2]),
          ReportEntry('κx', result.curvatures[0], units.curvature),
          ReportEntry('κy', result.curvatures[1], units.curvature),
          ReportEntry('κxy', result.curvatures[2], units.curvature),
        ]),
        TableSection(
          'Ply stresses (material axes) and failure indices',
          headers: [
            'Ply',
            'Angle (°)',
            'Surface',
            'z (${units.length})',
            'σ1 (${units.stress})',
            'σ2 (${units.stress})',
            'τ12 (${units.stress})',
            for (final criterion in FailureCriterion.values)
              'FI ${criterion.shortLabel}',
          ],
          rows: [
            for (final point in result.points)
              [
                point.ply,
                point.angle,
                point.position,
                point.z,
                ...point.materialStress,
                for (final criterion in FailureCriterion.values)
                  point.results[criterion]!.failureIndex,
              ],
          ],
        ),
        ChartSection(
          'Failure index through the thickness',
          xLabel: 'z (${units.length})',
          yLabel: 'Failure index',
          series: [
            for (final criterion in FailureCriterion.values)
              ChartSeries(criterion.label, [
                for (final point in result.points)
                  (point.z, point.results[criterion]!.failureIndex),
              ]),
          ],
        ),
      ],
      notes: _notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    final precision = context.watch<NumberPrecisionHelper>().precision;
    String number(double value) => CalcReport.formatNumber(
          value,
          precision: precision,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(S.of(context).Results),
        actions: [
          ReportExportButton(buildReport: () => _buildReport(context)),
          IconButton(
            tooltip: 'Result precision',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResultPrecisionPage()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _FirstPlyFailureCard(result: result, number: number),
            const SizedBox(height: 12),
            _PlyTableCard(result: result, units: units, number: number),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final note in _notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $note',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstPlyFailureCard extends StatelessWidget {
  const _FirstPlyFailureCard({required this.result, required this.number});

  final LaminateFailureResult result;
  final String Function(double) number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First-ply failure', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Strength ratio R = load factor at first-ply failure',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final criterion in FailureCriterion.values) ...[
              () {
                final point = result.critical(criterion);
                final outcome = point.results[criterion]!;
                final fails = outcome.fails;
                final ratio = number(outcome.strengthRatio);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  isThreeLine: true,
                  leading: Icon(
                    fails
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: fails ? scheme.error : Colors.green.shade600,
                  ),
                  title: Text(criterion.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ply ${point.ply} (${_angle(point.angle)}) '
                        '${point.position.toLowerCase()} · ${outcome.mode}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R = $ratio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: fails ? scheme.error : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }(),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlyTableCard extends StatefulWidget {
  const _PlyTableCard({
    required this.result,
    required this.units,
    required this.number,
  });

  final LaminateFailureResult result;
  final Units units;
  final String Function(double) number;

  @override
  State<_PlyTableCard> createState() => _PlyTableCardState();
}

class _PlyTableCardState extends State<_PlyTableCard>
    with AutomaticKeepAliveClientMixin<_PlyTableCard> {
  // An even page size keeps the bottom/top surface pair of each ply together.
  static const _rowsPerPage = 20;
  int _pageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _PlyTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) _pageIndex = 0;
  }

  void _showPage(int target) {
    if (target == _pageIndex) return;
    final result = widget.result;
    setState(() => _pageIndex = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageIndex != target || widget.result != result) return;
      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;
      // After a short last page replaces a full page, reveal its new rows
      // instead of leaving the reader at the old footer's scroll position.
      Scrollable.ensureVisible(context, alignment: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final points = widget.result.points;
    final rowCount = points.length;
    final lastPage = rowCount == 0 ? 0 : (rowCount - 1) ~/ _rowsPerPage;
    final page = _pageIndex.clamp(0, lastPage).toInt();
    final start = page * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, rowCount).toInt();
    final localizations = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ply stresses and failure indices',
                key: const ValueKey('failure-table-heading'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Material axes, ${widget.units.stress}. Failure index ≥ 1 means '
                'failure.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                columns: [
                  const DataColumn(label: Text('Ply')),
                  const DataColumn(label: Text('Surface')),
                  const DataColumn(label: Text('σ1'), numeric: true),
                  const DataColumn(label: Text('σ2'), numeric: true),
                  const DataColumn(label: Text('τ12'), numeric: true),
                  for (final criterion in FailureCriterion.values)
                    DataColumn(
                      label: Text(criterion.shortLabel),
                      numeric: true,
                    ),
                ],
                rows: [
                  for (var rowIndex = start; rowIndex < end; rowIndex++)
                    () {
                      final point = points[rowIndex];
                      return DataRow(
                          key: ValueKey('failure-point-$rowIndex'),
                          cells: [
                            DataCell(
                                Text('${point.ply} (${_angle(point.angle)})')),
                            DataCell(Text(point.position)),
                            for (final stress in point.materialStress)
                              DataCell(Text(widget.number(stress))),
                            for (final criterion in FailureCriterion.values)
                              DataCell(() {
                                final index =
                                    point.results[criterion]!.failureIndex;
                                return Text(
                                  widget.number(index),
                                  style: TextStyle(
                                    color: index >= 1 ? scheme.error : null,
                                    fontWeight:
                                        index >= 1 ? FontWeight.w600 : null,
                                  ),
                                );
                              }()),
                          ]);
                    }(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    localizations.pageRowsInfoTitle(
                        rowCount == 0 ? 0 : start + 1, end, rowCount, false),
                    key: const ValueKey('failure-table-range'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey('failure-table-first-page'),
                        tooltip: localizations.firstPageTooltip,
                        onPressed: page == 0 ? null : () => _showPage(0),
                        icon: const Icon(Icons.first_page_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('failure-table-previous-page'),
                        tooltip: localizations.previousPageTooltip,
                        onPressed: page == 0 ? null : () => _showPage(page - 1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('failure-table-next-page'),
                        tooltip: localizations.nextPageTooltip,
                        onPressed:
                            page == lastPage ? null : () => _showPage(page + 1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('failure-table-last-page'),
                        tooltip: localizations.lastPageTooltip,
                        onPressed:
                            page == lastPage ? null : () => _showPage(lastPage),
                        icon: const Icon(Icons.last_page_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _angle(double angle) {
  final text = angle == angle.roundToDouble()
      ? angle.toStringAsFixed(0)
      : angle.toString();
  return '$text°';
}
