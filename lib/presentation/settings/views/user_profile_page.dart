import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../injection_container.dart';
import '../viewModels/user_profile_view_model.dart';

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<UserProfileViewModel>(),
      child: Scaffold(
        appBar: AppBar(title: const Text("User Profile")),
        body: Consumer<UserProfileViewModel>(
          builder: (context, viewModel, _) {
            return viewModel.isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${viewModel.user?.username ?? ''}",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Email: ${viewModel.user?.email ?? ''}",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await viewModel.logoutUser();
                            Navigator.of(context).pop("refresh");
                          },
                          child: Text("Logout"),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _confirmDeleteUser(context, viewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text("Delete Account"),
                        ),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  void _confirmDeleteUser(
      BuildContext context, UserProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog first
                await viewModel.deleteUser();
                // Check if the widget is still mounted before navigating back
                if (context.mounted) {
                  Navigator.of(context).pop("refresh");
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
