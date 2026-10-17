import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';

import '../../app/injection_container.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key, this.email});

  final String? email;

  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPassWordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final TextEditingController _emailController;
  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool isNewPasswordValid = false;
  bool isCurrentPasswordValid = false;
  String? currentPassword;
  String? newPassword;
  String? confirmCode;
  bool confirmEnable = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email?.trim() ?? '');
  }

  @override
  void dispose() {
    _currentPassWordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void checkConfirmInput() {
    setState(() {
      confirmEnable = (_currentPassWordController.text.isNotEmpty) &&
          (_newPasswordController.text.length >= 6) &&
          _confirmPasswordController.text == _newPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => sl<UpdatePasswordViewModel>(),
        child:
            Consumer<UpdatePasswordViewModel>(builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Update Password')),
            body: SafeArea(
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
                      children: [
                        if (_emailController.text.isNotEmpty) ...[
                          TextFormField(
                            controller: _emailController,
                            readOnly: true,
                            canRequestFocus: false,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _currentPassWordController,
                          readOnly: viewModel.isLoading,
                          focusNode: _currentPasswordFocus,
                          autofillHints: const [AutofillHints.password],
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: _newPasswordFocus.requestFocus,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            hintText: "Enter Current Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.obscureCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  viewModel.toggleCurrentPasswordVisibility,
                            ),
                          ),
                          obscureText: viewModel.obscureCurrentPassword,
                          onChanged: (text) {
                            currentPassword = text;
                            setState(() {
                              isCurrentPasswordValid =
                                  currentPassword!.isNotEmpty;
                            });
                            checkConfirmInput();
                          },
                        ),

                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _newPasswordController,
                          readOnly: viewModel.isLoading,
                          focusNode: _newPasswordFocus,
                          autofillHints: const [AutofillHints.newPassword],
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: _confirmPasswordFocus.requestFocus,
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

                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _confirmPasswordController,
                          readOnly: viewModel.isLoading,
                          focusNode: _confirmPasswordFocus,
                          autofillHints: const [AutofillHints.newPassword],
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _updatePassword(viewModel),
                          decoration: InputDecoration(
                              labelText: 'Confirm New Password',
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
                              )),
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
                                    ? () => _updatePassword(viewModel)
                                    : null, // Disable button if confirmEnable is false
                                child: Text('Update Password'),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }));
  }

  Future<void> _updatePassword(UpdatePasswordViewModel viewModel) async {
    if (viewModel.isLoading ||
        !confirmEnable ||
        !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    await viewModel.updatePassword(
        _currentPassWordController.text, _newPasswordController.text);
    // A popped route can stay mounted throughout its exit animation.
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (viewModel.errorMessage.isNotEmpty) {
      // Show error message if update fails and return error string
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    } else {
      TextInput.finishAutofillContext(shouldSave: true);
      Navigator.pop(context, 'password_updated');
    }
  }
}
