import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftcomp/presentation/more/login/login_button.dart';
import 'package:swiftcomp/presentation/more/login/login_input.dart';
import 'package:swiftcomp/presentation/more/login/registration_page.dart';
import 'package:swiftcomp/util/string_util.dart';

import 'email_confimation_screen.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loginEnable = false;
  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: ProgressHUD(
          child: Builder(
            builder: (context) => Container(
              child: ListView(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  LoginInput(
                    'Email',
                    'Input Email',
                    onChanged: (text) {
                      email = text;
                      checkInput();
                    },
                  ),
                  LoginInput(
                    'Password',
                    'Input password',
                    obscureText: true,
                    onChanged: (text) {
                      password = text;
                      checkInput();
                    },
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: LoginButton(
                        'Login',
                        enable: loginEnable,
                        onPressed: () {
                          _loginButtonOnPressed(context);
                        },
                      )),
                  Padding(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                      child: LoginButton(
                        'Create Account',
                        enable: true,
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const RegistrationPage()));
                        },
                      )),
                  Padding(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                      child: LoginButton(
                        'Forget Password',
                        enable: true,
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const ForgetPasswordPage()));
                        },
                      )),
                ],
              ),
            ),
          ),
        ));
  }

  void checkInput() {
    bool enable;
    if (isNotEmpty(email) && isNotEmpty(password)) {
      enable = true;
    } else {
      enable = false;
    }
    setState(() {
      loginEnable = enable;
    });
  }

  void _loginButtonOnPressed(BuildContext context) async {
    final progress = ProgressHUD.of(context);
    progress?.show();
    try {
      final response = await Amplify.Auth.signIn(
        username: email!,
        password: password!,
      );

      print(response);

      progress?.dismiss();
      if (response.isSignedIn) {
        Fluttertoast.showToast(
            msg: "Logged in",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
        Navigator.pop(context, "Log in Success");
      }
    } on UserNotConfirmedException catch (e) {
      progress?.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailConfirmationScreen(
            email: email!,
            isFirst: false,
          ),
        ),
      );
    } on AuthException catch (e) {
      progress?.dismiss();
      Fluttertoast.showToast(
          msg: e.message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
}
