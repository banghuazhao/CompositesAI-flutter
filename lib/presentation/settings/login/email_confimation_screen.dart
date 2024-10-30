import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftcomp/presentation/settings/login/login_button.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;
  final bool isFirst;

  EmailConfirmationScreen({
    Key? key,
    required this.email,
    required this.isFirst,
  }) : super(key: key);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _confirmationCodeController = TextEditingController();

  final _formKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Confirm your email"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: isFirst
                    ? Text(
                        "An email confirmation code is sent to $email. Please type the code to confirm your email.",
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    : Text(
                        "An email confirmation code has already been sent to $email. Please type the code to confirm your email.",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _confirmationCodeController,
                  decoration: InputDecoration(labelText: "Confirmation Code"),
                  validator: (value) =>
                      value?.length != 6 ? "The confirmation code is invalid" : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: LoginButton('Confirm', enable: true, onPressed: () => _submitCode(context)),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: LoginButton('Try Again', enable: true, onPressed: () => _tryAgain(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCode(BuildContext context) async {
    final confirmationCode = _confirmationCodeController.text;
    try {
      final SignUpResult response = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      if (response.isSignUpComplete) {
        Fluttertoast.showToast(
            msg: "Successful",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
        Navigator.pop(context, "Successful");
      }
    } on CodeExpiredException catch (e) {
      Fluttertoast.showToast(
          msg: "The code is expired, please request a code again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
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

  Future<void> _tryAgain(BuildContext context) async {
    try {
      var response = await Amplify.Auth.resendSignUpCode(
        username: email,
      );
      Fluttertoast.showToast(
          msg: "Resend Successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
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
