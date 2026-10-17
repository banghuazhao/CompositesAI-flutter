import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'widgets/login_button.dart';
import 'forget_password_view_model.dart'; // Adjust the import path as necessary
import '../../app/injection_container.dart'; // Import your service locator to inject dependencies

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmationCodeController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();
  bool isEmailValid = false;

  String? newPassword;
  String? confirmCode;
  bool confirmEnable = false;
  bool isNewPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(
        _validateEmail); //these functions to automatically run whenever the text in the associated input field changes
    _newPasswordController.addListener(
        checkConfirmInput); //these functions to automatically run whenever the text in the associated input field changes
    _confirmPasswordController.addListener(checkConfirmInput);
    _confirmationCodeController.addListener(checkConfirmInput);
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

  Future<void> _sendCode(ForgetPasswordViewModel viewModel) async {
    if (viewModel.isLoading ||
        !isEmailValid ||
        viewModel.isPasswordResetting ||
        !_formKey.currentState!.validate()) {
      return;
    }
    await viewModel.forgetPassword(_emailController.text);
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (viewModel.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ModalRoute.of(context)?.isCurrent == true &&
            viewModel.isPasswordResetting) {
          _newPasswordFocus.requestFocus();
        }
      });
    }
  }

  Future<void> _resetPassword(ForgetPasswordViewModel viewModel) async {
    if (viewModel.isLoading ||
        !confirmEnable ||
        !_formKey.currentState!.validate()) {
      return;
    }
    await viewModel.confirmResetPassword(_emailController.text,
        _newPasswordController.text, _confirmationCodeController.text);
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (viewModel.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    } else {
      TextInput.finishAutofillContext(shouldSave: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<
          ForgetPasswordViewModel>(), //Creates an instance of the ForgetPasswordViewModel using the create function
      child: Scaffold(
        appBar: AppBar(
          title: Text("Reset Password"),
        ),
        body: Consumer<ForgetPasswordViewModel>(
          //widget listens to changes in the ForgetPasswordViewModel
          builder: (context, viewModel, child) {
            return SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16.0),
                child: AutofillGroup(
                  onDisposeAction: AutofillContextAction.cancel,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Input Field
                        TextFormField(
                          key: const ValueKey('reset_email'),
                          controller: _emailController,
                          focusNode: _emailFocus,
                          readOnly: viewModel.isLoading,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ],
                          autocorrect: false,
                          textInputAction: viewModel.isPasswordResetting
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (viewModel.isPasswordResetting) {
                              _newPasswordFocus.requestFocus();
                            } else {
                              _sendCode(viewModel);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Email",
                            hintText: "Input Email",
                            border: UnderlineInputBorder(),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                            errorStyle: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address to receive a confirmation code to reset your password.';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
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
                                key: const ValueKey('reset_new_password'),
                                controller: _newPasswordController,
                                focusNode: _newPasswordFocus,
                                readOnly: viewModel.isLoading,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                keyboardType: TextInputType.visiblePassword,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    _confirmPasswordFocus.requestFocus(),
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
                                    onPressed:
                                        viewModel.toggleNewPasswordVisibility,
                                  ),
                                ),
                                onChanged: (text) {
                                  newPassword = text;
                                  setState(() {
                                    isNewPasswordValid =
                                        newPassword!.length >= 6;
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
                                    isNewPasswordValid
                                        ? ''
                                        : 'Password must be at least 6 characters long',
                                    style: TextStyle(
                                      color: isNewPasswordValid
                                          ? Colors.transparent
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
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
                            key: const ValueKey('reset_password_confirmation'),
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            readOnly: viewModel.isLoading,
                            autofillHints: const [AutofillHints.newPassword],
                            keyboardType: TextInputType.visiblePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _codeFocus.requestFocus(),
                            obscureText: viewModel.obscureTextConfirmPassword,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              hintText: "Re-enter your password",
                              border: UnderlineInputBorder(),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              errorStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.obscureTextConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    viewModel.toggleConfirmPasswordVisibility,
                              ),
                            ),
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
                        SizedBox(height: 20),

                        // Confirmation Message
                        if (viewModel.isPasswordResetting)
                          Text(
                            "A confirmation code has been sent to ${_emailController.text}. Please enter the code to verify your email address.",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 18),

                        // Confirmation Code Input
                        if (viewModel.isPasswordResetting)
                          TextFormField(
                            key: const ValueKey('reset_code'),
                            focusNode: _codeFocus,
                            readOnly: viewModel.isLoading,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _resetPassword(viewModel),
                            keyboardType: TextInputType.number,
                            controller: _confirmationCodeController,
                            decoration: InputDecoration(
                              labelText: "Confirmation Code",
                              border: UnderlineInputBorder(),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              errorStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                            validator: (value) {
                              if (value == null || value.length != 6) {
                                return "Please enter a valid confirmation code to proceed";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              checkConfirmInput();
                            },
                          ),
                        SizedBox(height: 20),

                        // Confirm Button
                        if (viewModel.isPasswordResetting)
                          LoginButton(
                            'Reset',
                            enable: confirmEnable,
                            isLoading: viewModel.isLoading,
                            onPressed: () => _resetPassword(viewModel),
                          ),

                        // Reset Password Button
                        if (!viewModel.isPasswordResetting)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 1.0), // Adjust top padding here
                            child: MaterialButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => _sendCode(viewModel),
                              height: 45,
                              minWidth: double.infinity,
                              color: isEmailValid
                                  ? Color.fromRGBO(66, 66, 66, 1.0)
                                  : Color.fromRGBO(180, 180, 180, 1),
                              disabledColor: Color.fromRGBO(180, 180, 180, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: viewModel.isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(
                                      "Reset Password",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
    _confirmationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void checkConfirmInput() {
    setState(() {
      confirmEnable = _emailController.text.isNotEmpty &&
          (isEmailValid) &&
          (_newPasswordController.text.isNotEmpty &&
              _newPasswordController.text.length >= 6) &&
          (_confirmPasswordController.text == _newPasswordController.text) &&
          (_confirmationCodeController.text.isNotEmpty &&
              _confirmationCodeController.text.length == 6);
    });
  }
}
