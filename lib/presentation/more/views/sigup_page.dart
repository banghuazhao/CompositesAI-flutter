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

  void _signup(SignupViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      User? user = await viewModel.signup(username, email, password);
      if (user != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup successful!")),
        );

        // Wait for a short delay before popping the screen
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, user);
      } else if (viewModel.errorMessage != null) {
        // Display an error message
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
              child: Column(
                children: [
                  // Username Field
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Username'),
                    onChanged: (value) => username = value.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  // Email Field
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email'),
                    onChanged: (value) => email = value.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onChanged: (value) => password = value.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your password';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  // Confirm Password Field
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    onChanged: (value) => confirmPassword = value.trim(),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please confirm your password';
                      if (value != password)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  SizedBox(height: 30.0),
                  // Signup Button
                  // Signup Button
                  viewModel.isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () => _signup(viewModel),
                    child: Text('Signup'),
                  ),                ],
              )),
        ));
  }
}
