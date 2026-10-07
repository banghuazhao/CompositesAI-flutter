// lib/presentation/viewmodels/signup_view_model.dart

import 'dart:convert';

import 'package:domain/common/domain_exceptions.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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
        final result = await FilePicker.pickFiles(
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
    final message = error.toString().toLowerCase();
    if (error is ResourceAlreadyExistsException ||
        message.contains('email_taken') ||
        message.contains('email is already registered')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (message.contains('invalid_email_format') ||
        (message.contains('email format') && message.contains('invalid'))) {
      return 'Please enter a valid email address.';
    }
    if (error is TooManyRequestsException) {
      return 'Too many attempts. Please try again later.';
    }
    if (error is InternalServerErrorException) {
      return 'Server error. Please try again later.';
    }
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Network error. Please check your connection.';
    }
    if (error is BadRequestException || error is UnprocessableEntityException) {
      return 'Please check your signup details and try again.';
    }
    if (error is ForbiddenException) {
      return 'Account creation is currently unavailable. Please try again later.';
    }
    return 'Could not create your account. Please try again.';
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
      _errorMessage = _mapSignupError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
