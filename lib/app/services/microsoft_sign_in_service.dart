import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infrastructure/microsoft_android_redirect_service.dart';
import 'package:infrastructure/microsoft_sign_in_service.dart';
import 'package:msal_auth/msal_auth.dart';

/// Shares one MSAL client and serializes cache removal with interactive login.
/// MULTIPLE mode removes this client's tokens without signing out the broker.
class MicrosoftSignInServiceImpl implements MicrosoftSignInService {
  MicrosoftSignInServiceImpl({
    this.cleanupTimeout = const Duration(seconds: 10),
  });

  final Duration cleanupTimeout;
  Future<MultipleAccountPca>? _application;
  Future<void> _pendingOperation = Future<void>.value();

  static String _env(String key, [String fallback = '']) {
    try {
      return dotenv.env[key]?.trim() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static void _ensureActive(bool Function()? isActive) {
    if (isActive != null && !isActive()) {
      throw const _MicrosoftAttemptCancelled();
    }
  }

  Future<MultipleAccountPca> _client({bool Function()? isActive}) async {
    _ensureActive(isActive);
    final clientId = _env('MICROSOFT_CLIENT_ID');
    if (clientId.isEmpty ||
        kIsWeb ||
        !const [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS
        ].contains(defaultTargetPlatform)) {
      throw const MicrosoftSignInConfigurationException();
    }
    final existing = _application;
    if (existing != null) return existing;
    final creation = () async {
      final redirectUri = defaultTargetPlatform == TargetPlatform.android
          ? await MicrosoftAndroidRedirectService().getRedirectUri()
          : _env('MICROSOFT_ANDROID_REDIRECT_URI');
      _ensureActive(isActive);
      return MultipleAccountPca.create(
        clientId: clientId,
        androidConfig: AndroidConfig(
          configFilePath:
              _env('MICROSOFT_MSAL_CONFIG_PATH', 'msal_config.json'),
          redirectUri: redirectUri,
        ),
        appleConfig: AppleConfig(
          authorityType: AuthorityType.aad,
          broker: Broker.msAuthenticator,
        ),
      );
    }();
    _application = creation;
    try {
      return await creation;
    } catch (_) {
      _application = null;
      rethrow;
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final next = _pendingOperation.then((_) => operation());
    // Keep the lock until native work really finishes. A Dart timeout cannot
    // cancel MSAL, and releasing early could let old cleanup remove a new login.
    _pendingOperation =
        next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _removeAppAccounts(MultipleAccountPca application) async {
    final accounts = await application.getAccounts();
    for (final account in accounts) {
      if (!await application.removeAccount(identifier: account.id)) {
        throw const MicrosoftSessionCleanupException();
      }
    }
  }

  @override
  Future<String?> acquireAccessToken({bool Function()? isActive}) async {
    var abandoned = false;
    final readyForAccountPicker = Completer<void>();
    final operation = _serialize<String?>(() async {
      try {
        if (abandoned) throw const MicrosoftSessionCleanupException();
        _ensureActive(isActive);
        final application = await _client(isActive: isActive);
        _ensureActive(isActive);
        // Also clears a cached account left by an earlier app version or failed
        // backend exchange before starting this explicit account choice.
        await _removeAppAccounts(application);
        if (abandoned) throw const MicrosoftSessionCleanupException();
        _ensureActive(isActive);
        readyForAccountPicker.complete();
        final scopes = _env('MICROSOFT_SCOPES', 'User.Read')
            .split(RegExp(r'[ ,]+'))
            .where((scope) => scope.isNotEmpty)
            .toList();
        final authority = _env('MICROSOFT_AUTHORITY');
        final result = await application.acquireToken(
          scopes: scopes.isEmpty ? ['User.Read'] : scopes,
          prompt: Prompt.selectAccount,
          authority: authority.isEmpty ? null : authority,
        );
        if (result.accessToken.isEmpty) {
          throw const MicrosoftSessionCleanupException();
        }
        return result.accessToken;
      } on MsalUserCancelException {
        return null;
      } on _MicrosoftAttemptCancelled {
        return null;
      }
    });
    try {
      // Bound queue/cache preparation, while allowing the user time to finish
      // the native sign-in screen. Abandoned work cannot open that screen later.
      await Future.any<void>([
        readyForAccountPicker.future,
        operation.then<void>((_) {}),
      ]).timeout(cleanupTimeout);
    } on TimeoutException {
      abandoned = true;
      throw const MicrosoftSessionCleanupException();
    }
    return operation;
  }

  @override
  Future<void> clearAppSession() async {
    var abandoned = false;
    final operation = _serialize<void>(() async {
      if (abandoned) return;
      // No client configuration means Microsoft has never been available here.
      if (_env('MICROSOFT_CLIENT_ID').isEmpty) return;
      final application = await _client();
      await _removeAppAccounts(application);
    });
    try {
      await operation.timeout(cleanupTimeout);
    } catch (_) {
      abandoned = true;
      throw const MicrosoftSessionCleanupException();
    }
  }
}

class _MicrosoftAttemptCancelled implements Exception {
  const _MicrosoftAttemptCancelled();
}
