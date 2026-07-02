import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewModels/settings_view_model.dart';

class ApplyExpertPage extends StatefulWidget {
  const ApplyExpertPage({super.key});

  @override
  State<ApplyExpertPage> createState() => _ApplyExpertPage();
}

class _ApplyExpertPage extends State<ApplyExpertPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _profileLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _profileLinkController.dispose();
    super.dispose();
  }

  bool _isUrlValid(String url) {
    const urlPattern =
        r'^(https?:\/\/)?(www\.)?([a-zA-Z0-9-_]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$';
    return RegExp(urlPattern).hasMatch(url);
  }

  Future<void> _submitApplication() async {
    final profileLink = _profileLinkController.text;

    if (profileLink.isNotEmpty && !_isUrlValid(profileLink)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid URL.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
      final result = await viewModel.submitExpertRequest(
        _reasonController.text,
        profileLink,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Status'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, 'submit');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit: $error")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25.0),
            const Text(
              "Reason:",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: "Tell us why you’re applying to be an expert...",
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              "LinkedIn or Other Professional Profile Link:",
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _profileLinkController,
              decoration: const InputDecoration(
                hintText: "a link to showcase your professional work...",
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ElevatedButton(
                      onPressed: _submitApplication,
                      child: const Text("Apply"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
