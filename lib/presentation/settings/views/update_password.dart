import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/update_password_view_model.dart';

import '../../../injection_container.dart';
import '../viewModels/user_profile_view_model.dart';

class UpdatePasswordPage extends StatefulWidget {
  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isNewPasswordValid = false;
  String? newPassword;
  String? confirmCode;
  bool confirmEnable = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void checkConfirmInput() {
    setState(() {
      confirmEnable = (_newPasswordController.text.isNotEmpty) &&
          (_newPasswordController.text.length >= 6) &&
          _confirmPasswordController.text == _newPasswordController.text;
    });
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => sl<UpdatePasswordViewModel>(),
        child: Consumer<UpdatePasswordViewModel>(builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Update Password')),
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: "Enter new password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            viewModel.obscureTextNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: viewModel.toggleNewPasswordVisibility,
                        ),
                      ),
                      obscureText: viewModel.obscureTextNewPassword,
                      onChanged: (text) {
                        newPassword = text;
                        setState(() {
                          isNewPasswordValid = newPassword!.length >= 6;
                        });
                        checkConfirmInput();
                      },
                    ),
                    SizedBox(height: 4.0),

                    // Message aligned with the New Password input field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: Text(
                          isNewPasswordValid ? '' : 'Password must be at least 6 characters long',
                          style: TextStyle(
                            color: isNewPasswordValid ? Colors.transparent : Colors.black54,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                          hintText: "Re-enter your password",
                          border: UnderlineInputBorder(),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              viewModel.obscureTextConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: viewModel.toggleConfirmPasswordVisibility,
                          )
                      ),
                      obscureText: viewModel.obscureTextConfirmPassword,
                      onChanged: (text) {
                        checkConfirmInput(); // Call this to update button state
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPasswordController.text) {
                          return "The passwords do not match";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.0),
                    viewModel.isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: confirmEnable
                          ? () async {
                        if (_formKey.currentState!.validate()) {
                          await _updatePassword(viewModel);
                        }
                      }
                          : null, // Disable button if confirmEnable is false
                      child: Text('Update Password'),
                    ),

                  ],
                ),
              ),
            ),
          );
        }));
  }

  Future<void> _updatePassword(UpdatePasswordViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      // If the form validation fails, return immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Form validation failed")),
      );
    }

      // Access the view model and update the user's password
    await viewModel.updatePassword(_newPasswordController.text);
    if (viewModel.errorMessage.isNotEmpty) {
      // Show error message if update fails and return error string
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    } else {
      Navigator.pop(context, 'refresh');
    }
  }
}
