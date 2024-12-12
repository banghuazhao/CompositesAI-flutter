import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../viewModels/settings_view_model.dart';



class ApplyExpertPage extends StatefulWidget {
  @override
  _ApplyExpertPage createState() => _ApplyExpertPage();
}

class _ApplyExpertPage extends State<ApplyExpertPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Access the view model and submit the application
      final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
      final result = await viewModel.submitApplication(_reasonController.text);

      if (result == 'This user has already submitted an expert application. Please wait for approval.' ||
          result == 'This user has already submitted an expert application. Please wait for approval.' ||
          result == 'Submission failed due to an internal error. Please try again later.') {
        // Show a dialog and wait for the user to close it
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Application Status'),
            content: Text(result),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }

      // Add a slight delay before navigating back
      await Future.delayed(Duration(milliseconds: 300)); // Optional delay
      Navigator.pop(context, 'submit'); // Navigate back after dialog interaction
    } catch (error) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit: $error")),
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
      appBar: AppBar(title: const Text("Expert Apply")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reason (optional):",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Tell us the reason you want to apply to be an expert",
              ),
            ),
            SizedBox(height: 20.0),
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Center the loading indicator
                : Center(
              child: ElevatedButton(
                onPressed: _submitApplication,
                child: Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
