import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftcomp/presentation/more/login/login_button.dart';
import 'package:swiftcomp/presentation/more/login/login_input.dart';
import 'package:swiftcomp/util/string_util.dart';

import 'email_confimation_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool loginEnable = false;
  String? email;
  String? password;
  String? rePassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration"),
      ),
      body: Container(
        child: ListView(
          //自适应键盘弹起，防止遮挡
          children: [
            SizedBox(
              height: 20,
            ),
            LoginInput(
              "Email",
              "Input Email",
              onChanged: (text) {
                email = text;
                checkInput();
              },
            ),
            LoginInput(
              "Password",
              "Input password",
              obscureText: true,
              onChanged: (text) {
                password = text;
                checkInput();
              },
            ),
            LoginInput(
              "Confirm Password",
              "Input password again",
              lineStretch: true,
              obscureText: true,
              onChanged: (text) {
                rePassword = text;
                checkInput();
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: LoginButton('Register', enable: loginEnable, onPressed: checkParams),
            )
          ],
        ),
      ),
    );
  }

  void checkInput() {
    bool enable;
    if (isNotEmpty(email) && isNotEmpty(password) && isNotEmpty(rePassword)) {
      enable = true;
    } else {
      enable = false;
    }
    setState(() {
      loginEnable = enable;
    });
  }

  void checkParams() {
    String? tips;
    if (password != rePassword) {
      tips = '两次密码不一致';
    }

    if (tips != null) {
      print(tips);
      return;
    }
    send();
  }

  void send() async {
    final String emailFinal = email!;
    final String passwordFinal = password!;
    Map<CognitoUserAttributeKey, String> userAttributes = {
      CognitoUserAttributeKey.email: emailFinal,
    };

    try {
      final result = await Amplify.Auth.signUp(
        username: emailFinal,
        password: passwordFinal,
        options: CognitoSignUpOptions(userAttributes: userAttributes),
      );
      if (result.nextStep.signUpStep == "CONFIRM_SIGN_UP_STEP") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailConfirmationScreen(
              email: emailFinal,
              isFirst: true,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
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
