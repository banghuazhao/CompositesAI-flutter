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
  File? _selectedFile;
  String? fileDisplay;
  Uint8List? fileBytes;
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CompositesToolsViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Composites Tools"),
            backgroundColor: Colors.grey.shade800,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
               width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    _handleCreate(viewModel);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4, // Default elevation
                  ).copyWith(
                    overlayColor: MaterialStateProperty.all(Colors.grey.shade300), // Hover background color
                    elevation: MaterialStateProperty.resolveWith<double>(
                          (states) {
                        if (states.contains(MaterialState.hovered)) {
                          return 8; // Increased elevation on hover
                        }
                        return 4; // Default elevation
                      },
                    ),
                  ),
                  child: const Text(
                    "Create",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
            ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Create Your AI Tool",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                buildCard(
                  label: "Tool Title",
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Enter tool title",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                buildCard(
                  label: "Description",
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: "Add a short description about what this tool does",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                buildCard(
                  label: "Instructions",
                  child: TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      hintText: "What does this tool do? How does it work?",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload File"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.all(Colors.teal.shade300), // Hover background color
                    elevation: MaterialStateProperty.resolveWith<double>(
                          (states) {
                        if (states.contains(MaterialState.hovered)) {
                          return 8; // Increased elevation on hover
                        }
                        return 4; // Default elevation
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (fileDisplay != null) buildFileStatus(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget buildCard({required String label, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildFileStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: isUploading
            ? const CircularProgressIndicator()
            : const Icon(Icons.insert_drive_file, color: Colors.teal),
        title: Text(
          fileDisplay ?? "Unknown File",
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("Python File"),
        trailing: IconButton(
          icon: const Icon(Icons.clear, color: Colors.red),
          onPressed: () {
            setState(() {
              fileDisplay = null;
              _selectedFile = null;
              fileBytes = null;
            });
          },
        ),
      ),
    );
  }

  void _handleCreate(CompositesToolsViewModel viewModel) async {
    final title = _titleController.text;
    final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
    final instructions = _instructionsController.text.isEmpty ? null : _instructionsController.text;

    if (title.isEmpty) {
      _showSnackBar('Title is required!');
      return;
    }
    final file = _selectedFile ?? fileBytes;
    if (file == null) {
      _showSnackBar('Upload a file is required!');
      return;
    }

    try {
      final statusMessage = await viewModel.createCompositeTool(
        title,
        file,
        fileDisplay,
        description,
        instructions,
      );

      _showSuccessDialog(statusMessage);
    } catch (e) {
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
                Navigator.of(context).pop();
                Navigator.pop(context);
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
        allowedExtensions: ['py'],
      );

      if (result != null) {
        setState(() {
          fileDisplay = result.files.single.name;

          if (result.files.single.bytes != null) {
            fileBytes = result.files.single.bytes;
            _selectedFile = null;
          } else if (result.files.single.path != null) {
            _selectedFile = File(result.files.single.path!);
            fileBytes = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: $fileDisplay'),
            duration: Duration(seconds: 1),),
        );
      } else {
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
