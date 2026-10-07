import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final String title;
  final bool enable;
  final bool isLoading;
  final VoidCallback? onPressed;

  const LoginButton(this.title,
      {super.key, this.enable = true, this.isLoading = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        height: 45,
        onPressed: enable && !isLoading ? onPressed : null,
        disabledColor: Color.fromRGBO(180, 180, 180, 1),
        color: Color.fromRGBO(66, 66, 66, 1.0),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                  semanticsLabel: 'Resetting password',
                ),
              )
            : Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
