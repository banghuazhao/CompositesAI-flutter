import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/settings/viewModels/admin_model_tool_view_model.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

class AdminModelToolPage extends StatelessWidget {
  const AdminModelToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AdminModelToolViewModel>()..load(),
      child: const _AdminModelToolView(),
    );
  }
}

class _AdminModelToolView extends StatefulWidget {
  const _AdminModelToolView();

  @override
  State<_AdminModelToolView> createState() => _AdminModelToolViewState();
}

class _AdminModelToolViewState extends State<_AdminModelToolView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalSidePaddingForContentWidth;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Model & Tool Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Models'),
              Tab(text: 'Tools'),
            ],
          ),
        ),
        body: Consumer<AdminModelToolViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading &&
                viewModel.models.isEmpty &&
                viewModel.tools.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: viewModel.load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  32,
                ),
                children: [
                  _SearchField(controller: _searchController),
                  if (viewModel.error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: viewModel.error!),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        150,
                    child: TabBarView(
                      children: [
                        _ModelList(query: _query),
                        _ToolList(query: _query),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search models and tools',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ModelList extends StatelessWidget {
  final String query;

  const _ModelList({required this.query});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();
    final models = viewModel.models.where((model) {
      final text =
          '${model.name} ${model.id} ${model.description}'.toLowerCase();
      return text.contains(query);
    }).toList();

    return Column(
      children: [
        _ListHeader(
          title: 'Models',
          count: models.length,
          icon: Icons.add_rounded,
          onPressed: () => _showModelSheet(context),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: models.isEmpty
              ? const _EmptyState(message: 'No models found')
              : ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return _ModelTile(model: model);
                  },
                ),
        ),
      ],
    );
  }
}

class _ToolList extends StatelessWidget {
  final String query;

  const _ToolList({required this.query});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();
    final tools = viewModel.tools.where((tool) {
      final text = '${tool.name} ${tool.id} ${tool.description}'.toLowerCase();
      return text.contains(query);
    }).toList();

    return Column(
      children: [
        _ListHeader(
          title: 'Tools',
          count: tools.length,
          icon: Icons.add_rounded,
          onPressed: () => _showToolSheet(context),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tools.isEmpty
              ? const _EmptyState(message: 'No tools found')
              : ListView.separated(
                  itemCount: tools.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return _ToolTile(tool: tool);
                  },
                ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onPressed;

  const _ListHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title ($count)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filled(
          tooltip: 'Add $title',
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ],
    );
  }
}

class _ModelTile extends StatelessWidget {
  final ChatModel model;

  const _ModelTile({required this.model});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();

    return _AdminCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(model.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.id, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (model.description.isNotEmpty)
              Text(
                model.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SmallChip(
                  label: model.isActive ? 'Active' : 'Inactive',
                  color: model.isActive ? Colors.green : Colors.grey,
                ),
                if (model.toolIds.isNotEmpty)
                  _SmallChip(
                    label: '${model.toolIds.length} tools',
                    color: Colors.blueGrey,
                  ),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: model.isActive ? 'Disable model' : 'Enable model',
              onPressed: viewModel.isSaving
                  ? null
                  : () => viewModel.toggleModel(model),
              icon: Icon(
                model.isActive
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_outlined,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Model actions',
              onSelected: (value) async {
                if (value == 'edit') {
                  _showModelSheet(context, model: model);
                } else if (value == 'delete') {
                  await _confirmDelete(
                    context,
                    title: 'Delete model?',
                    message: 'This removes ${model.name} from the workspace.',
                    onDelete: () => viewModel.deleteModel(model),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final ChatTool tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();

    return _AdminCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(tool.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tool.id, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (tool.description.isNotEmpty)
              Text(
                tool.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Tool actions',
          onSelected: (value) async {
            if (value == 'edit') {
              _showToolSheet(context, tool: tool);
            } else if (value == 'delete') {
              await _confirmDelete(
                context,
                title: 'Delete tool?',
                message: 'This removes ${tool.name} from the workspace.',
                onDelete: () => viewModel.deleteTool(tool),
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: !viewModel.isSaving,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Widget child;

  const _AdminCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showModelSheet(BuildContext context, {ChatModel? model}) async {
  final formKey = GlobalKey<FormState>();
  final idController = TextEditingController(text: model?.id ?? '');
  final nameController = TextEditingController(text: model?.name ?? '');
  final baseModelController =
      TextEditingController(text: model?.baseModelId ?? '');
  final descriptionController =
      TextEditingController(text: model?.description ?? '');
  var isActive = model?.isActive ?? true;
  final selectedToolIds = <String>{...?model?.toolIds};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final viewModel = context.watch<AdminModelToolViewModel>();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetTitle(
                        title: model == null ? 'Add model' : 'Edit model'),
                    _TextInput(
                      controller: idController,
                      label: 'Model ID',
                      enabled: model == null,
                      required: true,
                    ),
                    _TextInput(
                      controller: nameController,
                      label: 'Name',
                      required: true,
                    ),
                    _TextInput(
                      controller: baseModelController,
                      label: 'Base model ID',
                    ),
                    _TextInput(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 2,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) =>
                          setSheetState(() => isActive = value),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Allowed tools',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.tools.map((tool) {
                        final selected = selectedToolIds.contains(tool.id);
                        return FilterChip(
                          label: Text(tool.name),
                          selected: selected,
                          onSelected: (value) {
                            setSheetState(() {
                              if (value) {
                                selectedToolIds.add(tool.id);
                              } else {
                                selectedToolIds.remove(tool.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _SheetActions(
                      isSaving: viewModel.isSaving,
                      submitLabel:
                          model == null ? 'Create model' : 'Save model',
                      onSubmit: () async {
                        if (!formKey.currentState!.validate()) return;
                        await viewModel.saveModel(
                          existing: model,
                          id: idController.text.trim(),
                          name: nameController.text.trim(),
                          baseModelId: baseModelController.text.trim(),
                          description: descriptionController.text.trim(),
                          isActive: isActive,
                          toolIds: selectedToolIds.toList(growable: false),
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  idController.dispose();
  nameController.dispose();
  baseModelController.dispose();
  descriptionController.dispose();
}

Future<void> _showToolSheet(BuildContext context, {ChatTool? tool}) async {
  final formKey = GlobalKey<FormState>();
  final idController = TextEditingController(text: tool?.id ?? '');
  final nameController = TextEditingController(text: tool?.name ?? '');
  final descriptionController =
      TextEditingController(text: tool?.description ?? '');
  final contentController =
      TextEditingController(text: tool?.content ?? _defaultToolContent);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final viewModel = sheetContext.watch<AdminModelToolViewModel>();
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetTitle(title: tool == null ? 'Add tool' : 'Edit tool'),
                _TextInput(
                  controller: idController,
                  label: 'Tool ID',
                  enabled: tool == null,
                  required: true,
                ),
                _TextInput(
                  controller: nameController,
                  label: 'Name',
                  required: true,
                ),
                _TextInput(
                  controller: descriptionController,
                  label: 'Description',
                  maxLines: 2,
                ),
                _TextInput(
                  controller: contentController,
                  label: 'Python tool content',
                  required: true,
                  maxLines: 12,
                  monospace: true,
                ),
                const SizedBox(height: 20),
                _SheetActions(
                  isSaving: viewModel.isSaving,
                  submitLabel: tool == null ? 'Create tool' : 'Save tool',
                  onSubmit: () async {
                    if (!formKey.currentState!.validate()) return;
                    await viewModel.saveTool(
                      existing: tool,
                      id: idController.text.trim(),
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      content: contentController.text,
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  idController.dispose();
  nameController.dispose();
  descriptionController.dispose();
  contentController.dispose();
}

class _SheetTitle extends StatelessWidget {
  final String title;

  const _SheetTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool required;
  final int maxLines;
  final bool monospace;

  const _TextInput({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.required = false,
    this.maxLines = 1,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        minLines: maxLines > 1 ? 4 : 1,
        maxLines: maxLines,
        style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final bool isSaving;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  const _SheetActions({
    required this.isSaving,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onSubmit,
            child: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onDelete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await onDelete();
  }
}

const _defaultToolContent = '''
class Tools:
    def example(self, text: str) -> str:
        """Return a short transformed response."""
        return text
''';
