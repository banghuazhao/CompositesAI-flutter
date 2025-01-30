

import 'package:domain/entities/tool_creation_requests.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chat/viewModels/composites_tools_view_model.dart';

class ToolCreationRequestPage extends StatefulWidget {
  @override
  _ToolCreationRequestState createState() => _ToolCreationRequestState();//createState() gives the widget a "brain" (state). The state works behind the scenes to store changes and make the widget dynamic.

//_ToolCreationRequestState() is a constructor for the _ToolCreationRequestState class
}

class _ToolCreationRequestState extends State<ToolCreationRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<CompositesToolsViewModel>(context, listen: false);
      await viewModel.getAllRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Composites Tool Creation Requests")),
        body: Consumer<CompositesToolsViewModel>(builder: (context, viewModel, child) {
          return Padding(
              padding: const EdgeInsets.all(16.0),
              child: viewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : viewModel.requests!.isEmpty
                  ? Center(child: Text("No requests found"))
                  : ListView.builder(
                itemCount: viewModel.requests.length,
                itemBuilder: (context, index) {
                  final request = viewModel.requests?[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Add padding around the content
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User Id: ${request?.userId}", ),
                          Text("User Name: ${request?.userName}"),
                          Text("Title: ${request?.title.isNotEmpty == true ? request?.title : "Not available"}", ),
                          Text("Description: ${request?.description?.isNotEmpty == true ? request?.description : "Not available"}", ),
                          Text("Instructions: ${request?.instructions?.isNotEmpty == true ? request?.instructions : "Not available"}", ),
                          request?.fileUrl.isNotEmpty == true
                              ? GestureDetector(
                              onTap: () async {
                                final Uri uri = Uri.parse(request!.fileUrl!);
                                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                  throw 'Could not launch ${request.fileUrl}';
                                }
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "File Link: ", // The first part with black color
                                  style: const TextStyle(color: Colors.black), // Style for "Profile Link:"
                                  children: const [
                                    TextSpan(
                                      text: "Click here", // Display friendly text for the link
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline, // Add underline to emphasize it's a link
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          )
                              : const Text("File Link: Not available"),

                          const SizedBox(height: 8.0), // Space between text and buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await viewModel.approveRequest(request!.id);
                                  await viewModel.getAllRequests();
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
                                  await viewModel.deleteRequest(request!.id);
                                  await viewModel.getAllRequests();
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
