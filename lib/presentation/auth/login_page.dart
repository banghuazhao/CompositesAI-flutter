import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:swiftcomp/presentation/auth/sigup_page.dart';
import 'package:swiftcomp/util/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/injection_container.dart';
import 'login_view_model.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  String? _emailLoginError;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkFields() {
    final isEmailValid =
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
    final isPasswordValid = _passwordController.text.length >= 6;
    setState(() => _isButtonEnabled = isEmailValid && isPasswordValid);
  }

  bool _isCancellation(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('cancel') || lower.contains('dismissed');
  }

  // ── Email/password login ─────────────────────────────────────────────────

  Future<void> _login(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _emailLoginError = null);

    final user = await viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (user != null) {
      Navigator.pop(context, user);
      return;
    }

    setState(() {
      _emailLoginError =
          viewModel.errorMessage ?? 'Login failed. Please try again.';
    });
  }

  // ── Social sign-in (Google / Apple / Microsoft) ──────────────────────────
  // Shows a loading spinner while `signIn()` runs, then navigates on success
  // or shows an error snackbar on failure. Cancellations are silent.

  Future<void> _handleSocialSignIn(Future<void> Function() signIn) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await signIn();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner

    final viewModel = context.read<LoginViewModel>();
    if (viewModel.isSigningIn) {
      Navigator.pop(context, viewModel.signedInUser);
      return;
    }

    final error = viewModel.errorMessage;
    if (error != null && !_isCancellation(error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── GitHub device-flow sign-in ───────────────────────────────────────────

  Future<void> _githubSignIn(LoginViewModel viewModel) async {
    try {
      bool started = false;
      bool dialogClosed = false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AnimatedBuilder(
            animation: viewModel,
            builder: (context, _) {
              void safeClose() {
                if (dialogClosed) return;
                dialogClosed = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                });
              }

              if (!started) {
                started = true;
                viewModel.signInWithGithub().whenComplete(safeClose);
              }

              final code = viewModel.githubUserCode;
              final uri = viewModel.githubVerificationUri;

              return AlertDialog(
                title: const Text('GitHub Sign-In'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (code == null || uri == null) ...[
                      const Text('Preparing GitHub authorization…'),
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      const Text('Open GitHub and enter this code:'),
                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          "If the browser didn't open automatically, open:"),
                      const SizedBox(height: 6),
                      SelectableText(uri),
                      const SizedBox(height: 12),
                      const Text('Waiting for authorization…'),
                    ],
                  ],
                ),
                actions: [
                  if (code != null)
                    TextButton(
                      onPressed: () async =>
                          Clipboard.setData(ClipboardData(text: code)),
                      child: const Text('Copy code'),
                    ),
                  if (uri != null)
                    TextButton(
                      onPressed: () async => launchUrl(Uri.parse(uri),
                          mode: LaunchMode.externalApplication),
                      child: const Text('Open GitHub'),
                    ),
                  TextButton(
                    onPressed: () {
                      viewModel.cancelGithubSignIn();
                      safeClose();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted) return;

      if (viewModel.isSigningIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pop(context, viewModel.signedInUser);
        });
        return;
      }

      final error = viewModel.errorMessage;
      if (error != null && !_isCancellation(error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GitHub sign-in failed. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Sign-up navigation ───────────────────────────────────────────────────

  Future<void> _signup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignupPage()),
    );
    if (!mounted) return;
    if (result is User) Navigator.pop(context, result);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Login'),
              centerTitle: true,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width:
                      screenWidth > 600 ? screenWidth * 0.4 : double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App icon
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'images/app_icon.png',
                                height: 40,
                                width: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFB71C1C)),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFB71C1C)),
                            ),
                            errorStyle: TextStyle(color: Color(0xFFB71C1C)),
                          ),
                          onChanged: (_) =>
                              setState(() => _emailLoginError = null),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: viewModel.obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(viewModel.obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: viewModel.togglePasswordVisibility,
                            ),
                          ),
                          onChanged: (_) =>
                              setState(() => _emailLoginError = null),
                        ),
                        const SizedBox(height: 2.0),

                        // Forgot password — always visible
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ForgetPasswordPage()),
                            ),
                            child: const Text(
                              'Forgot password?',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Login button
                        viewModel.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 45),
                                  backgroundColor: _isButtonEnabled
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                                onPressed: _isButtonEnabled
                                    ? () => _login(viewModel)
                                    : null,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),

                        // Inline login error
                        if (_emailLoginError != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _emailLoginError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20.0),

                        // Sign-up link
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                            children: [
                              const TextSpan(text: 'Not a member yet? '),
                              TextSpan(
                                text: 'Sign up',
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _signup,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20.0),

                        // Divider
                        const Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.grey, thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('OR',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.black)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.grey, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 10.0),

                        // Social buttons
                        _buildSocialButton(
                          iconPath: 'images/google_logo.png',
                          text: 'Continue with Google',
                          onPressed: () => _handleSocialSignIn(
                              () => viewModel.signInWithGoogle()),
                        ),
                        const SizedBox(height: 10),
                        _buildSocialButtonIcon(
                          icon: FontAwesomeIcons.github,
                          text: 'Continue with GitHub',
                          onPressed: () => _githubSignIn(viewModel),
                        ),
                        const SizedBox(height: 10),
                        _buildSocialButtonIcon(
                          iconWidget: _microsoftLogo(size: 20),
                          text: 'Continue with Microsoft',
                          onPressed: () => _handleSocialSignIn(
                              () => viewModel.signInWithMicrosoft()),
                        ),
                        const SizedBox(height: 10),
                        _buildSocialButton(
                          iconPath: 'images/apple_logo.png',
                          text: 'Continue with Apple',
                          onPressed: () => _handleSocialSignIn(
                              () => viewModel.signInWithApple()),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Widget _microsoftLogo({required double size}) {
    final gap = size * 0.08;
    final tile = (size - gap) / 2;

    Widget square(Color color) => Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          Row(children: [
            square(const Color(0xFFF25022)),
            SizedBox(width: gap),
            square(const Color(0xFF7FBA00)),
          ]),
          SizedBox(height: gap),
          Row(children: [
            square(const Color(0xFF00A4EF)),
            SizedBox(width: gap),
            square(const Color(0xFFFFB900)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSocialButtonBase({
    required Widget leading,
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 24, height: 24, child: Center(child: leading)),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
  }) {
    return _buildSocialButtonBase(
      leading: Image.asset(iconPath, height: 22, width: 22,
          fit: BoxFit.contain),
      text: text,
      onPressed: onPressed,
    );
  }

  Widget _buildSocialButtonIcon({
    FaIconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onPressed,
  }) {
    assert(icon != null || iconWidget != null);
    return _buildSocialButtonBase(
      leading: iconWidget ?? FaIcon(icon!, color: Colors.black, size: 22),
      text: text,
      onPressed: onPressed,
    );
  }
}
