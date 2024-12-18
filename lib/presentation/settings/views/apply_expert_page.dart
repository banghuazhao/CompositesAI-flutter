import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../viewModels/settings_view_model.dart';



class ApplyExpertPage extends StatefulWidget {
  @override
  _ApplyExpertPage createState() => _ApplyExpertPage();
}

class _ApplyExpertPage extends State<ApplyExpertPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _profileLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  @override
  void dispose() {
    _reasonController.dispose();
    _profileLinkController.dispose();
    super.dispose();
  }


  bool _isUrlValid(String url) {
    final urlPattern =
        r'^(https?:\/\/)?(www\.)?([a-zA-Z0-9-_]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$';
    return RegExp(urlPattern).hasMatch(url);
  }


  Future<void> _submitApplication() async {
    final profileLink = _profileLinkController.text;

    if (profileLink.isNotEmpty && !_isUrlValid(profileLink)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid URL.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Access the view model and submit the application
      final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
      final result = await viewModel.submitApplication(_reasonController.text, profileLink);

      if (result == 'Application successfully submitted. Please wait for approval.' ||
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
      print("Submission error: $error"); // Log the error for debugging
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
      appBar: AppBar(title: const Text("Expert Applications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filling these fields will increase your chances of approval and speed up the process.",
              style: TextStyle(
                fontSize: 16, // Slightly larger text
                fontWeight: FontWeight.w500, // Medium weight for emphasis
                color: Colors.blueAccent, // Use a subtle blue color for emphasis
              ),
              textAlign: TextAlign.center, // Center the text horizontally
            ),
            SizedBox(height: 25.0),
            Text(
              "Reason:",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Tell us why you’re applying to be an expert...",
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              "LinkedIn or Other Professional Profile Link:",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _profileLinkController,
              decoration: InputDecoration(
                hintText: "a link to showcase your professional work...",
              ),
              keyboardType: TextInputType.url, // URL-specific keyboard
            ),
            SizedBox(height: 20.0),
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Center the loading indicator
                : Center(
              child: ElevatedButton(
                onPressed: _submitApplication,
                child: Text("Apply"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
