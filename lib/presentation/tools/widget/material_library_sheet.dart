import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _saving = false;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateQuery);
  }

  void _updateQuery() {
    final query = _searchController.text;
    if (_query == query) return;
    setState(() => _query = query);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_updateQuery)
      ..dispose();
    super.dispose();
  }

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
            .where((m) =>
                query.isEmpty ||
                m.name.toLowerCase().contains(query) ||
                m.source.toLowerCase().contains(query))
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
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search materials',
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .clearButtonTooltip,
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
              if (widget.saveCurrent != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _saveCurrent,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save current inputs as a material'),
                  ),
                ),
              ],
              if (custom.isNotEmpty) ...[
                _sectionLabel(context, 'My materials'),
                for (final material in custom) _tile(context, material, units),
              ],
              if (builtIn.isNotEmpty) ...[
                _sectionLabel(context, 'Built-in'),
                for (final material in builtIn) _tile(context, material, units),
              ],
              if (materials.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No materials match your search.'),
                ),
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
                onPressed: _deleting.contains(material.id)
                    ? null
                    : () => _confirmDelete(material),
              )
            : null,
      ),
    );
  }

  Future<void> _confirmDelete(LibraryMaterial material) async {
    if (!mounted || _deleting.contains(material.id)) return;
    setState(() => _deleting.add(material.id));
    final messenger = ScaffoldMessenger.of(context);
    var answered = false;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          void finish(bool confirmed) {
            if (answered) return;
            answered = true;
            Navigator.of(dialogContext).pop(confirmed);
          }

          return AlertDialog(
            scrollable: true,
            title: const Text('Delete material?'),
            content:
                Text('"${material.name}" will be removed from your library.'),
            actions: [
              TextButton(
                onPressed: () => finish(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => finish(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (!mounted || confirmed != true) return;
      await MaterialLibrary.instance.remove(material);
    } catch (_) {
      if (!mounted || !messenger.mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(S.maybeOf(context)?.Calculator_material_delete_failed ??
            'Could not delete this material. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _deleting.remove(material.id));
    }
  }

  Future<void> _saveCurrent() async {
    final saveCurrent = widget.saveCurrent;
    if (!mounted || saveCurrent == null || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      var enteredName = '';
      while (mounted) {
        final name = await showDialog<String>(
          context: context,
          builder: (_) => _MaterialNameDialog(initialName: enteredName),
        );
        if (!mounted || name == null) return;
        enteredName = name;
        final material = saveCurrent(name.trim());
        if (material == null) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Enter the elastic constants before saving.'),
          ));
          return;
        }
        LibraryMaterial? approvedReplacement;
        while (mounted) {
          try {
            await MaterialLibrary.instance
                .save(material, replaceExisting: approvedReplacement);
            if (!mounted || !messenger.mounted) return;
            messenger.showSnackBar(
              SnackBar(
                  content: Text('Saved "${material.name}" to your library.')),
            );
            return;
          } on MaterialNameConflict catch (conflict) {
            if (!mounted) return;
            final choice = await _replacementChoice(conflict.existing.name);
            if (!mounted || choice == null) return;
            if (choice == _ReplacementChoice.rename) break;
            approvedReplacement = conflict.existing;
            // The model rechecks this exact record at commit. If it changed
            // during confirmation, the next conflict requests fresh approval.
          }
        }
      }
    } catch (error) {
      if (!mounted || !messenger.mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Could not save this material. Check its values and try again.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<_ReplacementChoice?> _replacementChoice(String name) {
    var answered = false;
    return showDialog<_ReplacementChoice>(
      context: context,
      builder: (dialogContext) {
        final strings = S.maybeOf(dialogContext);
        void finish(_ReplacementChoice? choice) {
          if (answered) return;
          answered = true;
          Navigator.of(dialogContext).pop(choice);
        }

        return AlertDialog(
          scrollable: true,
          title: Text(strings?.Calculator_replace_material_title ??
              'Replace saved material?'),
          content: Text(strings?.Calculator_replace_material_message(name) ??
              'A saved material named "$name" already exists. Replace its saved values or choose another name.'),
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 4,
          actions: [
            TextButton(
              onPressed: () => finish(null),
              child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => finish(_ReplacementChoice.rename),
              child: Text(
                  strings?.Calculator_choose_another_name ??
                      'Choose another name',
                  textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: () => finish(_ReplacementChoice.replace),
              child: Text(strings?.Calculator_replace_material ?? 'Replace'),
            ),
          ],
        );
      },
    );
  }
}

enum _ReplacementChoice { replace, rename }

/// The dialog owns its controller until its route finishes the reverse
/// animation, including when a replacement flow immediately opens another one.
class _MaterialNameDialog extends StatefulWidget {
  const _MaterialNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_MaterialNameDialog> createState() => _MaterialNameDialogState();
}

class _MaterialNameDialogState extends State<_MaterialNameDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName)
      ..selection = TextSelection.collapsed(offset: widget.initialName.length);
  }

  void _submit() {
    if (_submitted || _controller.text.trim().isEmpty) return;
    _submitted = true;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: const Text('Save material'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Material name'),
          onSubmitted: (_) => _submit(),
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () {
              if (_submitted) return;
              _submitted = true;
              Navigator.of(context).pop();
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: _submit,
            child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          ),
        ],
      );
}
