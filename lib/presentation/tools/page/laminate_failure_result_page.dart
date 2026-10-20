import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/settings/views/result_precision_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

import '../model/calc_report.dart';
import '../model/failure_criteria.dart';
import '../model/unit_system.dart';
import '../widget/report_export_button.dart';
import 'laminate_failure_page.dart';

class LaminateFailureResultPage extends StatefulWidget {
  const LaminateFailureResultPage({
    super.key,
    required this.result,
    this.inputs = const [],
  });

  final LaminateFailureResult result;
  final List<ReportSection> inputs;

  @override
  State<LaminateFailureResultPage> createState() =>
      _LaminateFailureResultPageState();
}

class _LaminateFailureResultPageState extends State<LaminateFailureResultPage> {
  final _scrollController = ScrollController();
  final _summaryKey = GlobalKey();
  final _tableKey = GlobalKey<_PlyTableCardState>();
  _SurfaceFocusRequest? _focusRequest;

  LaminateFailureResult get result => widget.result;
  List<ReportSection> get inputs => widget.inputs;

  @override
  void didUpdateWidget(covariant LaminateFailureResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != result) _focusRequest = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isCurrentRequest(_SurfaceFocusRequest request) =>
      mounted &&
      identical(_focusRequest, request) &&
      identical(result, request.result) &&
      ModalRoute.of(context)?.isCurrent == true;

  void _viewSurface(LaminateFailureResult expectedResult,
      FailureCriterion criterion, int index) {
    if (!mounted ||
        !identical(result, expectedResult) ||
        ModalRoute.of(context)?.isCurrent != true ||
        index < 0 ||
        index >= result.points.length ||
        result.points[index].results[criterion] == null) {
      return;
    }
    final request = _SurfaceFocusRequest(result, criterion, index);
    setState(() => _focusRequest = request);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentRequest(request) || !_scrollController.hasClients) return;
      // The table may not exist yet when a large summary fills the viewport.
      // Reveal its boundary using the already-laid-out summary, then let the
      // lazy list mount/layout the table before looking up the requested row.
      final tableContext = _tableKey.currentContext;
      final table = tableContext?.findRenderObject();
      final summary = _summaryKey.currentContext?.findRenderObject();
      if (tableContext != null && table != null && table.attached) {
        Scrollable.ensureVisible(tableContext, alignment: 0);
      } else if (summary is RenderBox && summary.attached && summary.hasSize) {
        final viewport = RenderAbstractViewport.maybeOf(summary);
        if (viewport != null) {
          final offset = viewport.getOffsetToReveal(summary, 0).offset +
              summary.size.height +
              12;
          final position = _scrollController.position;
          _scrollController.jumpTo(offset
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble());
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCurrentRequest(request)) {
          _tableKey.currentState?.revealFocusedSurface(request);
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

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
                final critical = _criticalOutcome(result, criterion);
                final point = critical?.$1;
                final outcome = critical?.$2;
                return <Object?>[
                  criterion.label,
                  outcome?.strengthRatio,
                  point?.ply,
                  point?.angle,
                  point?.position,
                  outcome?.mode,
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
                  point.results[criterion]?.failureIndex,
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
                  if (point.results[criterion] case final outcome?)
                    (point.z, outcome.failureIndex),
              ]),
          ],
        ),
      ],
      notes: _notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedResult = result;
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
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _FirstPlyFailureCard(
              key: _summaryKey,
              result: result,
              number: number,
              onView: (criterion, index) =>
                  _viewSurface(displayedResult, criterion, index),
            ),
            const SizedBox(height: 12),
            _PlyTableCard(
              key: _tableKey,
              result: result,
              units: units,
              number: number,
              focusRequest: _focusRequest,
            ),
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
  const _FirstPlyFailureCard({
    super.key,
    required this.result,
    required this.number,
    required this.onView,
  });

  final LaminateFailureResult result;
  final String Function(double) number;
  final void Function(FailureCriterion criterion, int index) onView;

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
            if (result.points.isEmpty)
              Text(S.of(context).Calculator_no_failure_results),
            if (result.points.isNotEmpty)
              for (final criterion in FailureCriterion.values) ...[
                () {
                  final index = _criticalIndex(result, criterion);
                  if (index == null) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(criterion.label),
                      subtitle: const Text('—'),
                    );
                  }
                  final point = result.points[index];
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
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            key: ValueKey('failure-view-${criterion.name}'),
                            onPressed: () => onView(criterion, index),
                            icon: const Icon(Icons.table_rows_outlined),
                            label: Text(
                                S.maybeOf(context)?.Calculator_view_in_table ??
                                    'View in table'),
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

class _SurfaceFocusRequest {
  const _SurfaceFocusRequest(this.result, this.criterion, this.index);

  final LaminateFailureResult result;
  final FailureCriterion criterion;
  final int index;
}

class _PlyTableCard extends StatefulWidget {
  const _PlyTableCard({
    super.key,
    required this.result,
    required this.units,
    required this.number,
    this.focusRequest,
  });

  final LaminateFailureResult result;
  final Units units;
  final String Function(double) number;
  final _SurfaceFocusRequest? focusRequest;

  @override
  State<_PlyTableCard> createState() => _PlyTableCardState();
}

class _PlyTableCardState extends State<_PlyTableCard>
    with AutomaticKeepAliveClientMixin<_PlyTableCard> {
  // An even page size keeps the bottom/top surface pair of each ply together.
  static const _rowsPerPage = 20;
  int _pageIndex = 0;
  FailureCriterion? _criterion;
  bool _onlyFailing = false;
  int _revealRevision = 0;
  int? _focusedOriginalIndex;
  final _focusedCellKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applyFocus(widget.focusRequest);
  }

  @override
  void didUpdateWidget(covariant _PlyTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _pageIndex = 0;
      _focusedOriginalIndex = null;
      _revealTable();
    }
    if (!identical(oldWidget.focusRequest, widget.focusRequest)) {
      _applyFocus(widget.focusRequest);
    }
  }

  void _applyFocus(_SurfaceFocusRequest? request) {
    if (request == null ||
        !identical(request.result, widget.result) ||
        request.index < 0 ||
        request.index >= widget.result.points.length) {
      return;
    }
    final outcome =
        widget.result.points[request.index].results[request.criterion];
    if (outcome == null) return;
    _revealRevision++;
    _criterion = request.criterion;
    _onlyFailing = _onlyFailing && outcome.fails;
    var row = 0;
    for (var index = 0; index < request.index; index++) {
      if (!_onlyFailing ||
          (widget.result.points[index].results[_criterion]?.fails ?? false)) {
        row++;
      }
    }
    _pageIndex = row ~/ _rowsPerPage;
    _focusedOriginalIndex = request.index;
  }

  void revealFocusedSurface(_SurfaceFocusRequest request) {
    if (!mounted ||
        !identical(widget.focusRequest, request) ||
        _focusedOriginalIndex != request.index) {
      return;
    }
    final target = _focusedCellKey.currentContext;
    final renderObject = target?.findRenderObject();
    if (target == null || renderObject == null || !renderObject.attached) {
      return;
    }
    Scrollable.ensureVisible(target, alignment: 0.5);
  }

  void _showPage(int target) {
    if (target == _pageIndex) return;
    setState(() {
      _pageIndex = target;
      _focusedOriginalIndex = null;
    });
    _revealTable();
  }

  void _selectCriterion(FailureCriterion? criterion) {
    if (criterion == _criterion) return;
    setState(() {
      _criterion = criterion;
      _pageIndex = 0;
      _focusedOriginalIndex = null;
    });
    _revealTable();
  }

  void _setOnlyFailing(bool onlyFailing) {
    if (onlyFailing == _onlyFailing) return;
    setState(() {
      _onlyFailing = onlyFailing;
      _pageIndex = 0;
      _focusedOriginalIndex = null;
    });
    _revealTable();
  }

  void _revealTable() {
    final revision = ++_revealRevision;
    final result = widget.result;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _revealRevision != revision || widget.result != result) {
        return;
      }
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
    final criteria =
        _criterion == null ? FailureCriterion.values : [_criterion!];
    // Keep original indexes so filtering never changes surface identity or
    // scans all points while building an individual table row.
    final indexes = [
      for (var index = 0; index < points.length; index++)
        if (!_onlyFailing ||
            criteria.any((criterion) =>
                points[index].results[criterion]?.fails ?? false))
          index,
    ];
    final rowCount = indexes.length;
    final lastPage = rowCount == 0 ? 0 : (rowCount - 1) ~/ _rowsPerPage;
    final page = _pageIndex.clamp(0, lastPage).toInt();
    final start = page * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, rowCount).toInt();
    final localizations = MaterialLocalizations.of(context);
    final strings = S.of(context);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(strings.Calculator_failure_criterion),
                  Semantics(
                    label: strings.Calculator_failure_criterion,
                    child: DropdownButton<FailureCriterion>(
                      key: const ValueKey('failure-criterion-filter'),
                      value: _criterion,
                      hint: Text(strings.Calculator_all_failure_criteria,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      isExpanded: true,
                      itemHeight: null,
                      selectedItemBuilder: (context) => [
                        strings.Calculator_all_failure_criteria,
                        for (final criterion in FailureCriterion.values)
                          criterion.label,
                      ]
                          .map((label) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      items: [
                        DropdownMenuItem<FailureCriterion>(
                          child: Text(strings.Calculator_all_failure_criteria),
                        ),
                        for (final criterion in FailureCriterion.values)
                          DropdownMenuItem(
                            value: criterion,
                            child: Text(criterion.label),
                          ),
                      ],
                      onChanged: _selectCriterion,
                    ),
                  ),
                  if (_focusedOriginalIndex case final index?)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        S.maybeOf(context)?.Calculator_focused_surface(
                                points[index].ply, points[index].position) ??
                            'Selected surface: ply ${points[index].ply}, '
                                '${points[index].position}',
                        key: const ValueKey('failure-focused-surface'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  SwitchListTile(
                    key: const ValueKey('failure-only-failed-filter'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.Calculator_failed_surfaces_only),
                    value: _onlyFailing,
                    onChanged: _setOnlyFailing,
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      strings.Calculator_failure_filter_summary(
                          rowCount, points.length),
                      key: const ValueKey('failure-filter-status'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (indexes.isEmpty)
              Padding(
                key: const ValueKey('failure-empty-state'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(points.isEmpty
                        ? strings.Calculator_no_failure_results
                        : strings.Calculator_no_failed_surfaces),
                    const SizedBox(height: 4),
                    Text(strings.Calculator_failure_exports_all,
                        style: theme.textTheme.bodySmall),
                  ],
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
                  for (final criterion in criteria)
                    DataColumn(
                      label: Text(criterion.shortLabel),
                      numeric: true,
                    ),
                ],
                rows: [
                  for (var rowIndex = start; rowIndex < end; rowIndex++)
                    () {
                      final originalIndex = indexes[rowIndex];
                      final point = points[originalIndex];
                      return DataRow(
                          key: ValueKey('failure-point-$originalIndex'),
                          selected: originalIndex == _focusedOriginalIndex,
                          cells: [
                            DataCell(Text(
                              '${point.ply} (${_angle(point.angle)})',
                              key: originalIndex == _focusedOriginalIndex
                                  ? _focusedCellKey
                                  : null,
                            )),
                            DataCell(Text(point.position)),
                            for (final stress in point.materialStress)
                              DataCell(Text(widget.number(stress))),
                            for (final criterion in criteria)
                              DataCell(() {
                                final outcome = point.results[criterion];
                                final fails = outcome?.fails ?? false;
                                return Text(
                                  outcome == null
                                      ? '—'
                                      : widget.number(outcome.failureIndex),
                                  style: TextStyle(
                                    color: fails ? scheme.error : null,
                                    fontWeight: fails ? FontWeight.w600 : null,
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

(PlyStressPoint, CriterionResult)? _criticalOutcome(
    LaminateFailureResult result, FailureCriterion criterion) {
  final index = _criticalIndex(result, criterion);
  if (index == null) return null;
  final point = result.points[index];
  return (point, point.results[criterion]!);
}

int? _criticalIndex(LaminateFailureResult result, FailureCriterion criterion) {
  int? critical;
  for (var index = 0; index < result.points.length; index++) {
    final point = result.points[index];
    final outcome = point.results[criterion];
    if (outcome != null &&
        (critical == null ||
            outcome.strengthRatio <
                result.points[critical].results[criterion]!.strengthRatio)) {
      critical = index;
    }
  }
  return critical;
}

String _angle(double angle) {
  final text = angle == angle.roundToDouble()
      ? angle.toStringAsFixed(0)
      : angle.toString();
  return '$text°';
}
