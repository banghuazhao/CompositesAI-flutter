import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/views/apply_expert_page.dart';
import '../../settings/views/login_page.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'composites_tool_creation.dart';

class CompositesTools extends StatefulWidget {
  @override
  State<CompositesTools> createState() => _CompositesToolsState();
}

class _CompositesToolsState extends State<CompositesTools> {
  // Temporary data for display
  final List<String> tools = [
    "Material Analyzer",
    "Stress Calculator",
    "Failure Predictor",
    "Composite Simulator",
    "Data Visualizer"
  ];

  void _showExpertDialog({required String message, String? actionLabel, VoidCallback? onAction}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Access Restricted'),
          content: Text(message), // Dynamic message
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            if (actionLabel != null && onAction != null) // Show action button if provided
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  onAction(); // Perform the action
                },
                child: Text(actionLabel),
              ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Composites Tools"),
        backgroundColor: const Color.fromRGBO(51, 66, 78, 1),
        actions: [
          Consumer<ChatViewModel>(
            builder: (context, viewModel, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Create Button
                  ElevatedButton(
                    onPressed: () {
                      if (viewModel.user == null) {
                        _showExpertDialog(
                          message: 'Please log in to access this feature.',
                          actionLabel: 'Log In',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            ); // Navigate to login page
                          },
                        );
                      } else if (viewModel.user?.isCompositeExpert == false) {
                        _showExpertDialog(
                          message: 'You need to be a composite expert to contribute. Please apply to become one.',
                          actionLabel: 'Become an Expert',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ApplyExpertPage()),
                            ); // Navigate to "Become an Expert" page
                          },
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompositesToolCreation(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Set button background color
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      '+ Contribute',
                      style: TextStyle(fontSize: 14, color: Colors.white), // White text color
                    ),
                  ),


                  const SizedBox(width: 14), // Space between button and avatar

                  // User Avatar and Verified Badge
                  GestureDetector(
                    onTap: () async {
                      String? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(user: viewModel.user),
                        ),
                      );
                      if (result == "refresh") {
                        await viewModel.checkAuthStatus(); // Refresh the authentication status
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none, // Ensures the badge is fully visible
                      alignment: Alignment.center,
                      children: [
                        // Avatar or Default Icon
                        viewModel.user?.avatarUrl != null
                            ? CircleAvatar(
                          backgroundImage: NetworkImage(viewModel.user!.avatarUrl!),
                          radius: 20,
                        )
                            : const Icon(
                          Icons.account_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                        // Verified Badge
                        if (viewModel.user?.isCompositeExpert == true)
                          Positioned(
                            right: -4, // Slightly outside the avatar
                            top: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Space between avatar and edge
                ],
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tools.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.build),
            title: Text(tools[index]),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Selected: ${tools[index]}")),
              );
            },
          );
        },
      ),
    );
  }
}
