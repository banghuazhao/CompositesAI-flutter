import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../../../util/NumberPrecisionHelper.dart';
import '../../../util/export/file_share.dart';
import '../model/calc_report.dart';

enum _ReportFormat { copy, csv, pdf }

/// App bar action that copies a calculator report or shares it as CSV or PDF.
class ReportExportButton extends StatefulWidget {
  const ReportExportButton({super.key, required this.buildReport});

  /// Built on demand so the export reflects the current result state.
  final CalcReport Function() buildReport;

  @override
  State<ReportExportButton> createState() => _ReportExportButtonState();
}

class _ReportExportButtonState extends State<ReportExportButton> {
  bool _busy = false;

  Future<void> _export(_ReportFormat format) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final strings = S.maybeOf(context);
    final copiedMessage =
        strings?.Calculator_results_copied ?? 'Results copied to clipboard';
    final failedMessage = format == _ReportFormat.copy
        ? strings?.Calculator_copy_failed ??
            'Could not copy these results. Please try again.'
        : strings?.Calculator_export_failed ??
            'Could not export these results.';
    setState(() => _busy = true);
    try {
      final report = widget.buildReport();
      switch (format) {
        case _ReportFormat.copy:
          await Clipboard.setData(
              ClipboardData(text: report.toClipboardText()));
          if (!mounted || !messenger.mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(copiedMessage)),
          );
        case _ReportFormat.csv:
          await FileShare.shareText(
            context,
            text: report.toCsv(),
            fileName: FileShare.safeFileName(report.title, 'csv'),
            mimeType: 'text/csv',
            subject: report.title,
          );
        case _ReportFormat.pdf:
          final precision = context.read<NumberPrecisionHelper>().precision;
          final bytes = await report.toPdf(precision: precision);
          if (!mounted) return;
          await FileShare.shareBytes(
            context,
            bytes: bytes,
            fileName: FileShare.safeFileName(report.title, 'pdf'),
            mimeType: 'application/pdf',
            subject: report.title,
          );
      }
    } catch (error) {
      debugPrint('Result export failed: $error');
      if (!mounted || !messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(failedMessage),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.maybeOf(context);
    return PopupMenuButton<_ReportFormat>(
      tooltip: strings?.Calculator_export_results ?? 'Export results',
      enabled: !_busy,
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share_rounded),
      onSelected: _export,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ReportFormat.copy,
          child: ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(strings?.Calculator_copy_results ?? 'Copy results'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ReportFormat.csv,
          child: ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(strings?.Calculator_share_csv ?? 'Share as CSV'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ReportFormat.pdf,
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(strings?.Calculator_share_pdf ?? 'Share as PDF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
