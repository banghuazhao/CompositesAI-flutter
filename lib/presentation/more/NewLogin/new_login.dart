import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      // final authService = context.read<AuthService>();
      try {
        final success = true;

        if (success) {
          // Navigate to the home page
          Navigator.pop(context, "Log in Success");
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: 32.0),
                  // Login Button
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                      onPressed: _login, child: Text('Login')),
                ],
              )),
        ));
  }
}
