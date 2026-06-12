import 'dart:ui';

import 'package:domain/auth/entities/user.dart';
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

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, RouteAware, WidgetsBindingObserver {
  /// Empty-state suggestion chips: matches Card shape + InkWell ripple.
  static const double _kSuggestionChipRadius = 18;

  @override
  bool get wantKeepAlive => true;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  late ChatViewModel viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await viewModel.fetchAuthSessionNew();
      if (viewModel.isLoggedIn) {
        await Future.wait([
          viewModel.fetchChats(),
          viewModel.fetchTools(),
        ]);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && viewModel.isLoggedIn) {
      viewModel.fetchChats();
      viewModel.fetchTools();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ChatViewModel>(
      //Consumer widget dynamically rebuilds the UI whenever the ChatViewModel changes
      builder: (context, viewModel, _) {
        if (viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || viewModel.errorMessage == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage!)),
            );
            viewModel.errorMessage = null;
          });
        }

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
                          if (viewModel.isLoggedIn) {
                            await Future.wait([
                              viewModel.fetchChats(),
                              viewModel.fetchTools(),
                            ]);
                          }
                        }
                      },
                    );
                  } else {
                    // If the user is logged in, show profile info
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Keep it compact
                      children: [
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
                      ? (viewModel.isLoadingMessages
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : MessageList())
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
    final name = (viewModel.user?.name ?? '').trim();
    final email = (viewModel.user?.email ?? '').trim();
    final greetingTarget = name.isNotEmpty ? name : email;
    final greeting = greetingTarget.isNotEmpty
        ? 'Hi, $greetingTarget'
        : 'Hi, I am Composites AI';

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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
                    'images/app_icon.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10), // More spacing for a balanced look
                Flexible(
                  child: Text(
                    greeting,
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Text(
                  "How can I help you today?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose a topic or ask your own question",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.contentWidth,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: viewModel.defaultQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(_kSuggestionChipRadius),
                    onTap: () async {
                      await viewModel.onDefaultQuestionsTapped(index);
                    },
                    child: _buildDefaultQuestionCard(
                      context,
                      viewModel.defaultQuestions[index],
                      index,
                    ),
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

  /// Leading icons for the empty-state suggestion chips (aligned with topic tone).
  IconData _leadingIconForDefaultQuestion(int index) {
    switch (index) {
      case 2:
        return Icons.history_rounded; // early history — clock / timeline
      case 3:
        return Icons.help_outline; // misconceptions — questionmark.circle
      default:
        return Icons.auto_awesome_outlined; // first & second prompts
    }
  }

  Widget _buildDefaultQuestionCard(
    BuildContext context,
    String question,
    int index,
  ) {
    final theme = Theme.of(context);
    final borderColor = Colors.grey.shade200;
    final fillColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.92);

    return Card(
      margin: EdgeInsets.zero,
      color: fillColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kSuggestionChipRadius),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _leadingIconForDefaultQuestion(index),
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                textAlign: TextAlign.start,
                style:
                    (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontSize: 15,
                  height: 1.35,
                  color: textColor,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                      } else if (!viewModel.isSendingMessage) {
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
              _buildToolsButton(),
              viewModel.isSendingMessage
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

  Widget _buildToolsButton() {
    final selectedCount = viewModel.selectedToolIds.length;
    final hasTools = viewModel.tools.isNotEmpty;
    final color = selectedCount > 0
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade600;

    return IconButton(
      icon: viewModel.isLoadingTools
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Badge(
              isLabelVisible: selectedCount > 0,
              label: Text('$selectedCount'),
              child: Icon(Icons.build_circle_outlined, color: color),
            ),
      tooltip: hasTools ? 'Tools' : 'No tools available',
      onPressed: viewModel.isLoadingTools || !hasTools
          ? null
          : () {
              _showToolsSheet();
            },
    );
  }

  Future<void> _showToolsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer<ChatViewModel>(
          builder: (context, model, _) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tools',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final enableAll = model.selectedToolIds.length !=
                                model.tools.length;
                            model.setAllToolsEnabled(enableAll);
                          },
                          child: Text(
                            model.selectedToolIds.length == model.tools.length
                                ? 'Disable all'
                                : 'Enable all',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: model.tools.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tool = model.tools[index];
                        final selected =
                            model.selectedToolIds.contains(tool.id);
                        return SwitchListTile(
                          value: selected,
                          onChanged: (_) => model.toggleToolSelection(tool.id),
                          title: Text(tool.name),
                          subtitle: tool.description.isEmpty
                              ? Text(tool.id)
                              : Text(tool.description),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              'images/app_icon.png',
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
                if (viewModel.isLoggedIn) {
                  await Future.wait([
                    viewModel.fetchChats(),
                    viewModel.fetchTools(),
                  ]);
                }
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
    );
  }
}
