import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'dart:ui';

import 'package:domain/entities/chat/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../../settings/views/login_page.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_message_list.dart';
import 'chat_session_drawer.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  late ChatViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _initializeChatSessions();
    _fetchAuthSession();
  }

  Future<void> _fetchAuthSession() async {
    await viewModel.fetchAuthSessionNew();
    setState(() {});
  }

  Future<void> _initializeChatSessions() async {
    await viewModel.initializeChatSessions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ChatViewModel>(
      //Consumer widget dynamically rebuilds the UI whenever the ChatViewModel changes
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chat"),
            actions: [
              Builder(
                builder: (context) {
                  if (!viewModel.isLoggedIn) {
                    // If the user is not logged in, show login icon
                    return IconButton(
                      icon: const Icon(Icons.manage_accounts),
                      color: Colors.white,
                      tooltip: "Sign In",
                      onPressed: () async {
                        String? result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                        if (result == "Log in Success") {
                          await viewModel.checkAuthStatus();
                          setState(() {}); // Trigger UI rebuild
                        }
                      },
                    );
                  } else {
                    // If the user is logged in, show profile info
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Keep it compact
                      children: [
                        if (viewModel.selectedMessages.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: "Clear Selection",
                            onPressed: () {
                              viewModel.selectedMessages.clear(); // Remove all selections
                              viewModel.notifyListeners(); // Update UI
                            },
                          ),
                        if (viewModel.selectedMessages.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              exportChatMessages(viewModel, context, true);
                            },
                            icon: const Icon(Icons.download, size: 18),
                            // Smaller icon
                            label: const Text(
                              "Download",
                              style: TextStyle(fontSize: 14), // Smaller text
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              // Smaller padding
                              minimumSize: const Size(88, 35),
                              // Smaller size
                              visualDensity: VisualDensity.compact, // Makes it more compact
                            ),
                          ),

                        const SizedBox(width: 8),
                        // Export Chat Dropdown Button
                        PopupMenuButton<String>(
                          icon: Row(
                            children: const [
                              Icon(Icons.download, color: Colors.teal),
                              SizedBox(width: 5),
                              Text(
                                "Export Chat",
                                style: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          onSelected: (String value) async {
                            final chatViewModel =
                                Provider.of<ChatViewModel>(context, listen: false);
                            if (value == 'export jsonl') {
                              await exportChatMessages(
                                  chatViewModel, context, false); // Call export JSON function
                            } else if (value == 'export xlsx') {
                              // Implement your Export XLSX logic here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Export XLSX selected")),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'export jsonl',
                              child: Row(
                                children: [
                                  Icon(Icons.file_download, color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("export jsonl"),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'export xlsx',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart, color: Colors.black),
                                  SizedBox(width: 10),
                                  Text("export xlsx"),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Spacing between the button and the avatar

                        // Avatar or Profile Button
                        GestureDetector(
                          onTap: () async {
                            String? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(
                                  user: viewModel.user,
                                ),
                              ),
                            );
                            if (result == "refresh") {
                              await viewModel
                                  .checkAuthStatus(); // Refresh the authentication status
                              setState(() {}); // Rebuild the UI
                            }
                          },
                          child: Stack(
                            alignment: Alignment.topRight,
                            // Align everything to the top-right corner
                            children: [
                              // Avatar or default icon
                              viewModel.user?.avatarUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(viewModel.user!.avatarUrl!),
                                      radius: 20, // Slightly bigger radius for better visuals
                                    )
                                  : const Icon(
                                      Icons.account_circle,
                                      size: 48, // Adjusted size for consistency
                                      color: Colors.white,
                                    ),

                              // Blue verified icon with a white circular background
                              if (viewModel.user?.isCompositeExpert == true)
                                Positioned(
                                  right: 0, // Align to the top-right corner
                                  top: 0,
                                  child: Container(
                                    width: 20,
                                    // Ensure fixed width
                                    height: 20,
                                    // Ensure fixed height
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      // White background for contrast
                                      shape: BoxShape.circle, // Ensure a perfect circle
                                    ),
                                    alignment: Alignment.center,
                                    // Center the icon
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      // Blue verification icon
                                      size: 16, // Size of the icon itself
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          drawer: viewModel.isLoggedIn ? ChatDrawer() : null,
          body: Stack(
            children: [
              // Main content (ChatMessageList or Login prompt)
              ChatMessageList(),

              // Blur effect applied when the user is not logged in and there are more than 6 messages
              if (!viewModel.isLoggedIn && viewModel.messages.length > 6)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  // Adjust blur intensity
                  child: Container(
                    color: Colors.black.withOpacity(0.2), // Semi-transparent overlay
                  ),
                ),

              // Foreground content (Text & Button) remains fully visible
              if (!viewModel.isLoggedIn && viewModel.messages.length > 6)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'images/Icon-512.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Please sign in to access the chat and continue your learning experience.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Keep text fully visible
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          String? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                          if (result == "Log in Success") {
                            await viewModel.checkAuthStatus();
                            setState(() {}); // Trigger UI rebuild
                          }
                        },
                        icon: const Icon(Icons.manage_accounts, size: 22),
                        label: const Text(
                          "Login to Chat",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> exportChatMessages(
      ChatViewModel chatViewModel, BuildContext context, bool shouldDownloadSelected) async {
    try {
      // Get the list of messages from ChatViewModel
      final List<Message> messages =
          shouldDownloadSelected ? chatViewModel.selectedMessages : chatViewModel.messages;

      // Convert messages to JSON format
      //.map() function goes through each message in the messages list one by one.
      final List<Map<String, dynamic>> messageData = messages.map((message) {
        return {
          "role": message.role, // e.g., "user" or "assistant"
          "content": message.content, // message text
        };
      }).toList();
      //.toList() Collects the Results:After processing all messages, .toList() takes all the resulting dictionaries from .map() and combines them into a new list.
      // Create a JSON string
      final String jsonString = jsonEncode({"messages": messageData});

      if (kIsWeb) {
        // Web: Use browser's download functionality.
        final blob = html.Blob([jsonString], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = "chat_export.json"; // Suggest "Downloads" behavior
        anchor.click();
        html.Url.revokeObjectUrl(url);

        // Notify the user about the export
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chat exported as chat_export.json in browser"),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Mobile/Desktop: Save to the Downloads directory
        final Directory? downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory == null) {
          throw Exception("Downloads directory is not available");
        }

        final File file = File('${downloadsDirectory.path}/chat_export.json');

        // Write the JSON string to the file
        await file.writeAsString(jsonString);

        // Notify the user about the export
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Chat exported to Downloads as chat_export.json"),
            duration: const Duration(seconds: 5),
          ),
        );

        print("Chat exported successfully to Downloads: ${file.path}");
      }
    } catch (e) {
      // Handle errors
      print("Error exporting chat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export chat: $e")),
      );
    }
  }
}
