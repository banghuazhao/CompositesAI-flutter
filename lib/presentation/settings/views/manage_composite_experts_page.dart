import 'package:domain/entities/application.dart';
import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../viewModels/manage_composite_experts_view_model.dart';

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
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text("Reason: ${application?.reason}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("User ID: ${application?.userId}"),
                                  ],
                                ),
                              ),
                            );
                          },
                        ));
        }));
  }
}
