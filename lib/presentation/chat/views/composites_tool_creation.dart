import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../viewModels/composites_tools_view_model.dart';
import 'composites_tools.dart';

class CompositesToolCreation extends StatefulWidget {
  @override
  State<CompositesToolCreation> createState() => _CompositesToolCreationState();
}

class _CompositesToolCreationState extends State<CompositesToolCreation> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  File? _selectedFile; // File selected by the user
  String? fileDisplay; // State variable
  Uint8List? fileBytes;
  bool isUploading = false; // Tracks uploading status

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<CompositesToolsViewModel>(),
      child: Consumer<CompositesToolsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Composites Tools"),
              backgroundColor: const Color.fromRGBO(51, 66, 78, 1),
              actions: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      _handleCreate(viewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contribute',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fill in the details to create your AI tool:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Tool Title Field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Tool Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      hintText:
                      "Add a short description about what this tool does",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),

                  // Instructions Field
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: "Instructions",
                      hintText: "What does this tool do? How does it work?",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),

                  // Upload File Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _uploadFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload File"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // Selected File Information
                  uploadStatusWidget(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget uploadStatusWidget() {
    if (fileDisplay == null) {
      return const SizedBox.shrink(); // No widget if no file is selected
    }

    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(top: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // File icon or placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade300,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: isUploading
                  ? const CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white,
              ) // Show progress while uploading
                  : const Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8.0), // Adjusted spacing to fit content

            // File name and type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileDisplay ?? "Unknown File",
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long file names
                  ),
                  const Text(
                    "Python", // File type (can be dynamic)
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreate(CompositesToolsViewModel viewModel) async {
    final title = _titleController.text;
    final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
    final instructions = _instructionsController.text.isEmpty ? null : _instructionsController.text;

    // Validate title
    if (title.isEmpty) {
      _showSnackBar('Title is required!');
      return;
    }

    // Validate file
    final file = _selectedFile ?? fileBytes;
    if (file == null) {
      _showSnackBar('Upload a file is required!');
      return;
    }

    try {
      // Call the createCompositeTool method and get the status message
      final statusMessage = await viewModel.createCompositeTool(
        title,
        file,
        fileDisplay,
        description,
        instructions,
      );

      // Show success dialog with the returned status message
      _showSuccessDialog(statusMessage);
    } catch (e) {
      // Handle any errors
      _showSnackBar('An error occurred: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Sent'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CompositesTools()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }



  void _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['py'], // Allowed file extensions
      );

      if (result != null) {
        setState(() {
          fileDisplay = result.files.single.name;

          if (result.files.single.bytes != null) {
            // For web
            fileBytes = result.files.single.bytes;
            _selectedFile = null; // Clear file reference for web
          } else if (result.files.single.path != null) {
            // For desktop/mobile
            _selectedFile = File(result.files.single.path!);
            fileBytes = null; // Clear bytes reference for mobile
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: $fileDisplay')),
        );
      } else {
        // No file selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

}
