import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

class ToolSettingPage extends StatefulWidget {
  const ToolSettingPage({super.key, this.showChatTools = true});

  final bool showChatTools;

  @override
  _ToolSettingPageState createState() => _ToolSettingPageState();
}

class _ToolSettingPageState extends State<ToolSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Settings),
      ),
      body: Consumer2<NumberPrecisionHelper, ChatViewModel>(
        builder: (context, precision, chat, _) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: context.horizontalSidePaddingForContentWidth),
            children: [
              const SizedBox(height: 10),
              ListTile(
                title: Text(S.of(context).Result_Precision),
                subtitle:
                    Text(123456789.toStringAsExponential(precision.precision)),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => setState(() {
                          if (precision.precision > 1) {
                            precision.set(precision.precision - 1);
                          }
                        }),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          precision.precision.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() {
                          if (precision.precision < 9) {
                            precision.set(precision.precision + 1);
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.showChatTools && chat.tools.isNotEmpty) ...[
                const Divider(height: 32),
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
              if (widget.showChatTools && chat.isLoadingTools)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
