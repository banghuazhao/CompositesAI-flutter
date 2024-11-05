import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/forget_password_view_model.dart'; // Adjust the import path as necessary
import '../../../injection_container.dart'; // Import your service locator to inject dependencies

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ForgetPasswordViewModel>(), // Use your service locator
      child: Scaffold(
        appBar: AppBar(
          title: Text("Forget Password"),
          backgroundColor: Color(0xFF33424E), // Customize the AppBar color as needed
        ),
        body: Consumer<ForgetPasswordViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 10),

                    // If password reset flow has started, show confirmation form
                    if (viewModel.isPasswordResetting) ...[
                      // New Password Input
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          hintText: "Input New Password",
                          border: UnderlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Confirmation Code Input
                      TextFormField(
                        controller: _confirmationCodeController,
                        decoration: InputDecoration(
                          labelText: "Confirmation Code",
                          hintText: "Input Code",
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'The confirmation code is invalid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Confirm Button
                      MaterialButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                          if (_formKey.currentState!.validate()) {
                            await viewModel.confirmPasswordReset(
                              _emailController.text,
                              _newPasswordController.text,
                              _confirmationCodeController.text,
                            );
                            if (viewModel.errorMessage.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password reset successful.'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        height: 45,
                        minWidth: double.infinity,
                        color: Color.fromRGBO(150, 150, 150, 1),
                        disabledColor: Color.fromRGBO(150, 150, 150, 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: viewModel.isLoading
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ] else ...[
                      // Email Input Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          hintText: "Input Email",
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Reset Password Button
                      MaterialButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                          if (_formKey.currentState!.validate()) {
                            await viewModel.forgetPassword(_emailController.text);
                            if (viewModel.errorMessage.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password reset email sent.'),
                                ),
                              );
                            }
                          }
                        },
                        height: 45,
                        minWidth: double.infinity,
                        color: Color.fromRGBO(150, 150, 150, 1),
                        disabledColor: Color.fromRGBO(150, 150, 150, 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: viewModel.isLoading
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text(
                          "Reset Password",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],

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
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }
}
