import 'package:domain/auth/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/qa_settings_page.dart';
import 'package:swiftcomp/presentation/settings/views/admin_model_tool_page.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';
import 'package:swiftcomp/util/app_colors.dart';
import 'package:swiftcomp/util/app_interactions.dart';
import 'package:swiftcomp/util/app_theme.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import '../../chat/viewModels/chat_view_model.dart';
import '../../conponents/base64-image.dart';
import '../viewModels/settings_view_model.dart';
import 'apply_expert_page.dart';
import '../../auth/login_page.dart';
import 'expert_requests_page.dart';
import 'result_precision_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Account & Settings')),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
            children: [
              _buildSectionLabel('Account'),
              const SizedBox(height: 6),
              if (viewModel.isLoading)
                _buildSection([
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ])
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
                        if (!context.mounted) return;
                        final chat = context.read<ChatViewModel>();
                        await chat.checkAuthStatus();
                        if (!context.mounted) return;
                        if (chat.isLoggedIn) await chat.fetchChats();
                      }
                    },
                  ),
                ]),
              if (viewModel.isLoggedIn &&
                  !viewModel.isExpert &&
                  !viewModel.isAdmin) ...[
                const SizedBox(height: 12),
                _buildSection([
                  _buildTile(
                    icon: Icons.workspace_premium_outlined,
                    title: _expertRequestTitle(viewModel),
                    subtitle: _expertRequestSubtitle(viewModel),
                    trailing: viewModel.isLoadingExpertRequestMetadata
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _canOpenExpertRequest(viewModel)
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ApplyExpertPage()),
                            );
                            await viewModel.refreshExpertRequestMetadata();
                          }
                        : () => _showExpertRequestStatus(context, viewModel),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              _buildSectionLabel('Composite Calculators'),
              const SizedBox(height: 6),
              _buildSection([
                _buildTile(
                  icon: Icons.calculate_outlined,
                  title: 'Composite Calculators',
                  subtitle: 'Open the engineering calculation toolkit.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ToolPage()),
                  ),
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.pin_outlined,
                  title: 'Result Precision',
                  subtitle: 'Set numeric precision for calculator results.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ResultPrecisionPage()),
                  ),
                ),
              ]),
              if (viewModel.isAdmin) ...[
                const SizedBox(height: 24),
                _buildSectionLabel('Admin'),
                const SizedBox(height: 6),
                _buildSection([
                  _buildTile(
                    icon: Icons.memory_rounded,
                    title: 'Model Management',
                    subtitle: 'Edit models and choose tools for each model.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminModelManagementPage(),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildTile(
                    icon: Icons.build_outlined,
                    title: 'Tool Management',
                    subtitle: 'Create and edit the admin tool catalog.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminToolManagementPage(),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Expert Requests',
                    trailing: _buildExpertRequestBadge(viewModel),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpertRequestsPage(),
                        ),
                      );
                      await viewModel.refreshExpertRequestMetadata();
                    },
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              _buildSectionLabel('Support'),
              const SizedBox(height: 6),
              _buildSection([
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    final name = viewModel.user?.name ?? '';
    final email = viewModel.user?.email ?? '';
    final isExpert = viewModel.user?.isCompositeExpert == true;
    final isAdmin = viewModel.user?.isAdmin == true;

    return _buildSection([
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          AppHaptics.light();
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(user: viewModel.user),
            ),
          );
          await _refresh();
          if (!context.mounted) return;
          if (result == 'refresh') Navigator.pop(context, 'refresh');
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
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified,
                                color: scheme.primary, size: 16),
                          ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          _buildAdminBadge(),
                        ],
                      ],
                    ),
                    if (name.isNotEmpty && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 13,
            color: AppColors.warning,
          ),
          SizedBox(width: 3),
          Text(
            'Admin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertRequestBadge(SettingsViewModel viewModel) {
    if (viewModel.isLoadingExpertRequestMetadata) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final count = viewModel.pendingExpertRequestCount;
    if (count <= 0) {
      return Text(
        'None',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  String _expertRequestTitle(SettingsViewModel viewModel) {
    final status = viewModel.currentExpertRequest?.status;
    switch (status) {
      case 'pending':
        return 'Expert Request Pending';
      case 'approved':
        return 'Expert Request Approved';
      case 'denied':
        return 'Request to Become an Expert';
      default:
        return 'Request to Become an Expert';
    }
  }

  String? _expertRequestSubtitle(SettingsViewModel viewModel) {
    if (viewModel.isLoadingExpertRequestMetadata) {
      return 'Checking your request status...';
    }

    final status = viewModel.currentExpertRequest?.status;
    switch (status) {
      case 'pending':
        return 'Your application is waiting for admin review.';
      case 'approved':
        return 'Your application was approved. Refresh your account if the expert badge is not visible yet.';
      case 'denied':
        return 'Your previous request was denied. You can submit a new request.';
      default:
        return 'Apply for expert access and review permissions.';
    }
  }

  bool _canOpenExpertRequest(SettingsViewModel viewModel) {
    final status = viewModel.currentExpertRequest?.status;
    return !viewModel.isLoadingExpertRequestMetadata &&
        status != 'pending' &&
        status != 'approved';
  }

  void _showExpertRequestStatus(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final message = _expertRequestSubtitle(viewModel) ??
        'Your expert request is already being reviewed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildAvatar(SettingsViewModel viewModel) {
    final scheme = Theme.of(context).colorScheme;
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
      backgroundColor: scheme.surfaceContainerHighest,
      child:
          Icon(Icons.person, size: size * 0.55, color: scheme.onSurfaceVariant),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface;
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: c)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 52);
}
