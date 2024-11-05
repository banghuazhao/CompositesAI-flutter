import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../injection_container.dart';
import '../viewModels/reset_password_view_model.dart';

class ResetPasswordPage extends StatelessWidget {
  final String token;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ResetPasswordPage({required this.token});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = sl<ResetPasswordViewModel>();
        Future.microtask(
                () => viewModel.verifyToken(token)); // Call verifyToken on load
        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Reset Password"),
          backgroundColor: Color(0xFF33424E), // Customize the AppBar color as needed
        ),
        body: Consumer<ResetPasswordViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage.isNotEmpty) {
              return Center(
                child: Text(
                  viewModel.errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              );
            }

            if (viewModel.isTokenValid) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // New Password Input Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          hintText: "Enter new password",
                          border: UnderlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Reset Password Button
                      MaterialButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final message = await viewModel.resetPassword(
                              token,
                              _passwordController.text,
                            );

                            if (message != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                              Navigator.pop(context); // Go back after successful reset
                            }
                          }
                        },
                        height: 45,
                        minWidth: double.infinity,
                        color: Color.fromRGBO(150, 150, 150, 1),
                        disabledColor: Color.fromRGBO(150, 150, 150, 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // Rounded corners
                        ),
                        child: Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),

                      // Error Message
                      if (viewModel.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            viewModel.errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ElevatedButton(
                onPressed: () => viewModel.verifyToken(token),
                child: Text("Verify Token"),
              ),
            );
          },
        ),
      ),
    );
  }


}