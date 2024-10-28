import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/more/views/sigup_page.dart';

import '../../../../injection_container.dart';
import '../viewModels/login_view_model.dart';

class NewLoginPage extends StatefulWidget {
  const NewLoginPage({Key? key}) : super(key: key);

  @override
  State<NewLoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<NewLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;
  final TextEditingController _emailController = TextEditingController();

  void _login(LoginViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final accessToken = await viewModel.login(email, password);

      if (accessToken != null) {
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful! Access Token: $accessToken')),
        );
        Navigator.pop(context, "Log in Success");
      } else if (viewModel.errorMessage != null) {
        // Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => sl<LoginViewModel>(),
        child: Consumer<LoginViewModel>(builder: (context, viewModel, child) {
          return Scaffold(
              appBar: AppBar(title: Text('Login')),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                          onChanged: (value) => email = value.trim(),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                              return 'Enter a valid email';
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
                        SizedBox(height: 30.0),
                        // Login Button
                        viewModel.isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: () => _login(viewModel),
                          child: Text('Login'),
                        ),
                        SizedBox(height: 50.0),

                        Text("Don't have an account?"),

                        SizedBox(height: 30.0),
                        ElevatedButton(
                            onPressed: _signup, child: Text('Signup')),
                      ],
                    )),
              ));
        }));
  }

  void _signup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );

    if (result != null && result is User) {
      print(result.email);
      setState(() {
        email = result.email;
        _emailController.text = email;
      });
    }
  }
}
