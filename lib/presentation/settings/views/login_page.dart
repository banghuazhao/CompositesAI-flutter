import 'package:domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/sigup_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../injection_container.dart';
import '../viewModels/login_view_model.dart';
import 'forget_password_page.dart';

class NewLoginPage extends StatefulWidget {
  const NewLoginPage({Key? key}) : super(key: key);

  @override
  State<NewLoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<NewLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool isLoading = false;
  bool isButtonEnabled = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to check if the fields are non-empty
    _usernameController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
  }

  void _checkFields() {
    setState(() {
      isButtonEnabled = _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 6;
    });
  }

  void _login(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Call login from viewModel and pass the credentials
      final accessToken = await viewModel.login(username, password);

      if (accessToken != null) {
        // Login successful
        Fluttertoast.showToast(
          msg: "Logged in",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.pop(context, "Log in Success");
      } else {
        // Login failed - error handled within viewModel and errorMessage will be populated
        if (viewModel.errorMessage != null) {
          Fluttertoast.showToast(
            msg: viewModel.errorMessage!,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      // General error handling, if something unexpected happens
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFFB71C1C)), // Underline color when there’s an error
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color:
                              Color(0xFFB71C1C)), // Underline color when focused and there’s an error
                        ),
                        errorStyle: TextStyle(color: Color(0xFFB71C1C)), // Error text color
                      ),
                      style: TextStyle(color: Colors.black), // Text color when typing
                      obscureText: false,
                      onChanged: (value) => username = value.trim(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username should not be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText, // Controls whether the text is hidden
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFB71C1C), // Underline color when there’s an error
                          ),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFB71C1C), // Underline color when focused and there’s an error
                          ),
                        ),
                        errorStyle: TextStyle(color: Color(0xFFB71C1C)), // Error text color
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) => password = value.trim(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password should not be empty';
                        } else if (value.length < 6) {
                          return 'Password should be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30.0),

                    // Login Button
                    viewModel.isLoading
                        ? CircularProgressIndicator()
                        : MaterialButton(
                            minWidth: double.infinity,
                            height: 45,
                            color: isButtonEnabled
                                ? Color.fromRGBO(51, 66, 78, 1) // Enabled color
                                : Color.fromRGBO(
                                    180, 180, 180, 1), // Grey color for disabled button
                            disabledColor: Color.fromRGBO(140, 150, 153, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onPressed: isButtonEnabled ? () => _login(viewModel) : null,
                            child: Text(
                              'Login',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                    SizedBox(height: 20.0),

                    // Forget Password Button
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 45,
                      color: Color.fromRGBO(51, 66, 78, 1), // Darker color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgetPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Forget Password',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20.0),

                    // Signup Section
                    Text("Don't have an account?"),
                    SizedBox(height: 5.0),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 45,
                      color: Color.fromRGBO(
                          51, 66, 78, 1), // Darker color matching "Forget Password" button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onPressed: _signup,
                      child: Text(
                        'Signup',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }));
  }

  void _signup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );

    if (result != null && result is User) {
      print(result.username);
      setState(() {
        username = result.username;
        _usernameController.text = username;
      });
    }
  }
}
