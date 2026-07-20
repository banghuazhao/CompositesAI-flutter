import 'package:domain/chat/entities/chat_model.dart';
import 'package:domain/chat/entities/chat_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/settings/viewModels/admin_model_tool_view_model.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

enum _ManagementKind { models, tools }

class AdminModelManagementPage extends StatelessWidget {
  const AdminModelManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AdminModelToolViewModel>()..loadModelsAndTools(),
      child: const _AdminManagementView(kind: _ManagementKind.models),
    );
  }
}

class AdminToolManagementPage extends StatelessWidget {
  const AdminToolManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AdminModelToolViewModel>()..loadTools(),
      child: const _AdminManagementView(kind: _ManagementKind.tools),
    );
  }
}

class _AdminManagementView extends StatefulWidget {
  final _ManagementKind kind;

  const _AdminManagementView({required this.kind});

  @override
  State<_AdminManagementView> createState() => _AdminManagementViewState();
}

class _AdminManagementViewState extends State<_AdminManagementView> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get _managesModels => widget.kind == _ManagementKind.models;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateQuery);
  }

  void _updateQuery() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
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
    final horizontalPadding = context.horizontalSidePaddingForContentWidth;
    final viewModel = context.watch<AdminModelToolViewModel>();
    final title = _managesModels ? 'Model Management' : 'Tool Management';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Column(
            children: [
              _SearchField(
                controller: _searchController,
                hintText: _managesModels ? 'Search models' : 'Search tools',
              ),
              if (viewModel.error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: viewModel.error!),
              ],
              const SizedBox(height: 12),
              _ListHeader(
                title: _managesModels ? 'Models' : 'Tools',
                count: _managesModels
                    ? _filteredModels(viewModel).length
                    : _filteredTools(viewModel).length,
                onPressed: viewModel.isSaving
                    ? null
                    : () => _managesModels
                        ? _openModelEditor(context)
                        : _openToolEditor(context),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildList(viewModel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(AdminModelToolViewModel viewModel) {
    if (viewModel.isLoading &&
        (_managesModels ? viewModel.models.isEmpty : viewModel.tools.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    final refresh =
        _managesModels ? viewModel.loadModelsAndTools : viewModel.loadTools;

    if (_managesModels) {
      final models = _filteredModels(viewModel);
      return RefreshIndicator(
        onRefresh: refresh,
        child: models.isEmpty
            ? const _EmptyList(message: 'No models found')
            : ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: models.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _ModelTile(model: models[index]),
              ),
      );
    }

    final tools = _filteredTools(viewModel);
    return RefreshIndicator(
      onRefresh: refresh,
      child: tools.isEmpty
          ? const _EmptyList(message: 'No tools found')
          : ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ToolTile(tool: tools[index]),
            ),
    );
  }

  List<ChatModel> _filteredModels(AdminModelToolViewModel viewModel) {
    return viewModel.models.where((model) {
      final text =
          '${model.name} ${model.id} ${model.description}'.toLowerCase();
      return text.contains(_query);
    }).toList();
  }

  List<ChatTool> _filteredTools(AdminModelToolViewModel viewModel) {
    return viewModel.tools.where((tool) {
      final text = '${tool.name} ${tool.id} ${tool.description}'.toLowerCase();
      return text.contains(_query);
    }).toList();
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: controller.clear,
              ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onPressed;

  const _ListHeader({
    required this.title,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton.filled(
          tooltip: 'Add $title',
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: viewModel.isSaving
            ? null
            : () => _openModelEditor(context, model: model),
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
                _SmallChip(
                  label: '${model.toolIds.length} tools',
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: model.isActive,
              onChanged: viewModel.isSaving
                  ? null
                  : (_) => viewModel.toggleModel(model),
            ),
            PopupMenuButton<String>(
              tooltip: 'Model actions',
              onSelected: (value) {
                if (value == 'edit') {
                  _openModelEditor(context, model: model);
                } else if (value == 'delete') {
                  _confirmDelete(
                    context,
                    title: 'Delete model?',
                    message: 'This removes ${model.name} from the workspace.',
                    onDelete: () async {
                      await viewModel.deleteModel(model);
                    },
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: viewModel.isSaving
            ? null
            : () => _openToolEditor(context, tool: tool),
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
          onSelected: (value) {
            if (value == 'edit') {
              _openToolEditor(context, tool: tool);
            } else if (value == 'delete') {
              _confirmDelete(
                context,
                title: 'Delete tool?',
                message: 'This removes ${tool.name} from the workspace.',
                onDelete: () async {
                  await viewModel.deleteTool(tool);
                },
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

Future<void> _openModelEditor(BuildContext context, {ChatModel? model}) {
  final viewModel = context.read<AdminModelToolViewModel>();
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _ModelEditorPage(model: model),
      ),
    ),
  );
}

class _ModelEditorPage extends StatefulWidget {
  final ChatModel? model;

  const _ModelEditorPage({this.model});

  @override
  State<_ModelEditorPage> createState() => _ModelEditorPageState();
}

class _ModelEditorPageState extends State<_ModelEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _baseModelController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late final Set<String> _selectedToolIds;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    _idController = TextEditingController(text: model?.id ?? '');
    _nameController = TextEditingController(text: model?.name ?? '');
    _baseModelController =
        TextEditingController(text: model?.baseModelId ?? '');
    _descriptionController =
        TextEditingController(text: model?.description ?? '');
    _isActive = model?.isActive ?? true;
    _selectedToolIds = <String>{...?model?.toolIds};
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _baseModelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();
    final isEditing = widget.model != null;
    final horizontalPadding = context.horizontalSidePaddingForContentWidth;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Model' : 'Add Model')),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              horizontalPadding, 16, horizontalPadding, 120),
          children: [
            if (viewModel.error != null) ...[
              _ErrorBanner(message: viewModel.error!),
              const SizedBox(height: 16),
            ],
            _TextInput(
              controller: _idController,
              label: 'Model ID',
              enabled: !isEditing,
              required: true,
            ),
            _TextInput(
                controller: _nameController, label: 'Name', required: true),
            _TextInput(
                controller: _baseModelController, label: 'Base model ID'),
            _TextInput(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Model active'),
              subtitle: const Text('Inactive models are unavailable in chat.'),
              value: _isActive,
              onChanged: viewModel.isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 20),
            Text(
              'Tools for this model',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose tools individually. These assignments apply only to this model.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            if (viewModel.tools.isEmpty)
              const _InlineEmpty(
                message: 'No tools are available. Add them in Tool Management.',
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < viewModel.tools.length;
                        index++) ...[
                      if (index > 0) const Divider(height: 1),
                      _ModelToolToggle(
                        tool: viewModel.tools[index],
                        selected: _selectedToolIds
                            .contains(viewModel.tools[index].id),
                        enabled: !viewModel.isSaving,
                        onChanged: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedToolIds.add(viewModel.tools[index].id);
                            } else {
                              _selectedToolIds
                                  .remove(viewModel.tools[index].id);
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _EditorActions(
        isSaving: viewModel.isSaving,
        submitLabel: isEditing ? 'Save Model' : 'Create Model',
        onSubmit: _save,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await context.read<AdminModelToolViewModel>().saveModel(
          existing: widget.model,
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          baseModelId: _baseModelController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          toolIds: _selectedToolIds.toList(growable: false),
        );
    if (saved && mounted) Navigator.pop(context);
  }
}

class _ModelToolToggle extends StatelessWidget {
  final ChatTool tool;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ModelToolToggle({
    required this.tool,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: selected,
      onChanged: enabled ? onChanged : null,
      title: Text(tool.name),
      subtitle: Text(tool.description.isEmpty ? tool.id : tool.description),
    );
  }
}

Future<void> _openToolEditor(BuildContext context, {ChatTool? tool}) {
  final viewModel = context.read<AdminModelToolViewModel>();
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _ToolEditorPage(tool: tool),
      ),
    ),
  );
}

class _ToolEditorPage extends StatefulWidget {
  final ChatTool? tool;

  const _ToolEditorPage({this.tool});

  @override
  State<_ToolEditorPage> createState() => _ToolEditorPageState();
}

class _ToolEditorPageState extends State<_ToolEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    final tool = widget.tool;
    _idController = TextEditingController(text: tool?.id ?? '');
    _nameController = TextEditingController(text: tool?.name ?? '');
    _descriptionController =
        TextEditingController(text: tool?.description ?? '');
    _contentController =
        TextEditingController(text: tool?.content ?? _defaultToolContent);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModelToolViewModel>();
    final isEditing = widget.tool != null;
    final horizontalPadding = context.horizontalSidePaddingForContentWidth;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Tool' : 'Add Tool')),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              horizontalPadding, 16, horizontalPadding, 120),
          children: [
            if (viewModel.error != null) ...[
              _ErrorBanner(message: viewModel.error!),
              const SizedBox(height: 16),
            ],
            _TextInput(
              controller: _idController,
              label: 'Tool ID',
              enabled: !isEditing,
              required: true,
            ),
            _TextInput(
                controller: _nameController, label: 'Name', required: true),
            _TextInput(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            _TextInput(
              controller: _contentController,
              label: 'Python tool content',
              required: true,
              maxLines: 16,
              monospace: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _EditorActions(
        isSaving: viewModel.isSaving,
        submitLabel: isEditing ? 'Save Tool' : 'Create Tool',
        onSubmit: _save,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await context.read<AdminModelToolViewModel>().saveTool(
          existing: widget.tool,
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          content: _contentController.text,
        );
    if (saved && mounted) Navigator.pop(context);
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
        minLines: maxLines > 1 ? maxLines.clamp(3, 6) : 1,
        maxLines: maxLines,
        style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
            : null,
      ),
    );
  }
}

class _EditorActions extends StatelessWidget {
  final bool isSaving;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  const _EditorActions({
    required this.isSaving,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalSidePaddingForContentWidth;
    return SafeArea(
      minimum:
          EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 10),
      child: Row(
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
      ),
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
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String message;

  const _EmptyList({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        _InlineEmpty(message: message),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String message;

  const _InlineEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
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
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) await onDelete();
}

const _defaultToolContent = '''
class Tools:
    def example(self, text: str) -> str:
        """Return a short transformed response."""
        return text
''';
