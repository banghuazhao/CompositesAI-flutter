import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import '../../app/injection_container.dart';
import '../../util/app_colors.dart';
import 'signup_view_model.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide the SignupViewModel to the widget tree
    return ChangeNotifierProvider(
      create: (_) => sl<SignupViewModel>(),
      child: SignupForm(),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({Key? key}) : super(key: key);

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool isLoading = false;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;
  bool isPasswordValid = false;
  bool isEmailValid = false;

  void _checkFields() {
    setState(() {
      name = _nicknameController.text.trim();
      isButtonEnabled = email.isNotEmpty &&
          RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email) &&
          name.isNotEmpty &&
          password.isNotEmpty &&
          password.length >= 6 &&
          confirmPassword == password;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _nicknameController.addListener(_checkFields);
  }

  void _validateEmail() {
    email = _emailController.text;
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (isValid != isEmailValid) {
      setState(() {
        isEmailValid = isValid;
      });
    }
  }

  void _signup(SignupViewModel viewModel) async {
    name = _nicknameController.text.trim();
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      User? user = await viewModel.signUp(
        name,
        email,
        password,
        profileImageUrl: viewModel.profileImageDataUrl,
      );
      setState(() => isLoading = false);

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sign-up complete! You have been logged in."),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, user);
      } else if (viewModel.errorMessage != null) {
        // Sign-up failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SignupViewModel>(
        context); //access an already provided instance of SignupViewModel
    return Scaffold(
      appBar: AppBar(title: Text('Signup')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: context.horizontalSidePaddingForContentWidth,
            vertical: 20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // Profile image picker (optional)
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: viewModel.profileImageBytes == null
                        ? null
                        : MemoryImage(viewModel.profileImageBytes!),
                    child: viewModel.profileImageBytes == null
                        ? const Icon(Icons.person, color: Colors.black54)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                                  await viewModel.pickProfileImage();
                                  if (viewModel.errorMessage != null &&
                                      viewModel.errorMessage!.isNotEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(viewModel.errorMessage!),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            viewModel.profileImageBytes == null
                                ? 'Add profile photo'
                                : 'Change photo',
                          ),
                        ),
                        if (viewModel.profileImageBytes != null)
                          TextButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () {
                                    viewModel.clearProfileImage();
                                  },
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Username Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: "Input Email",
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB71C1C)),
                  ),
                  focusedErrorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB71C1C)),
                  ),
                  errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                ),
                onChanged: (value) {
                  email = value.trim();
                  _checkFields();
                },
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Name Field
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  name = value.trim();
                  _checkFields();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                      password = text;
                      setState(() {
                        isPasswordValid = password.length >= 6;
                      });
                      _checkFields();
                    },
                  ),
                  SizedBox(height: 4.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3.0),
                      child: Text(
                        isPasswordValid
                            ? ''
                            : 'Password must be at least 6 characters long',
                        style: TextStyle(
                          color: isPasswordValid
                              ? Colors.transparent
                              : Colors.black54,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Confirm Password Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  errorText: confirmPassword == password
                      ? null
                      : 'Passwords do not match',
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
                obscureText: viewModel.obscureTextConfirmPassword,
                onChanged: (value) {
                  setState(() {
                    confirmPassword = value.trim();
                  });
                  _checkFields();
                },
              ),
              SizedBox(height: 16.0),

              // Signup Button
              viewModel.isLoading || isLoading
                  ? CircularProgressIndicator()
                  : MaterialButton(
                      onPressed:
                          isButtonEnabled ? () => _signup(viewModel) : null,
                      height: 45,
                      minWidth: double.infinity,
                      color: isButtonEnabled
                          ? Color.fromRGBO(51, 66, 78, 1)
                          : Color.fromRGBO(180, 180, 180, 1),
                      disabledColor: Color.fromRGBO(140, 150, 153, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Create account',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
