// lib/presentation/viewmodels/signup_view_model.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/entities/domain_exceptions.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;

  bool obscureTextNewPassword = true;
  bool obscureTextConfirmPassword = true;

  void toggleNewPasswordVisibility() {
    obscureTextNewPassword = !obscureTextNewPassword;
    notifyListeners(); // Notify the UI about the change
  }

  void toggleConfirmPasswordVisibility() {
    obscureTextConfirmPassword = !obscureTextConfirmPassword;
    notifyListeners(); // Notify the UI about the change
  }

  SignupViewModel({required this.authUseCase});

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  User? _signedInUser;
  User? get signedInUser => _signedInUser;
  bool _isSignedUp = false;
  bool get isSignedUp => _isSignedUp;

  Uint8List? _profileImageBytes;
  Uint8List? get profileImageBytes => _profileImageBytes;

  String? _profileImageDataUrl;
  String? get profileImageDataUrl => _profileImageDataUrl;

  String _mimeFromExtension(String? extOrName) {
    if (extOrName == null) return 'image/png';
    final lower = extOrName.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : lower;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/png';
    }
  }

  Future<void> pickProfileImage() async {
    _errorMessage = null;
    notifyListeners();

    try {
      Uint8List? bytes;
      String? nameOrExt;

      if (kIsWeb) {
        // On web, file_picker works reliably and provides bytes directly.
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return; // user cancelled
        final file = result.files.single;
        bytes = file.bytes;
        nameOrExt = file.extension ?? file.name;
      } else {
        // On iOS/Android, prefer native photo picker to avoid file_picker iOS representation issues.
        final picker = ImagePicker();
        final XFile? picked =
            await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return; // user cancelled
        bytes = await picked.readAsBytes();
        nameOrExt = picked.name;
      }

      if (bytes == null || bytes.isEmpty) {
        _errorMessage =
            'Failed to read selected image. Please try another one.';
        notifyListeners();
        return;
      }

      final mime = _mimeFromExtension(nameOrExt);
      _profileImageBytes = bytes;
      _profileImageDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      notifyListeners();
    } on PlatformException catch (e) {
      _errorMessage = 'Failed to pick image: ${e.message ?? e.code}';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  void clearProfileImage() {
    _profileImageBytes = null;
    _profileImageDataUrl = null;
    notifyListeners();
  }

  String _mapSignupError(Object error) {
    final msg = error.toString();
    if (msg.contains('EMAIL_TAKEN')) return '邮箱已被注册';
    if (msg.contains('INVALID_EMAIL_FORMAT')) return '邮箱格式不对';
    if (error is BadRequestException) return '注册信息有误，请检查后重试';
    if (error is InternalServerErrorException) return '服务器错误，请稍后再试';
    if (msg.contains('SocketException')) return '网络异常，请检查网络后重试';
    return 'Signup failed: $msg';
  }

  Future<User?> signUp(
    String name,
    String email,
    String password, {
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _signedInUser = null;
    _isSignedUp = false;
    notifyListeners();

    try {
      final session = await authUseCase.signUp(
        name,
        email,
        password,
        profileImageUrl: profileImageUrl ?? _profileImageDataUrl,
      );
      _signedInUser = session.user ?? User(email: email, name: name);
      _isSignedUp = true;
      return _signedInUser;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _errorMessage = _mapSignupError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
