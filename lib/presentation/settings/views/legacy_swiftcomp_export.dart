import 'package:flutter/material.dart';
import 'package:swiftcomp/app/services/legacy_swiftcomp_data.dart';
import 'package:swiftcomp/generated/l10n.dart';

class LegacySwiftCompExport extends StatefulWidget {
  const LegacySwiftCompExport({super.key});

  @override
  State<LegacySwiftCompExport> createState() => _LegacySwiftCompExportState();
}

class _LegacySwiftCompExportState extends State<LegacySwiftCompExport> {
  final _data = const LegacySwiftCompData();
  bool _available = false;
  bool _busy = false;
  String? _message;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _data.isAvailable().then((available) {
      if (mounted && available) setState(() => _available = true);
    });
  }

  Future<void> _export() async {
    if (_busy) return;
    final strings = S.maybeOf(context);
    final saved =
        strings?.Legacy_data_saved ?? 'Legacy SwiftComp data exported.';
    final failed = strings?.Legacy_data_failed ??
        'Could not export legacy data. Your original data has not been changed.';
    setState(() {
      _busy = true;
      _message = null;
      _failed = false;
    });
    try {
      final didSave = await _data.export();
      if (mounted && didSave) setState(() => _message = saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = failed;
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final strings = S.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings?.Legacy_data_title ?? 'Legacy SwiftComp data',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(strings?.Legacy_data_help ??
                  'Export a complete backup of materials and layups saved in '
                      'the older Mac app. The original values and units are preserved; '
                      'this backup is separate from the new material library.'),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('legacy-swiftcomp-export'),
                onPressed: _busy ? null : _export,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_alt_rounded),
                label:
                    Text(strings?.Legacy_data_export ?? 'Export legacy data'),
              ),
              if (_message case final message?)
                Semantics(
                  liveRegion: true,
                  child: Text(message,
                      style: TextStyle(
                          color: _failed
                              ? Theme.of(context).colorScheme.error
                              : null)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
