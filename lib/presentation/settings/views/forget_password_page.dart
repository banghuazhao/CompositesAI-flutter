import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../login/login_button.dart';
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
  bool isNewPasswordValid = false;

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
                          return 'Please enter your email address to receive a confirmation code to reset your password.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address to receive a confirmation code to reset your password.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // New Password Field
                    if (viewModel.isPasswordResetting)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            obscureText: viewModel.obscureTextNewPassword,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              hintText: "Enter new password",
                              border: UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.obscureTextNewPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: viewModel.toggleNewPasswordVisibility,
                              ),
                            ),
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
                          SizedBox(height: 18),
                        ],
                      ),

                    // Confirm Password Field
                    if (viewModel.isPasswordResetting)
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: viewModel.obscureTextConfirmPassword,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
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
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != newPassword) {
                            return "The passwords do not match";
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),

                    // Confirmation Message
                    if (viewModel.isPasswordResetting)
                      Text(
                        "A confirmation code has been sent to ${_emailController.text}. Please enter the code to verify your email address.",
                        style: Theme.of(context).textTheme.bodyText2,
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 18),

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
                            return "Please enter a valid confirmation code to proceed";
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
                        'Reset',
                        enable: confirmEnable,
                        onPressed: () async {
                          await viewModel.confirmResetPassword(
                              _emailController.text, newPassword, confirmCode);
                          if (viewModel.errorMessage.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reset password: ${viewModel.errorMessage}.'),
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
