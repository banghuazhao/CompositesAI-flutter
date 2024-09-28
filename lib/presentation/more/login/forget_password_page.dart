import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftcomp/presentation/more/login/login_button.dart';
import 'package:swiftcomp/presentation/more/login/login_input.dart';
import 'package:swiftcomp/util/string_util.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  bool confirmEnable = false;
  bool resetEnable = false;
  String? email;
  bool isPasswordResetting = false;
  String? newPassword;
  String? confirmCode;
  final TextEditingController _confirmationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
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
                if (isPasswordResetting) {
                  checkConfirmInput();
                } else {
                  checkInput();
                }
              },
            ),
            if (isPasswordResetting)
              LoginInput(
                "New Password",
                "Input new password",
                obscureText: true,
                onChanged: (text) {
                  newPassword = text;
                  checkConfirmInput();
                },
              ),
            if (isPasswordResetting)
              Container(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Text(
                    "An email confirmation code is sent to $email. Please type the code to confirm your email.",
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
            if (isPasswordResetting)
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _confirmationCodeController,
                  decoration: InputDecoration(labelText: "Confirmation Code"),
                  validator: (value) =>
                      value?.length != 6 ? "The confirmation code is invalid" : null,
                  onChanged: (value) {
                    confirmCode = value;
                    checkConfirmInput();
                  },
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: isPasswordResetting
                  ? LoginButton('Confirm', enable: confirmEnable, onPressed: sendConfirm)
                  : LoginButton('Reset Password', enable: resetEnable, onPressed: sendReset),
            )
          ],
        ),
      ),
    );
  }

  void checkInput() {
    bool enable;
    if (isNotEmpty(email)) {
      enable = true;
    } else {
      enable = false;
    }
    setState(() {
      resetEnable = enable;
    });
  }

  void checkConfirmInput() {
    bool enable;
    if (isNotEmpty(email) &&
        isNotEmpty(newPassword) &&
        isNotEmpty(confirmCode) &&
        confirmCode?.length == 6) {
      enable = true;
    } else {
      enable = false;
    }
    setState(() {
      confirmEnable = enable;
    });
  }

  void sendReset() async {
    final String emailFinal = email!;

    try {
      ResetPasswordResult res = await Amplify.Auth.resetPassword(
        username: emailFinal,
      );
      setState(() {
        isPasswordResetting = true;
      });
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

  void sendConfirm() async {
    final String emailFinal = email!;
    final String newPasswordFinal = newPassword!;
    final String confirmCodeFinal = confirmCode!;

    try {
      ResetPasswordResult res = await Amplify.Auth.confirmResetPassword(
          username: emailFinal, newPassword: newPasswordFinal, confirmationCode: confirmCodeFinal);
      Fluttertoast.showToast(
          msg: "Successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
      Navigator.pop(context, "Successful");
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
