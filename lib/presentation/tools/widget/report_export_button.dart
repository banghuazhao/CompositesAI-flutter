import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    setState(() => _busy = true);
    try {
      final report = widget.buildReport();
      switch (format) {
        case _ReportFormat.copy:
          await Clipboard.setData(
              ClipboardData(text: report.toClipboardText()));
          if (!mounted || !messenger.mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Results copied to clipboard')),
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
          content: Text(format == _ReportFormat.copy
              ? 'Could not copy these results. Please try again.'
              : 'Could not export these results.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReportFormat>(
      tooltip: 'Export results',
      enabled: !_busy,
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share_rounded),
      onSelected: _export,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ReportFormat.copy,
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Copy results'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ReportFormat.csv,
          child: ListTile(
            leading: Icon(Icons.table_chart_outlined),
            title: Text('Share as CSV'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ReportFormat.pdf,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Share as PDF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
