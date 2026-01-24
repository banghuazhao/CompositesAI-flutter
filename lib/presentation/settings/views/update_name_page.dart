import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../viewModels/settings_view_model.dart';


class UpdateNamePage extends StatefulWidget {
  final String currentName;

  const UpdateNamePage({Key? key, required this.currentName}) : super(key: key);

  @override
  _UpdateNamePageState createState() => _UpdateNamePageState();
}

class _UpdateNamePageState extends State<UpdateNamePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) {
      // Show validation message if name is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Access the view model and update the user's name
      // looks for an instance of SettingsViewModel that has been provided by a Provider widget (like ChangeNotifierProvider) somewhere higher in the widget tree
      final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
      await viewModel.updateUserName(_nameController.text);

      // Navigate back to the previous screen with a 'refresh' result
      Navigator.pop(context, 'refresh');
    } catch (error) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update name: $error")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Name")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your new username:",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: widget.currentName,
                hintStyle: const TextStyle(color: Colors.black54),
              ),
            ),
            SizedBox(height: 20.0),
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Center the loading indicator
                : Center(
              child: ElevatedButton(
                onPressed: _saveName,
                child: Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}