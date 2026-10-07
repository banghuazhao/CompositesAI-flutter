import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:swiftcomp/presentation/auth/sigup_page.dart';
import 'package:swiftcomp/util/app_interactions.dart';
import 'package:swiftcomp/util/app_theme.dart';
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
    if (viewModel.isLoading) return;
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

  Future<void> _handleSocialSignIn(
    LoginViewModel viewModel,
    Future<void> Function() signIn,
    String providerName,
  ) async {
    if (viewModel.isLoading) return;
    setState(() => _emailLoginError = null);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final navigator = Navigator.of(context, rootNavigator: true);
    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    navigator.push(loadingRoute);

    String? unexpectedError;
    try {
      await signIn();
    } catch (_) {
      unexpectedError =
          '$providerName sign-in could not be completed. Please try again.';
    } finally {
      // Dismiss this dialog even if the callback throws or the page is removed.
      // Removing its specific route also avoids popping another screen.
      if (navigator.mounted && loadingRoute.isActive) {
        if (loadingRoute.isCurrent) {
          navigator.pop();
        } else {
          navigator.removeRoute(loadingRoute);
        }
      }
    }

    if (!mounted) return;

    if (unexpectedError == null && viewModel.isSigningIn) {
      Navigator.pop(context, viewModel.signedInUser);
      return;
    }

    final error = unexpectedError ?? viewModel.errorMessage;
    if (error != null && !_isCancellation(error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── GitHub device-flow sign-in ───────────────────────────────────────────

  Future<void> _githubSignIn(LoginViewModel viewModel) async {
    if (viewModel.isLoading) return;
    setState(() => _emailLoginError = null);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                  if (!dialogContext.mounted) return;
                  final route = ModalRoute.of(dialogContext);
                  final navigator = Navigator.of(dialogContext);
                  if (route?.isCurrent == true) {
                    navigator.pop();
                  } else if (route?.isActive == true) {
                    navigator.removeRoute(route!);
                  }
                });
              }

              if (!started) {
                started = true;
                // signInWithGithub notifies listeners before its first await.
                // Start it after this dialog's first build has finished.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || dialogClosed) return;
                  viewModel.signInWithGithub().whenComplete(safeClose);
                });
              }

              final code = viewModel.githubUserCode;
              final uri = viewModel.githubVerificationUri;

              return PopScope(
                canPop: !viewModel.isGithubFinalizing,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) {
                    dialogClosed = true;
                    if (!viewModel.isSigningIn) {
                      viewModel.cancelGithubSignIn();
                    }
                  }
                },
                child: AlertDialog(
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
                        Text(viewModel.isGithubFinalizing
                            ? 'Finishing sign-in…'
                            : 'Waiting for authorization…'),
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
                      onPressed: viewModel.isGithubFinalizing
                          ? null
                          : () {
                              viewModel.cancelGithubSignIn();
                              safeClose();
                            },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
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
            content: Text(error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GitHub sign-in failed. Please try again.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!viewModel.isSigningIn) viewModel.cancelGithubSignIn();
    }
  }

  // ── Sign-up navigation ───────────────────────────────────────────────────

  Future<void> _signup(LoginViewModel viewModel) async {
    if (viewModel.isLoading) return;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sign in'),
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth > 600 ? 460 : double.infinity,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'images/app_icon.png',
                                  height: 56,
                                  width: 56,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to sync chats, tools, and expert settings.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
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
                          TextFormField(
                            controller: _passwordController,
                            obscureText: viewModel.obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 48),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () {
                                      if (viewModel.isLoading) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ForgetPasswordPage()),
                                      );
                                    },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          viewModel.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _isButtonEnabled
                                      ? () => _login(viewModel)
                                      : null,
                                  child: const SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Sign in',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                          if (_emailLoginError != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline,
                                    color: scheme.error, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _emailLoginError!,
                                    style: TextStyle(
                                        color: scheme.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20.0),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Text('Not a member yet?'),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: viewModel.isLoading
                                    ? null
                                    : () => _signup(viewModel),
                                child: const Text('Sign up'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'OR',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          _buildSocialButton(
                            iconPath: 'images/google_logo.png',
                            text: 'Continue with Google',
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _handleSocialSignIn(viewModel,
                                    viewModel.signInWithGoogle, 'Google'),
                          ),
                          const SizedBox(height: 10),
                          _buildSocialButtonIcon(
                            icon: FontAwesomeIcons.github,
                            text: 'Continue with GitHub',
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _githubSignIn(viewModel),
                          ),
                          const SizedBox(height: 10),
                          _buildSocialButtonIcon(
                            iconWidget: _microsoftLogo(size: 20),
                            text: 'Continue with Microsoft',
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _handleSocialSignIn(viewModel,
                                    viewModel.signInWithMicrosoft, 'Microsoft'),
                          ),
                          if (!kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.iOS) ...[
                            const SizedBox(height: 10),
                            _buildSocialButton(
                              iconPath: 'images/apple_logo.png',
                              text: 'Continue with Apple',
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => _handleSocialSignIn(viewModel,
                                      viewModel.signInWithApple, 'Apple'),
                            ),
                          ],
                          const SizedBox(height: 24.0),
                        ],
                      ),
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
    required VoidCallback? onPressed,
  }) {
    return Pressable(
      haptic: true,
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: leading)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
    required VoidCallback? onPressed,
  }) {
    return _buildSocialButtonBase(
      leading:
          Image.asset(iconPath, height: 22, width: 22, fit: BoxFit.contain),
      text: text,
      onPressed: onPressed,
    );
  }

  Widget _buildSocialButtonIcon({
    FaIconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback? onPressed,
  }) {
    assert(icon != null || iconWidget != null);
    return _buildSocialButtonBase(
      leading: iconWidget ??
          FaIcon(icon!,
              color: Theme.of(context).colorScheme.onSurface, size: 22),
      text: text,
      onPressed: onPressed,
    );
  }
}
