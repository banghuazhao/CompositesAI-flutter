import 'package:cached_network_image/cached_network_image.dart';
import 'package:domain/entities/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/update_name_page.dart';
import 'package:swiftcomp/presentation/auth/update_password.dart';
import '../../../app/injection_container.dart';
import '../../conponents/base64-image.dart';
import '../viewModels/user_profile_view_model.dart';

class UserProfilePage extends StatelessWidget {
  User? user;

  UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(//Creates the UserProfileViewModel object. 2.Makes it available to the page and any widgets below it in the widget tree.
      create: (_) => UserProfileViewModel(authUseCase: sl(), userUseCase: sl(), user: user),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("User Profile"),
          backgroundColor: Colors.grey.shade800,
          elevation: 4.0,
        ),
        body: Consumer<UserProfileViewModel>(//The page accesses the ViewModel through a Consumer
          builder: (context, viewModel, _) {
            return viewModel.isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width, // 50% of the screen width
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              viewModel.user?.avatarUrl != null
                                  ? CircleAvatar(
                                radius: 27.5, // Adjust the radius to match the icon size
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: Base64Image(viewModel.user!.avatarUrl!)
                                ),
                              )
                                  : const Icon(
                                Icons.account_circle,
                                size: 55,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        viewModel.user?.name ?? "",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (viewModel.user?.isCompositeExpert == true) // Check if the user is verified
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0), // Add spacing between name and icon
                                          child: Icon(
                                            Icons.verified, // Use a verified checkmark icon
                                            color: Colors.blue, // Make it blue to represent verification
                                            size: 16, // Adjust the size to fit nicely
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 8),
                                  Text(
                                    viewModel.user?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueGrey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateNamePage(
                            currentName: viewModel.user?.name ?? "",
                          ),
                        ),
                      );
                      if (result == 'refresh') {
                        await viewModel.fetchUser();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6, // Controls the shadow strength
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: Text(
                      "Change Name",
                      style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w500,),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdatePasswordPage(),
                        ),
                      );
                      if (result == 'password_updated') {
                        await viewModel.fetchUser();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated successfully')),
                        );
                      }

                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6, // Controls the shadow strength
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: Text(
                      "Update Password",
                      style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w500,),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      await viewModel.logoutUser(context);
                      Navigator.of(context).pop("refresh");
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6, // Controls the shadow strength
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: Text(
                      "Logout",
                      style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w500,),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _confirmDeleteUser(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6, // Controls the shadow strength
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: Text(
                      "Delete Account",
                      style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500,),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  void _confirmDeleteUser(BuildContext context, UserProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog first

                await viewModel.deleteUser();

                if (!context.mounted) return; // Exit if widget is unmounted

                if (viewModel.errorMessage != null) {
                  // Show error dialog if an error occurred
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Error"),
                      content: Text(viewModel.errorMessage!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Navigate back with "refresh" if no error
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
