import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/sigup_page.dart';


import '../../../app/injection_container.dart';
import '../viewModels/login_view_model.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;
  bool isButtonEnabled = false;
  bool isPasswordValid = false;
  bool isLoginFailed = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners to check if the fields are non-empty
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
  }

  void _checkFields() {
    setState(() {
      final isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
      isButtonEnabled = isEmailValid &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 6;
    });
  }

  void _login(LoginViewModel viewModel, BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Call login from viewModel and pass the credentials
      final accessToken = await viewModel.login(
        _emailController.text,
        _passwordController.text,
      );

      if (accessToken != null) {
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logged in"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          ),
        );

        Navigator.pop(context, "Log in Success");
      } else {
        // Login failed - error handled within viewModel and errorMessage will be populated
        if (viewModel.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage!),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
          isLoginFailed = true;
        }
      }
    } catch (e) {
      // General error handling, if something unexpected happens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _googleSignIn(LoginViewModel viewModel, BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Display loading indicator
        );
      },
    );

    try {
      // Perform Google Sign-In
      await viewModel.signInWithGoogle();

      // Dismiss loading dialog before performing further actions
      Navigator.of(context, rootNavigator: true).pop();

      // Check the result of the sign-in
      if (viewModel.isSigningIn) {
        // Display success Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logged in with Google"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          ),
        );

        // Navigate to the next screen
        Navigator.pop(context, "Log in Success"); // Pop the current screen
      } else {
        // Display failure Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? "Google Sign-In failed"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any unexpected errors
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _appleSignIn(LoginViewModel viewModel, BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Display loading indicator
        );
      },
    );

    try {
      // Perform Apple Sign-In
      await viewModel.signInWithApple();

      // Dismiss loading dialog before performing further actions
      Navigator.of(context, rootNavigator: true).pop();

      // Check the result of the sign-in
      if (viewModel.isSigningIn) {
        // Display success Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logged in with Apple"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          ),
        );

        // Navigate to the next screen
        Navigator.pop(context, "Log in Success"); // Pass result back
      } else {
        // Display failure Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? "Apple Sign in failed"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any unexpected errors
      Navigator.of(context, rootNavigator: true).pop(); // Ensure dialog is dismissed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: Consumer<LoginViewModel>(builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
            centerTitle: true, // Center the title
            elevation: 0, // Remove AppBar shadow
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.zero, // Remove any padding for the scroll view
            child: Container(// Ensure it matches appBar or desired color
              alignment: Alignment.topCenter, // Align content at the top center
              child: Container(
                width: screenWidth > 600 ? screenWidth * 0.4 : double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduce padding
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Icon
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0), // Adjust top padding
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Image.asset(
                            'images/app_icon.png',
                            height: 35,
                            width: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.black, // Ensure label text is visible
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFB71C1C)),
                          ),
                          errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                        ),
                        onChanged: (value) => email = value.trim(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: viewModel.obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              viewModel.obscureText ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: viewModel.togglePasswordVisibility,
                          ),
                        ),
                        onChanged: (value) {
                          password = value.trim();
                          setState(() {
                            isPasswordValid = password.length >= 6;
                          });
                        },
                      ),
                      const SizedBox(height: 4.0),

                      // Password Validation Message
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
                      const SizedBox(height: 20.0),

                      // Login Button
                      viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : MaterialButton(
                        minWidth: double.infinity,
                        height: 45,
                        color: isButtonEnabled
                            ? const Color.fromRGBO(51, 66, 78, 1)
                            : const Color.fromRGBO(180, 180, 180, 1),
                        disabledColor: const Color.fromRGBO(140, 150, 153, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onPressed: isButtonEnabled ? () => _login(viewModel, context) : null,
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: Colors.black), // Default text style
                          children: [
                            const TextSpan(text: 'Not a member yet? '), // Static part
                            TextSpan(
                              text: 'Sign up', // Clickable part
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // Custom style for clickable text
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _signup(); // Call your signup method
                                },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20.0),

                      // Social Login Section
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Colors.grey, // Line color
                              thickness: 1, // Line thickness
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0), // Space around "OR"
                            child: Text(
                              'OR',
                              style: TextStyle(fontSize: 15, color: Colors.black54), // Style for "OR"
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey, // Line color
                              thickness: 1, // Line thickness
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5.0),
                      Column(
                        children: [
                          _buildSocialButton(
                            iconPath: 'images/google_logo.png',
                            text: 'Continue with Google',
                            onPressed: () => _googleSignIn(viewModel, context),
                          ),
                          const SizedBox(height: 10), // Space between buttons
                          _buildSocialButton(
                            iconPath: 'images/apple_logo.png',
                            text: 'Continue with Apple',
                            onPressed: () => _appleSignIn(viewModel, context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15.0),

                      // Forgot Password Button
                      if (isLoginFailed) ...[
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero, // Removes extra padding for the button
                              minimumSize: Size(50, 20), // Ensures the button has a smaller clickable area
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrinks the tap area
                              alignment: Alignment.center, // Centers the text inside the button
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: Colors.blue, // Button text color
                                fontSize: 14, // Font size for the text
                                decoration: TextDecoration.underline, // Adds underline to make it look like a link
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15.0),
                      ],

                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }




// Helper Method for Social Buttons
  Widget _buildSocialButton({
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white, // Button background color
          borderRadius: BorderRadius.circular(6), // Rounded corners
          border: Border.all(color: Colors.grey.shade300, width: 1), // Border color and width
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              iconPath,
              height: 24, // Logo height
              width: 24,  // Logo width
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12), // Space between logo and text
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87, // Text color
                fontSize: 16,         // Text size
                fontWeight: FontWeight.w500, // Text weight
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _signup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );

    if (result == "sign up success") {
      Navigator.pop(context, "Log in Success");
    }
  }
}
