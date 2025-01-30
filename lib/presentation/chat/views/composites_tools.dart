import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../../settings/views/apply_expert_page.dart';
import '../../settings/views/login_page.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'composites_tool_creation.dart';
import '../viewModels/composites_tools_view_model.dart';

class CompositesTools extends StatefulWidget {
  @override
  State<CompositesTools> createState() => _CompositesToolsState();
}

class _CompositesToolsState extends State<CompositesTools> {
  final Set<int> hoveredIndexes = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      await viewModel.getAllTools(); // Fetch tools after the widget is initialized
    });
  }

  void _showExpertDialog({required String message, String? actionLabel, VoidCallback? onAction}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Access Restricted'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
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
                            );
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
                            );
                          },
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChangeNotifierProvider(
                                  create: (_) =>
                                      CompositesToolsViewModel(
                                        toolUseCase: sl(),
                                        user: viewModel.user!,
                                      ),
                                  child: CompositesToolCreation(),
                                ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      elevation: 4, // Default elevation
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
                    child: const Text(
                      '+ Contribute',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () async {
                      String? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(user: viewModel.user),
                        ),
                      );
                      if (result == "refresh") {
                        await viewModel.checkAuthStatus();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
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
                        if (viewModel.user?.isCompositeExpert == true)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
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
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.tools == null || viewModel.tools!.isEmpty) {
            return const Center(child: Text("No tools found"));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        "Featured Tools",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 1,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                          childAspectRatio: 1.7,
                        ),
                        itemCount: viewModel.tools!.length,
                        itemBuilder: (context, index) {
                          final tool = viewModel.tools![index];
                          final isHovered = hoveredIndexes.contains(index);

                          return InkWell(
                            onTap: () {},
                            onHover: (hovering) {
                              setState(() {
                                if (hovering) {
                                  hoveredIndexes.add(index); // Add to hovered state
                                } else {
                                  hoveredIndexes.remove(index); // Remove from hovered state
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isHovered ? Colors.teal.shade300 : Colors.teal.shade500,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: isHovered
                                    ? [BoxShadow(color: Colors.black26, blurRadius: 8.0, spreadRadius: 2.0)]
                                    : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: tool.toolAvatar != null
                                          ? NetworkImage(tool.toolAvatar!)
                                          : null,
                                      child: tool.toolAvatar == null
                                          ? const Icon(Icons.account_circle, size: 45, color: Colors.blue)
                                          : null,
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      tool.title.isNotEmpty ? tool.title : "Not available",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Expanded(
                                      child: Text(
                                        tool.description?.isNotEmpty == true ? tool.description! : "",
                                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Expanded(
                                      child: Text(
                                        tool.instructions?.isNotEmpty == true ? tool.instructions! : "",
                                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      "By ${tool.userName ?? "Unknown user"}",
                                      style: const TextStyle(fontSize: 14, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}