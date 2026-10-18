import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewModels/settings_view_model.dart';

class UpdateNamePage extends StatefulWidget {
  final String currentName;
  final int? expectedSessionGeneration;

  const UpdateNamePage({
    super.key,
    required this.currentName,
    this.expectedSessionGeneration,
  });

  @override
  State<UpdateNamePage> createState() => _UpdateNamePageState();
}

class _UpdateNamePageState extends State<UpdateNamePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  SettingsViewModel? _viewModel;
  int? _sessionGeneration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = context.read<SettingsViewModel>();
      _sessionGeneration =
          widget.expectedSessionGeneration ?? _viewModel!.sessionGeneration;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    bool saved;
    try {
      saved = await _viewModel!.updateUserName(
        name,
        expectedSessionGeneration: _sessionGeneration,
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

    if (saved) {
      Navigator.pop(context, 'refresh');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update your name. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Name')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('name_input'),
                  controller: _nameController,
                  readOnly: _isLoading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name cannot be empty'
                      : null,
                  onFieldSubmitted: (_) => _saveName(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const ValueKey('name_save'),
                  onPressed: _isLoading ? null : _saveName,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Saving name',
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
