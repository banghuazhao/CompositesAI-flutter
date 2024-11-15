import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../viewModels/signup_view_model.dart';

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
  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String? verificationCode;
  bool isLoading = false;
  String nickname = '';
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool isButtonEnabled = false;
  bool isPasswordValid = false;
  bool isEmailValid = false;

  void _checkFields() {
    setState(() {
      isButtonEnabled = email.isNotEmpty &&
          RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email) &&
          password.isNotEmpty &&
          password.length >= 6 &&
          confirmPassword == password &&
          _verificationCodeController.text.isNotEmpty &&
              _verificationCodeController.text.length == 6;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _verificationCodeController.addListener(_checkFields);
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
    nickname = _nicknameController.text.trim();
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      User? user = await viewModel.signup(
        email,
        password,
        _verificationCodeController.text,
        name: nickname.isNotEmpty ? nickname : null,
      );
      setState(() => isLoading = false);

      if (user != null) {
        // Attempt to login after successful sign-up
        String? token = await viewModel.login(email, password);
        if (token != null) {
          // Successful login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sign-up complete! You have been logged in."),
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to the home screen
          Navigator.pop(context, "sign up success");
        } else {
          // Sign-up succeeded, but login failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sign-up successful but login failed. Please try logging in manually."),
            ),
          );
        }
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
    final viewModel = Provider.of<SignupViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Signup')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
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
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Nickname Field (Optional)
              if(viewModel.isSignUp)
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname (optional)',
                  hintText: 'Enter your nickname',
                ),
                style: TextStyle(color: Colors.black),
                onChanged: (value) {
                  nickname = value.trim();
                },
              ),
              SizedBox(height: 16.0),

              // Password Field
              if(viewModel.isSignUp)
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
                        isPasswordValid ? '' : 'Password must be at least 6 characters long',
                        style: TextStyle(
                          color: isPasswordValid ? Colors.transparent : Colors.black54,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Confirm Password Field
              if(viewModel.isSignUp)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  errorText: confirmPassword == password ? null : 'Passwords do not match',
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

              if(viewModel.isSignUp)
              TextFormField(
                keyboardType: TextInputType.number,
                controller: _verificationCodeController,
                decoration: InputDecoration(
                  labelText: "Verification Code",
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
                    return "Please enter a valid verification code to proceed";
                  }
                  return null;
                },
                onChanged: (value) {
                  verificationCode = value;
                  _checkFields();
                },
              ),
              SizedBox(height: 20),

              // Signup Button
              if(viewModel.isSignUp)
              viewModel.isLoading || isLoading
                  ? CircularProgressIndicator()
                  : MaterialButton(
                onPressed: isButtonEnabled ? () => _signup(viewModel) : null,
                height: 45,
                minWidth: double.infinity,
                color: isButtonEnabled
                    ? Color.fromRGBO(51, 66, 78, 1)
                    : Color.fromRGBO(180, 180, 180, 1),
                disabledColor: Color.fromRGBO(140, 150, 153, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Signup', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),

              if (!viewModel.isSignUp)
                Padding(
                  padding: const EdgeInsets.only(top: 1.0), // Adjust top padding here
                  child: MaterialButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        await viewModel.signUpFor(email);

                        if (viewModel.errorMessage != null && viewModel.errorMessage!.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(viewModel.errorMessage!),
                            ),
                          );
                        } else if (viewModel.isSignUp) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification code sent successfully.'),
                            ),
                          );
                        }
                      }
                    },
                    height: 45,
                    minWidth: double.infinity,
                    color: isEmailValid ? const Color(0xFF33424E) : const Color(0xFF8C9699),
                    disabledColor: const Color(0xFF8C9699),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: viewModel.isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      "Send Verification Code",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
