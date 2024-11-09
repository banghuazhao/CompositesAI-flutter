import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../injection_container.dart';
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
  bool isLoading = false;
  String nickname = '';
  final TextEditingController _nicknameController = TextEditingController();
  bool isButtonEnabled = false;
  bool isPasswordValid = false;

  void _checkFields() {
    setState(() {
      isButtonEnabled = email.isNotEmpty &&
          RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email) &&
          password.isNotEmpty &&
          password.length >= 6 &&
          confirmPassword == password;
    });
  }

  void _signup(SignupViewModel viewModel) async {
    nickname = _nicknameController.text.trim();
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      User? user = await viewModel.signup(
        email,
        password,
        name: nickname.isNotEmpty ? nickname : null,
      );
      setState(() => isLoading = false);

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signup successful!"),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, user);
      } else if (viewModel.errorMessage != null) {
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
                decoration: InputDecoration(
                  labelText: 'Email',
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
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Nickname Field (Optional)
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
              SizedBox(height: 30.0),

              // Signup Button
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
            ],
          ),
        ),
      ),
    );
  }
}
