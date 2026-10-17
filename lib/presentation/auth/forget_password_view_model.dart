import 'dart:async';

import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/material.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
  ForgetPasswordViewModel({
    required this.authUseCase,
    this.resendCooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuthUseCase authUseCase;
  final Duration resendCooldown;
  final DateTime Function() _now;
  final Map<String, DateTime> _nextCodeAllowed = {};
  Timer? _cooldownTimer;
  bool _disposed = false;
  String? _requestedEmail;

  bool isLoading = false;
  bool isSendingCode = false;
  String errorMessage = '';
  bool isPasswordResetting = false;
  bool obscureTextNewPassword = true;
  bool obscureTextConfirmPassword = true;

  String? get requestedEmail => _requestedEmail;
  int get resendSecondsRemaining =>
      _requestedEmail == null ? 0 : cooldownForEmail(_requestedEmail!);
  bool get canResendCode =>
      !_disposed &&
      !isLoading &&
      _requestedEmail != null &&
      resendSecondsRemaining == 0;

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  int cooldownForEmail(String email) {
    final deadline = _nextCodeAllowed[_normalizeEmail(email)];
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(_now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void toggleNewPasswordVisibility() {
    obscureTextNewPassword = !obscureTextNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureTextConfirmPassword = !obscureTextConfirmPassword;
    notifyListeners();
  }

  Future<bool> forgetPassword(String email) async {
    if (_disposed || isLoading || isPasswordResetting) return false;
    return _sendCode(_normalizeEmail(email));
  }

  Future<bool> resendCode() async {
    if (!canResendCode) return false;
    return _sendCode(_requestedEmail!);
  }

  Future<bool> _sendCode(String email) async {
    if (cooldownForEmail(email) > 0) return false;
    isLoading = true;
    isSendingCode = true;
    errorMessage = '';
    notifyListeners();
    try {
      await authUseCase.forgetPassword(email);
      if (_disposed) return false;
      _requestedEmail = email;
      isPasswordResetting = true;
      _startCooldown(email);
      return true;
    } catch (error) {
      if (_disposed) return false;
      if (error is TooManyRequestsException) {
        // The domain API does not expose Retry-After; use the backend's
        // documented 60-second window (or the configured test duration).
        _startCooldown(email);
        errorMessage =
            'Too many requests. Please wait a minute before trying again.';
      } else if (error is TimeoutException) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to send confirmation code.';
      }
      return false;
    } finally {
      isLoading = false;
      isSendingCode = false;
      notifyListeners();
    }
  }

  bool changeEmail() {
    if (_disposed || isLoading) return false;
    _requestedEmail = null;
    isPasswordResetting = false;
    errorMessage = '';
    obscureTextNewPassword = true;
    obscureTextConfirmPassword = true;
    notifyListeners();
    return true;
  }

  Future<bool> confirmResetPassword(
      String email, String newPassword, String confirmCode) async {
    if (_disposed || isLoading) return false;
    isLoading = true;
    errorMessage = '';
    notifyListeners();
    try {
      // Once a code has been requested, its recipient is authoritative even if
      // a caller supplies a different address or autofill changes the field.
      await authUseCase.resetPassword(
          _requestedEmail ?? _normalizeEmail(email), newPassword, confirmCode);
      return !_disposed;
    } catch (_) {
      errorMessage =
          'Failed to reset password. Please check your confirmation code and try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _startCooldown(String email) {
    if (resendCooldown <= Duration.zero) return;
    _nextCodeAllowed[email] = _now().add(resendCooldown);
    _cooldownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _nextCodeAllowed.removeWhere((_, deadline) => !deadline.isAfter(_now()));
      if (_nextCodeAllowed.isEmpty) {
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
      }
      notifyListeners();
    });
  }
}
