import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/material_library.dart';
import '../model/unit_system.dart';

/// Builds a custom material from the current inputs, or returns null when
/// they are incomplete.
typedef MaterialFromInputs = LibraryMaterial? Function(String name);

/// Shows the material library and returns the picked material, if any.
Future<LibraryMaterial?> showMaterialLibrary(
  BuildContext context, {
  required MaterialKind kind,
  MaterialFromInputs? saveCurrent,
}) {
  return showModalBottomSheet<LibraryMaterial>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _MaterialLibrarySheet(
      kind: kind,
      saveCurrent: saveCurrent,
    ),
  );
}

/// Trailing header button that opens the library for a calculator card.
class MaterialLibraryButton extends StatelessWidget {
  const MaterialLibraryButton({
    super.key,
    required this.kind,
    required this.onSelected,
    this.saveCurrent,
  });

  final MaterialKind kind;
  final ValueChanged<LibraryMaterial> onSelected;
  final MaterialFromInputs? saveCurrent;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final material = await showMaterialLibrary(
          context,
          kind: kind,
          saveCurrent: saveCurrent,
        );
        if (material != null) onSelected(material);
      },
      icon: const Icon(Icons.inventory_2_outlined, size: 18),
      label: const Text('Library'),
    );
  }
}

class _MaterialLibrarySheet extends StatefulWidget {
  const _MaterialLibrarySheet({required this.kind, this.saveCurrent});

  final MaterialKind kind;
  final MaterialFromInputs? saveCurrent;

  @override
  State<_MaterialLibrarySheet> createState() => _MaterialLibrarySheetState();
}

class _MaterialLibrarySheetState extends State<_MaterialLibrarySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: MaterialLibrary.instance,
      builder: (context, _) {
        final query = _query.trim().toLowerCase();
        final materials = MaterialLibrary.instance
            .materials(widget.kind)
            .where((m) => query.isEmpty || m.name.toLowerCase().contains(query))
            .toList();
        final custom = materials.where((m) => m.isCustom).toList();
        final builtIn = materials.where((m) => !m.isCustom).toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                '${widget.kind.label} library',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Values fill in as ${units.summary}. Typical published data '
                'for preliminary design; check your supplier data sheets.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search materials',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              if (widget.saveCurrent != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saveCurrent,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save current inputs as a material'),
                  ),
                ),
              ],
              if (custom.isNotEmpty) ...[
                _sectionLabel(context, 'My materials'),
                for (final material in custom) _tile(context, material, units),
              ],
              _sectionLabel(context, 'Built-in'),
              if (builtIn.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No materials match your search.'),
                ),
              for (final material in builtIn) _tile(context, material, units),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _tile(BuildContext context, LibraryMaterial material, Units units) {
    final details = [
      material.summary(units),
      if (material.source.isNotEmpty) material.source,
    ].join('\n');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(material.name),
        subtitle: Text(details),
        isThreeLine: material.source.isNotEmpty,
        onTap: () => Navigator.of(context).pop(material),
        trailing: material.isCustom
            ? IconButton(
                tooltip: 'Delete ${material.name}',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(material),
              )
            : null,
      ),
    );
  }

  Future<void> _confirmDelete(LibraryMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete material?'),
        content: Text('"${material.name}" will be removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await MaterialLibrary.instance.remove(material);
  }

  Future<void> _saveCurrent() async {
    final saveCurrent = widget.saveCurrent;
    if (saveCurrent == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save material'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Material name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.trim().isEmpty) return;

    final material = saveCurrent(name.trim());
    final messenger = ScaffoldMessenger.of(context);
    if (material == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Enter the elastic constants before saving.'),
      ));
      return;
    }
    await MaterialLibrary.instance.save(material);
    messenger.showSnackBar(
      SnackBar(content: Text('Saved "${material.name}" to your library.')),
    );
  }
}
