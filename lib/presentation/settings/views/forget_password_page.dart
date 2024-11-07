import 'dart:html';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../util/string_util.dart';
import '../login/login_button.dart';
import '../login/login_input.dart';
import '../viewModels/forget_password_view_model.dart'; // Adjust the import path as necessary
import '../../../injection_container.dart'; // Import your service locator to inject dependencies

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmationCodeController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isEmailValid = false;

  String? newPassword;
  String? confirmCode;
  bool confirmEnable = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text;
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (isValid != isEmailValid) {
      setState(() {
        isEmailValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ForgetPasswordViewModel>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Reset Password"),
          backgroundColor: Color(0xFF33424E),
        ),
        body: Consumer<ForgetPasswordViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Input Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "Input Email",
                        border: UnderlineInputBorder(),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB71C1C)),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB71C1C)),
                        ),
                        errorStyle: TextStyle(color: Color(0xFFB71C1C)),
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

                    // New Password Field
                    if (viewModel.isPasswordResetting)
                      TextFormField(
                        obscureText: viewModel.obscureTextNewPassword,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          hintText: "Input new password",
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
                              viewModel.obscureTextNewPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: viewModel.toggleNewPasswordVisibility,
                          ),
                        ),
                        onChanged: (text) {
                          newPassword = text;
                          checkConfirmInput();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),

                    // Confirm Password Field
                    if (viewModel.isPasswordResetting)
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: viewModel.obscureTextConfirmPassword,
                        decoration: InputDecoration(
                          labelText: "Re-enter Password",
                          hintText: "Re-enter password",
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
                              viewModel.obscureTextConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: viewModel.toggleConfirmPasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please re-enter your password';
                          }
                          if (value != newPassword) {
                            return "Passwords don't match";
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),

                    // Confirmation Message
                    if (viewModel.isPasswordResetting)
                      Text(
                        "An email confirmation code is sent to ${_emailController.text}. Please type the code to confirm your email.",
                        style: Theme.of(context).textTheme.bodyText2,
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 20),

                    // Confirmation Code Input
                    if (viewModel.isPasswordResetting)
                      TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _confirmationCodeController,
                        decoration: InputDecoration(
                          labelText: "Confirmation Code",
                          border: UnderlineInputBorder(),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                        ),
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return "The confirmation code is invalid";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          confirmCode = value;
                          checkConfirmInput();
                        },
                      ),
                    SizedBox(height: 20),

                    // Confirm Button
                    if (viewModel.isPasswordResetting)
                      LoginButton(
                        'Confirm',
                        enable: confirmEnable,
                        onPressed: () async {
                          await viewModel.confirmResetPassword(
                              _emailController.text, newPassword, confirmCode);
                          if (viewModel.errorMessage.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to reset password: ${viewModel.errorMessage}.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Password reset successful!")),
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),

                    // Reset Password Button
                    if (!viewModel.isPasswordResetting)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0), // Adjust top padding here
                        child: MaterialButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    await viewModel.forgetPassword(_emailController.text);

                                    if (viewModel.errorMessage.isNotEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to send confirmation code.'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          height: 45,
                          minWidth: double.infinity,
                          color: isEmailValid ? Color(0xFF33424E) : Color(0xFF8C9699),
                          disabledColor: Color(0xFF8C9699),
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
    super.dispose();
  }

  void checkConfirmInput() {
    setState(() {
      confirmEnable = _emailController.text.isNotEmpty &&
          (newPassword?.isNotEmpty ?? false) &&
          (newPassword?.length ?? 0) >= 6 &&
          _confirmPasswordController.text == newPassword &&
          (confirmCode?.isNotEmpty ?? false) &&
          (confirmCode?.length ?? 0) == 6;
    });
  }
}
