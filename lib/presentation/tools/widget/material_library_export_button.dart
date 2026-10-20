import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../../../util/export/file_share.dart';
import '../model/material_library.dart';
import '../model/material_library_export.dart';

/// Shares all saved materials, independently of the library kind or search.
class MaterialLibraryExportButton extends StatefulWidget {
  const MaterialLibraryExportButton({super.key});

  @override
  State<MaterialLibraryExportButton> createState() =>
      _MaterialLibraryExportButtonState();
}

class _MaterialLibraryExportButtonState
    extends State<MaterialLibraryExportButton> {
  bool _busy = false;
  String? _error;

  Future<void> _export(BuildContext buttonContext) async {
    if (_busy || !mounted) return;
    final failureMessage =
        S.maybeOf(context)?.Calculator_material_export_failed ??
            'Could not export saved materials. Please try again.';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Capture only the committed saved list, before the first asynchronous
      // operation. A later save/delete cannot change this share's contents.
      final snapshot =
          List<LibraryMaterial>.of(MaterialLibrary.instance.customMaterials);
      if (snapshot.isEmpty) return;
      final text = MaterialLibraryExport.toJson(snapshot);
      await FileShare.shareText(
        buttonContext,
        text: text,
        fileName: FileShare.safeFileName('CompositesAI materials', 'json'),
        mimeType: 'application/json',
        subject: 'CompositesAI materials',
      );
    } catch (error) {
      debugPrint('Material export failed: $error');
      if (!mounted) return;
      setState(() => _error = failureMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.maybeOf(context);
    return ListenableBuilder(
      listenable: MaterialLibrary.instance,
      builder: (context, _) {
        final hasMaterials =
            MaterialLibrary.instance.customMaterials.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              // Anchor the iPad share popover to the actual button, excluding
              // the explanatory text below it.
              builder: (buttonContext) => TextButton.icon(
                key: const Key('material-library-export-button'),
                onPressed: _busy || !hasMaterials
                    ? null
                    : () => _export(buttonContext),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(strings?.Calculator_export_materials ??
                    'Export my materials (JSON)'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                hasMaterials
                    ? strings?.Calculator_export_materials_help ??
                        'Exports all saved materials in SI units, including '
                            'materials outside the current search.'
                    : strings?.Calculator_material_export_empty ??
                        'Save a custom material to enable JSON export.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    key: const Key('material-library-export-error'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
