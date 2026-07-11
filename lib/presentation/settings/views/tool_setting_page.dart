import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

class ToolSettingPage extends StatefulWidget {
  const ToolSettingPage({super.key});

  @override
  _ToolSettingPageState createState() => _ToolSettingPageState();
}

class _ToolSettingPageState extends State<ToolSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Tools'),
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, chat, _) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: context.horizontalSidePaddingForContentWidth),
            children: [
              const SizedBox(height: 10),
              if (chat.tools.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chat Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final enableAll =
                              chat.selectedToolIds.length != chat.tools.length;
                          chat.setAllToolsEnabled(enableAll);
                        },
                        child: Text(
                          chat.selectedToolIds.length == chat.tools.length
                              ? 'Disable all'
                              : 'Enable all',
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(chat.tools.length, (i) {
                  final tool = chat.tools[i];
                  final selected = chat.selectedToolIds.contains(tool.id);
                  return SwitchListTile(
                    value: selected,
                    onChanged: (_) => chat.toggleToolSelection(tool.id),
                    title: Text(tool.name),
                    subtitle: tool.description.isEmpty
                        ? Text(tool.id)
                        : Text(tool.description),
                  );
                }),
              ],
              if (chat.isLoadingTools)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!chat.isLoadingTools && chat.tools.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No chat tools available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
