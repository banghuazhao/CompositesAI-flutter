
import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../viewModels/manage_composite_experts_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageCompositeExpertsPage extends StatefulWidget {
  const ManageCompositeExpertsPage({Key? key}) : super(key: key);


  @override
  _ManageCompositeExpertsPageState createState() => _ManageCompositeExpertsPageState();
}

class _ManageCompositeExpertsPageState extends State<ManageCompositeExpertsPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<ManageCompositeExpertsViewModel>(context, listen: false);
      await viewModel.getAllApplications();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Applications Management")),
        body: Consumer<ManageCompositeExpertsViewModel>(builder: (context, viewModel, child) {
          return Padding(
              padding: const EdgeInsets.all(16.0),
              child: viewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : viewModel.applications!.isEmpty
                      ? Center(child: Text("No applications found"))
                      : ListView.builder(
                          itemCount: viewModel.applications?.length,
                          itemBuilder: (context, index) {
                            final application = viewModel.applications?[index];
                            final Future<User> userFuture =
                            viewModel.getUserById(application!.userId);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0), // Add padding around the content
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Reason: ${application?.reason?.isNotEmpty == true ? application?.reason : "Not available"}", ),
                                    application?.link?.isNotEmpty == true
                                        ? GestureDetector(
                                      onTap: () async {
                                        final Uri uri = Uri.parse(application!.link!);
                                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                          throw 'Could not launch ${application.link}';
                                        }
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: "Profile Link: ", // The first part with black color
                                          style: const TextStyle(color: Colors.black), // Style for "Profile Link:"
                                          children: [
                                            TextSpan(
                                              text: application.link, // The link with blue color
                                              style: const TextStyle(color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                      )
                                    )
                                        : const Text("Profile Link: Not available"),

                                    FutureBuilder<User>(
                                      future: userFuture, // Call your function
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text("Loading user details...");
                                        } else if (snapshot.hasError) {
                                          return const Text("Failed to load user details");
                                        } else if (snapshot.hasData) {
                                          final user = snapshot.data!;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Name: ${user.name}"),
                                              Text("Email: ${user.email}"),
                                            ],
                                          );
                                        } else {
                                          return const Text("No user details available");
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8.0), // Space between text and buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            await viewModel.approveExpert(application.userId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            minimumSize: const Size(80, 30), // Smaller button size
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          child: const Text(
                                            "Approve",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0), // Space between buttons
                                        ElevatedButton(
                                          onPressed: () async {
                                            await viewModel.disapproveExpert(application.userId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white54,
                                            minimumSize: const Size(80, 30), // Smaller button size
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          child: const Text(
                                            "Disapprove",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );

                          },
                        ));
        }));
  }
}
