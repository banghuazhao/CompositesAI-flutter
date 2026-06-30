import 'package:domain/auth/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/qa_settings_page.dart';
import 'package:swiftcomp/presentation/settings/views/admin_model_tool_page.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import '../../chat/viewModels/chat_view_model.dart';
import '../../conponents/base64-image.dart';
import '../viewModels/settings_view_model.dart';
import 'apply_expert_page.dart';
import '../../auth/login_page.dart';
import 'tool_setting_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    viewModel.fetchAuthSessionNew();
  }

  Future<void> _refresh() => viewModel.fetchAuthSessionNew();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, _) {
        final hPad = context.horizontalSidePaddingForContentWidth;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
            children: [
              // ── Profile / Login ──────────────────────────────────────
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (viewModel.isLoggedIn)
                _buildProfileCard(context, viewModel)
              else
                _buildSection([
                  _buildTile(
                    icon: Icons.login_rounded,
                    title: 'Sign In',
                    onTap: () async {
                      final user = await Navigator.push<User>(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      if (user != null) {
                        viewModel.updateUser(user);
                        final chat = context.read<ChatViewModel>();
                        await chat.checkAuthStatus();
                        if (!context.mounted) return;
                        if (chat.isLoggedIn) await chat.fetchChats();
                      }
                    },
                  ),
                ]),

              const SizedBox(height: 24),

              // ── App section ──────────────────────────────────────────
              _buildSectionLabel('App'),
              const SizedBox(height: 6),
              _buildSection([
                _buildTile(
                  icon: Icons.settings_outlined,
                  title: 'Tools Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ToolSettingPage()),
                  ),
                ),
                if (viewModel.isAdmin) ...[
                  _buildDivider(),
                  _buildTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Model & Tool Management',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminModelToolPage(),
                      ),
                    ),
                  ),
                ],
                _buildDivider(),
                _buildTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Feedback',
                  onTap: viewModel.openFeedback,
                ),
                if (!kIsWeb) ...[
                  _buildDivider(),
                  _buildTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate this App',
                    onTap: viewModel.rateApp,
                  ),
                ],
                _buildDivider(),
                _buildTile(
                  icon: Icons.share_outlined,
                  title: kIsWeb ? 'Share this Website' : 'Share this App',
                  onTap: () {
                    viewModel.shareApp(context);
                    if (kIsWeb) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'https://compositesai.com copied to Clipboard')),
                      );
                    }
                  },
                ),
              ]),

              // ── Account section (expert apply) ───────────────────────
              if (viewModel.isLoggedIn && !viewModel.isExpert) ...[
                const SizedBox(height: 24),
                _buildSectionLabel('Account'),
                const SizedBox(height: 6),
                _buildSection([
                  _buildTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Request to Become an Expert',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ApplyExpertPage()),
                      );
                    },
                  ),
                ]),
              ],

              // ── Version ──────────────────────────────────────────────
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => viewModel.handleTap(() async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QASettingsPage()),
                  );
                  viewModel.fetchAuthSessionNew();
                }),
                child: Center(
                  child: Text(
                    'Version ${viewModel.version}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Profile header card ────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, SettingsViewModel viewModel) {
    final name = viewModel.user?.name ?? '';
    final email = viewModel.user?.email ?? '';
    final isExpert = viewModel.user?.isCompositeExpert == true;

    return _buildSection([
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(user: viewModel.user),
            ),
          );
          await _refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildAvatar(viewModel),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.isNotEmpty ? name : email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExpert)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified,
                                color: Colors.blue, size: 16),
                          ),
                      ],
                    ),
                    if (name.isNotEmpty && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildAvatar(SettingsViewModel viewModel) {
    const double size = 44;
    if (viewModel.user?.avatarUrl != null) {
      return ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: Base64Image(viewModel.user!.avatarUrl!),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: size * 0.55, color: Colors.grey.shade500),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, color: c)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 52, color: Colors.grey.shade200);
}
