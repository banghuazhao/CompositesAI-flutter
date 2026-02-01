import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:domain/entities/chat/message.dart';
import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import '../../auth/login_page.dart';
import '../../conponents/base64-image.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'message_list.dart';
import 'chat_list.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController textController =
  TextEditingController();
  final FocusNode focusNode = FocusNode();

  late ChatViewModel viewModel;

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _fetchChats();
    _fetchAuthSession();
  }

  Future<void> _fetchAuthSession() async {
    await viewModel.fetchAuthSessionNew();
    setState(() {});
  }

  Future<void> _fetchChats() async {
    await viewModel.fetchChats();
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
                        User? user = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                        if (user != null) {
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
                              viewModel.selectedMessages
                                  .clear(); // Remove all selections
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              // Smaller padding
                              minimumSize: const Size(88, 35),
                              // Smaller size
                              visualDensity: VisualDensity
                                  .compact, // Makes it more compact
                            ),
                          ),

                        const SizedBox(width: 8),
                        // Export Chat Dropdown Button
                        PopupMenuButton<String>(
                          icon: Row(
                            children: const [
                              Icon(Icons.download, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                "Export Chat",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          onSelected: (String value) async {
                            final chatViewModel = Provider.of<ChatViewModel>(
                                context,
                                listen: false);
                            if (value == 'export jsonl') {
                              await exportChatMessages(chatViewModel, context,
                                  false); // Call export JSON function
                            } else if (value == 'export xlsx') {
                              // Implement your Export XLSX logic here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Export XLSX selected")),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'export jsonl',
                              child: Row(
                                children: [
                                  Icon(Icons.file_download,
                                      color: Colors.black),
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
                                  ? ClipOval(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Base64Image(
                                            viewModel.user!.avatarUrl!),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.account_circle,
                                      size: 20, // Adjusted size for consistency
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
                                      shape: BoxShape
                                          .circle, // Ensure a perfect circle
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
          drawer: viewModel.isLoggedIn ? ChatList() : null,
          body: Stack(
            children: [
              if (viewModel.isLoggedIn) ...[
                Positioned.fill(
                  child: viewModel.selectedChat != null
                      ? MessageList()
                      : defaultQuestionView(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: inputBar(),
                )
              ] else
                noLoginView()
            ],
          ),
        );
      },
    );
  }

  Widget defaultQuestionView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30), // More spacing from the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'images/Icon-512.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10), // More spacing for a balanced look
                Flexible(
                  child: Text(
                    "Hi, I am Composites AI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "How can I help you today?",
            style: TextStyle(
              fontSize: 28, // Slightly larger for better readability
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          Center(
            // Center the grid
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context
                    .contentWidth, // Adjust as needed to keep it centered
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  int crossAxisCount = max(width ~/ 200, 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                    ),
                    itemCount: viewModel.defaultQuestions.length,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          await viewModel.onDefaultQuestionsTapped(index);
                        },
                        child: _buildDefaultQuestionCard(
                            viewModel.defaultQuestions[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // A helper function to create default question cards
  Widget _buildDefaultQuestionCard(String question) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      elevation: 2, // Lower elevation for a more compact look
      child: SizedBox(
        width: 80, // Reduce the width
        height: 30, // Reduce the height
        child: Padding(
          padding: const EdgeInsets.all(4.0), // Reduce padding
          child: Center(
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black),
              // Smaller font size
              maxLines: 3,
              overflow: TextOverflow.ellipsis, // Prevents overflow
            ),
          ),
        ),
      ),
    );
  }

  Widget inputBar() {
    return Column(
      children: [
        Container(
          width: context.contentWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) async {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      final isShiftPressed = HardwareKeyboard
                          .instance.logicalKeysPressed
                          .contains(LogicalKeyboardKey.shiftLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.shiftRight);
                      if (isShiftPressed) {
                        // Insert newline
                        final text = textController.text;
                        textController.text = "$text\n";
                        textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: textController.text.length),
                        );
                      } else if (!viewModel.isLoading) {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          if (await viewModel.reachChatLimit()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Daily chat limit reached (50/day)')),
                            );
                            return;
                          }
                          textController.clear();
                          await viewModel.sendInputMessage(text);
                        }
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        focusNode.requestFocus();
                      });
                    }
                  },
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ask anything about Composites...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    minLines: 2,
                    maxLines: 8,
                    onChanged: (text) {
                      setState(() {}); // Update UI for button state
                    },
                  ),
                ),
              ),
              viewModel.isLoading
                  ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: Icon(Icons.send),
                onPressed: textController.text.isEmpty
                    ? null
                    : () {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    textController.clear();
                    viewModel.sendInputMessage(text);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget noLoginView() {
    return Center(
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Please sign in to access the chat and continue your learning experience.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black, // Keep text fully visible
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              User? user = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
              if (user != null) {
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> exportChatMessages(ChatViewModel chatViewModel,
      BuildContext context, bool shouldDownloadSelected) async {
    try {
      // Get the list of messages from ChatViewModel
      final List<Message> messages = shouldDownloadSelected
          ? chatViewModel.selectedMessages
          : chatViewModel.messages;

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
    } catch (e) {
      // Handle errors
      print("Error exporting chat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export chat: $e")),
      );
    }
  }
}
