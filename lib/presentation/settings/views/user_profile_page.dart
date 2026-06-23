import 'package:domain/auth/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/update_name_page.dart';
import 'package:swiftcomp/presentation/auth/update_password.dart';
import '../../../app/injection_container.dart';
import '../../chat/viewModels/chat_view_model.dart';
import '../../conponents/base64-image.dart';
import '../viewModels/settings_view_model.dart';
import '../viewModels/user_profile_view_model.dart';

class UserProfilePage extends StatelessWidget {
  final User? user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileViewModel(
          authUseCase: sl(), userUseCase: sl(), user: user),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Consumer<UserProfileViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: [
                _buildHeader(context, viewModel),
                const SizedBox(height: 8),
                _buildSection(context, [
                  _buildRow(
                    context,
                    icon: Icons.person_outline,
                    label: 'Change Name',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateNamePage(
                            currentName: viewModel.user?.name ?? '',
                          ),
                        ),
                      );
                      if (result == 'refresh') await viewModel.fetchUser();
                    },
                  ),
                  _buildDivider(),
                  _buildRow(
                    context,
                    icon: Icons.lock_outline,
                    label: 'Update Password',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UpdatePasswordPage()),
                      );
                      if (result == 'password_updated') {
                        await viewModel.fetchUser();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password updated successfully')),
                        );
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection(context, [
                  _buildRow(
                    context,
                    icon: Icons.logout,
                    label: 'Sign Out',
                    color: Colors.red.shade600,
                    onTap: () async {
                      final ok = await viewModel.logoutUser(context);
                      if (!context.mounted) return;
                      if (ok) {
                        await context
                            .read<ChatViewModel>()
                            .clearChatStateOnLogout();
                        if (!context.mounted) return;
                        Navigator.of(context).pop('refresh');
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildRow(
                    context,
                    icon: Icons.delete_outline,
                    label: 'Delete Account',
                    color: Colors.red.shade600,
                    onTap: () => _confirmDeleteUser(context, viewModel),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfileViewModel viewModel) {
    final name = viewModel.user?.name ?? '';
    final email = viewModel.user?.email ?? '';
    final isExpert = viewModel.user?.isCompositeExpert == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              viewModel.user?.avatarUrl != null
                  ? CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: SizedBox.square(
                          dimension: 88,
                          child: Base64Image(viewModel.user!.avatarUrl!),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                    ),
              if (isExpert)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified,
                      color: Colors.blue, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (name.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (name.isNotEmpty) const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: effectiveColor,
                ),
              ),
            ),
            if (color == null)
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 0,
      color: Colors.grey.shade200,
    );
  }

  void _confirmDeleteUser(
      BuildContext context, UserProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account'),
          content: const Text(
              'This will permanently delete your account and all associated data. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final settingsViewModel = context.read<SettingsViewModel>();
                final chatViewModel = context.read<ChatViewModel>();
                Navigator.of(dialogContext).pop();

                final deleted = await viewModel.deleteUser();
                if (!context.mounted) return;

                if (!deleted || viewModel.errorMessage != null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Error'),
                      content: Text(viewModel.errorMessage ?? 'Delete failed'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  await settingsViewModel.fetchAuthSessionNew();
                  await chatViewModel.fetchAuthSessionNew();
                  await chatViewModel.clearChatStateOnLogout();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully.'),
                      duration: Duration(milliseconds: 800),
                      backgroundColor: Colors.black,
                    ),
                  );
                  Navigator.of(context).pop('refresh');
                }
              },
              child: Text('Delete',
                  style: TextStyle(color: Colors.red.shade600)),
            ),
          ],
        );
      },
    );
  }
}
