import 'package:domain/auth/entities/user.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import '../../auth/login_page.dart';
import '../../conponents/base64-image.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'message_list.dart';
import 'chat_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with
        AutomaticKeepAliveClientMixin,
        RouteAware,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  /// Empty-state suggestion chips: matches Card shape + InkWell ripple.
  static const double _kSuggestionChipRadius = 18;

  @override
  bool get wantKeepAlive => true;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final FocusNode _sendShortcutFocusNode = FocusNode();

  late ChatViewModel viewModel;

  // Voice input
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sendShortcutFocusNode.dispose();
    focusNode.dispose();
    textController.dispose();
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        textController.text = result.recognizedWords;
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length),
        );
        setState(() {});
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
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
              children: const [
                Text(
                  "How can I help you today?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
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
    final hPad = context.horizontalSidePaddingForContentWidth;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        hPad,
        0,
        hPad,
        bottomInset > 0 ? bottomInset : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPendingFiles(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyboardListener(
                  focusNode: _sendShortcutFocusNode,
                  onKeyEvent: _handleComposerKeyEvent,
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 8,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAttachButton(),
                    if (viewModel.isAdmin) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            _buildAdminIndicator(),
                            if (viewModel.shouldShowModelSelector) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: viewModel.canSelectModels
                                    ? _buildModelPickerButton()
                                    : _buildModelLoadingChip(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: 8),
                    _buildRightButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComposerKeyEvent(KeyEvent event) async {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return;
    }

    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.shiftLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.shiftRight);
    if (isShiftPressed) {
      final text = textController.text;
      textController.text = "$text\n";
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
      return;
    }

    if (!viewModel.isSendingMessage) {
      final text = textController.text.trim();
      if (text.isNotEmpty || viewModel.pendingFiles.isNotEmpty) {
        if (await viewModel.reachChatLimit()) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily chat limit reached (50/day)'),
            ),
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

  bool _canSendMessage() {
    return !viewModel.isSendingMessage &&
        !viewModel.isUploadingFile &&
        (textController.text.trim().isNotEmpty ||
            viewModel.pendingFiles.isNotEmpty);
  }

  Widget _buildAdminIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7B5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 16,
            color: Color(0xFFC65F1A),
          ),
          SizedBox(width: 4),
          Text(
            'Admin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC65F1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelPickerButton() {
    final selectedModel = viewModel.selectedModel;
    final label = selectedModel?.name ?? 'Select model';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: viewModel.isSendingMessage ? null : _showModelPickerSheet,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelLoadingChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Models',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightButton() {
    if (viewModel.isSendingMessage) {
      return const SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_isListening) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: _stopListening,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
          ),
        ),
      );
    }
    if (_canSendMessage()) {
      return GestureDetector(
        onTap: () {
          final text = textController.text.trim();
          textController.clear();
          viewModel.sendInputMessage(text);
        },
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_upward_rounded,
              color: Colors.white, size: 20),
        ),
      );
    }
    return GestureDetector(
      onTap: viewModel.isUploadingFile ? null : _startListening,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
        ),
        child: Icon(Icons.mic_none, size: 18, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildAttachButton() {
    return GestureDetector(
      onTap: viewModel.isUploadingFile || viewModel.isSendingMessage
          ? null
          : _showAttachmentSheet,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
        ),
        child: viewModel.isUploadingFile
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.add, size: 20, color: Colors.grey.shade700),
      ),
    );
  }

  void _showModelPickerSheet() {
    final models = List<ChatModel>.from(viewModel.models);
    final selectedId = viewModel.selectedModel?.id;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select model',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: models.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey.shade300,
                      ),
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final isSelected = model.id == selectedId;
                        final showId = model.id != model.name;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(
                            model.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: showId
                              ? Text(
                                  model.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.blue,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            viewModel.selectModel(model);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickAndUploadImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickAndUploadImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Files'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickAndUploadFiles();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static bool _isImageFile(ChatFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'}.contains(ext);
  }

  Widget _buildPendingFiles() {
    if (viewModel.pendingFiles.isEmpty) return const SizedBox.shrink();

    final images = viewModel.pendingFiles.where(_isImageFile).toList();
    final files =
        viewModel.pendingFiles.where((f) => !_isImageFile(f)).toList();

    return Container(
      width: context.contentWidth,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _buildPendingImageThumb(images[i]),
              ),
            ),
          if (images.isNotEmpty && files.isNotEmpty) const SizedBox(height: 6),
          if (files.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: files
                  .map((file) => InputChip(
                        avatar: const Icon(Icons.insert_drive_file_outlined,
                            size: 18),
                        label: Text(file.name, overflow: TextOverflow.ellipsis),
                        onDeleted: viewModel.isSendingMessage
                            ? null
                            : () => viewModel.removePendingFile(file),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingImageThumb(ChatFile file) {
    final bytes = viewModel.pendingImageBytes[file.id];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.image_outlined, size: 32)),
          ),
        ),
        if (!viewModel.isSendingMessage)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => viewModel.removePendingFile(file),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
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
