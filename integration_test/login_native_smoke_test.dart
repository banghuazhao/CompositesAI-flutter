import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/main.dart' as app;
import 'package:swiftcomp/presentation/auth/forget_password_page.dart';
import 'package:swiftcomp/presentation/auth/login_page.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';
import 'package:swiftcomp/presentation/auth/sigup_page.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/views/settings_page.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';

const _mode = String.fromEnvironment('LOGIN_SMOKE_MODE', defaultValue: 'ui');
const _provider = String.fromEnvironment('LOGIN_SMOKE_PROVIDER');
const _timeoutSeconds =
    int.fromEnvironment('LOGIN_SMOKE_TIMEOUT_SECONDS', defaultValue: 240);
const _providerLabels = {
  'google': 'Continue with Google',
  'github': 'Continue with GitHub',
  'microsoft': 'Continue with Microsoft',
  'apple': 'Continue with Apple',
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real-device login smoke', (tester) async {
    final checks = <String>[];
    var stage = 'startup';
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'unsupported';

    void progress(String value) {
      stage = value;
      debugPrint('LOGIN_SMOKE_PROGRESS ${jsonEncode({'stage': value})}');
    }

    void require(bool condition, String reason) {
      if (!condition) fail(reason);
    }

    Future<void> waitUntil(bool Function() condition,
        {int seconds = 60}) async {
      final watch = Stopwatch()..start();
      while (!condition()) {
        if (watch.elapsed >= Duration(seconds: seconds)) {
          fail('The expected app state was not reached during $stage.');
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> tap(Finder finder) async {
      require(finder.evaluate().length == 1,
          'The expected control is unavailable during $stage.');
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<bool> hasStoredSession() async =>
        await tester.runAsync(() async {
          final token = await TokenProvider().getToken();
          return token != null && token.trim().isNotEmpty;
        }) ??
        false;

    void result(String outcome) {
      binding.reportData = {
        'mode': _mode,
        'provider': _provider.isEmpty ? 'none' : _provider,
        'platform': platform,
        'outcome': outcome,
        'scope': _mode == 'email-login'
            ? 'assisted_email_auth'
            : _mode.startsWith('oauth-')
                ? 'assisted_native_auth'
                : 'in_app_ui',
        'build_source': 'flutter_drive_debug',
        'native_ui_automated': false,
        'play_signed_verified': false,
        'cold_restart_verified': false,
        'completed_checks': checks,
        'stage': stage,
      };
    }

    try {
      require(!kIsWeb && platform != 'unsupported',
          'This harness requires an iOS or Android runtime.');
      require(
          const {
            'ui',
            'email-login',
            'oauth-login',
            'oauth-cancel',
            'restore',
            'logout'
          }.contains(_mode),
          'Unknown smoke mode.');
      require(_timeoutSeconds >= 30 && _timeoutSeconds <= 600,
          'The assisted timeout must be between 30 and 600 seconds.');
      if (_mode.startsWith('oauth-')) {
        require(_providerLabels.containsKey(_provider),
            'Choose a supported visible provider.');
        require(_provider != 'apple' || platform == 'ios',
            'Apple login is only exposed on iOS.');
      }

      // Use the real app bootstrap, repositories, native plugins and backend.
      // integration_test installs its driver service only in this test target.
      app.main();
      await waitUntil(() => find.byType(ChatScreen).evaluate().isNotEmpty);
      final chat =
          tester.element(find.byType(ChatScreen)).read<ChatViewModel>();
      await tester.runAsync(chat.checkAuthStatus);
      await tester.pump();
      checks.add('real_app_started');

      if (_mode == 'restore') {
        progress('restore_session');
        require(chat.isLoggedIn && await hasStoredSession(),
            'Startup did not restore an authenticated backend session.');
        require(find.byTooltip('Account & settings').evaluate().length == 1,
            'The signed-in chat screen is unavailable.');
        checks.add('stored_session_restored');
        // This run can verify restoration, not whether the operator previously
        // force-closed the OS process. Record that separately in the run sheet.
      } else if (_mode == 'logout') {
        progress('logout');
        require(chat.isLoggedIn && await hasStoredSession(),
            'Logout smoke requires an existing signed-in session.');
        await tap(find.byTooltip('Account & settings'));
        await waitUntil(() => find.byType(SettingsPage).evaluate().isNotEmpty);
        final settings =
            tester.element(find.byType(SettingsPage)).read<SettingsViewModel>();
        await waitUntil(() => settings.isLoggedIn && !settings.isLoading);
        final profileCard = find.ancestor(
          of: find
              .descendant(
                of: find.byType(SettingsPage),
                matching: find.byIcon(Icons.chevron_right),
              )
              .first,
          matching: find.byType(InkWell),
        );
        await tap(profileCard.first);
        await waitUntil(
            () => find.byType(UserProfilePage).evaluate().isNotEmpty);
        await tap(find.text('Sign Out'));
        await waitUntil(() =>
            !chat.isLoggedIn &&
            find.byType(UserProfilePage).evaluate().isEmpty &&
            find.byType(SettingsPage).evaluate().isEmpty);
        require(!await hasStoredSession(), 'Logout retained a saved session.');
        require(
            chat.selectedChat == null &&
                chat.messages.isEmpty &&
                chat.chats.isEmpty &&
                chat.pendingFiles.isEmpty &&
                chat.pendingImageBytes.isEmpty,
            'Logout retained private chat or attachment state.');
        checks.add('real_logout_cleared_session');
      } else {
        require(!chat.isLoggedIn && !await hasStoredSession(),
            'Start this mode signed out; use logout mode first if needed.');
        progress('open_login');
        await tap(find.byTooltip('Sign In'));
        await waitUntil(() => find.byType(LoginPage).evaluate().isNotEmpty);
        final consumer = find.descendant(
          of: find.byType(LoginPage),
          matching: find.byType(Consumer<LoginViewModel>),
        );
        final login = tester.element(consumer).read<LoginViewModel>();
        checks.add('login_route_opened');

        if (_mode == 'ui') {
          progress('login_routes');
          for (final provider in ['google', 'github', 'microsoft']) {
            require(
                find.byKey(ValueKey('login_$provider')).evaluate().length == 1,
                'A supported login provider is missing.');
          }
          require(
              find.byKey(const ValueKey('login_apple')).evaluate().length ==
                  (platform == 'ios' ? 1 : 0),
              'Apple login visibility does not match this platform.');
          checks.add('platform_providers_visible');
          await tap(find.text('Forgot password?'));
          await waitUntil(
              () => find.byType(ForgetPasswordPage).evaluate().isNotEmpty);
          await tester.pageBack();
          await waitUntil(() => find.byType(LoginPage).evaluate().isNotEmpty);
          await tap(find.text('Sign up'));
          await waitUntil(() => find.byType(SignupPage).evaluate().isNotEmpty);
          await tester.pageBack();
          await waitUntil(() => find.byType(LoginPage).evaluate().isNotEmpty);
          await tester.pageBack();
          await waitUntil(() => find.byType(LoginPage).evaluate().isEmpty);
          require(!chat.isLoggedIn && !await hasStoredSession(),
              'Navigating login forms unexpectedly created a session.');
          checks.add('auth_forms_open_and_close');
        } else {
          final emailLogin = _mode == 'email-login';
          progress(emailLogin
              ? 'awaiting_email_login'
              : _mode == 'oauth-login'
                  ? 'awaiting_native_login'
                  : 'awaiting_native_cancel');
          var attemptStarted = false;
          void observeAttempt() {
            if (login.isLoading) attemptStarted = true;
          }

          // A no-op tap is not evidence of cancellation. Listen before tapping
          // so immediate SDK returns and GitHub's post-frame start are observed.
          login.addListener(observeAttempt);
          try {
            if (!emailLogin) {
              await tap(find.byKey(ValueKey('login_$_provider')));
            }
            await waitUntil(() => attemptStarted,
                seconds: emailLogin ? _timeoutSeconds : 15);
            checks.add(emailLogin
                ? 'real_email_attempt_started'
                : 'real_provider_attempt_started');
            if (_mode != 'oauth-cancel') {
              await waitUntil(
                () =>
                    (chat.isLoggedIn &&
                        find.byType(LoginPage).evaluate().isEmpty) ||
                    (!login.isLoading && login.errorMessage != null),
                seconds: _timeoutSeconds,
              );
              require(
                  chat.isLoggedIn && find.byType(LoginPage).evaluate().isEmpty,
                  'Sign-in did not complete successfully.');
              require(
                  emailLogin
                      ? !login.isSigningIn && login.signedInUser != null
                      : login.isSigningIn,
                  'The completed sign-in did not match the selected smoke mode.');
              require(await hasStoredSession(),
                  'Sign-in did not persist a backend session.');
              require(
                  find.byTooltip('Account & settings').evaluate().length == 1,
                  'Sign-in did not return to signed-in chat.');
              checks.add(emailLogin
                  ? 'real_email_login_persisted'
                  : 'real_provider_login_persisted');
            } else {
              await waitUntil(() => !login.isLoading, seconds: _timeoutSeconds);
              require(
                  !login.isSigningIn &&
                      login.errorMessage == null &&
                      !chat.isLoggedIn &&
                      find.byType(LoginPage).evaluate().length == 1 &&
                      !await hasStoredSession(),
                  'Cancellation did not return silently to signed-out login.');
              checks.add('provider_cancel_returned_silently');
            }
          } finally {
            login.removeListener(observeAttempt);
          }
        }
      }

      progress('complete');
      result('passed');
    } catch (_) {
      result('failed');
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
