// lib/presentation/viewmodels/settings_view_model.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:domain/auth/entities/expert_upgrade_request.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
import 'package:domain/common/domain_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUserCase;
  final FeatureFlagProvider featureFlagProvider;

  bool isLoggedIn = false;
  String version = '';
  User? user;
  String submission = '';
  bool isExpert = false;
  bool isAdmin = false;
  bool isLoading = false;
  bool isLoadingExpertRequestMetadata = false;
  int pendingExpertRequestCount = 0;
  ExpertUpgradeRequest? currentExpertRequest;

  int _tapCount = 0;
  final int _maxTaps = 5;
  final int _tapTimeout = 1000; // Timeout in milliseconds
  DateTime _lastTapTime = DateTime.now();
  int _sessionGeneration = 0;
  int _authRequestId = 0;
  int _expertRequestId = 0;
  bool _isDisposed = false;
  bool _isLoggingOut = false;

  SettingsViewModel(
      {required this.authUseCase,
      required this.userUserCase,
      required this.featureFlagProvider}) {
    initPackageInfo();
    fetchAuthSessionNew();
  }

  void updateUser(User user) {
    if (_isDisposed) return;
    _sessionGeneration++;
    _authRequestId++;
    _expertRequestId++;
    _clearExpertRequestMetadata();
    submission = '';
    _applyUser(user);
    notifyListeners();
  }

  /// Invalidates in-flight account work before publishing the signed-out state.
  void clearSession() {
    if (_isDisposed) return;
    _sessionGeneration++;
    _authRequestId++;
    _expertRequestId++;
    user = null;
    isLoggedIn = false;
    isExpert = false;
    isAdmin = false;
    isLoading = false;
    submission = '';
    _clearExpertRequestMetadata();
    notifyListeners();
  }

  bool _isCurrentSession(int generation) =>
      !_isDisposed && generation == _sessionGeneration;

  bool _isCurrentAuthRequest(int requestId) =>
      !_isDisposed && requestId == _authRequestId;

  bool _isCurrentExpertRequest(int generation, int requestId) =>
      _isCurrentSession(generation) && requestId == _expertRequestId;

  static String? _userIdentity(User? value) {
    if (value == null) return null;
    final id = value.id?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final email = value.email.trim().toLowerCase();
    if (email.isNotEmpty) return 'email:$email';
    return value.username;
  }

  void _applyUser(User user) {
    if (_userIdentity(this.user) != _userIdentity(user) ||
        isExpert != user.isCompositeExpert ||
        isAdmin != user.isAdmin) {
      _sessionGeneration++;
      _expertRequestId++;
      _clearExpertRequestMetadata();
      submission = '';
    }
    this.user = user;
    isLoggedIn = true;
    isExpert = user.isCompositeExpert;
    isAdmin = user.isAdmin;
  }

  Future<void> fetchAuthSessionNew() async {
    if (_isDisposed) return;
    final requestId = ++_authRequestId;
    try {
      final hasSession = await authUseCase.isLoggedIn();
      if (!_isCurrentAuthRequest(requestId)) return;
      if (!hasSession) {
        clearSession();
        return;
      }
      final verified = await _fetchUser(requestId);
      if (verified && _isCurrentAuthRequest(requestId)) {
        await refreshExpertRequestMetadata();
      }
    } catch (error) {
      if (!_isCurrentAuthRequest(requestId)) return;
      if (error is UnauthorizedException) {
        clearSession();
      } else if (kDebugMode) {
        debugPrint('Could not refresh the settings session.');
      }
    } finally {
      if (_isCurrentAuthRequest(requestId)) notifyListeners();
    }
  }

  Future<void> fetchUser() async {
    if (_isDisposed) return;
    await _fetchUser(++_authRequestId);
  }

  Future<bool> _fetchUser(int requestId) async {
    try {
      final fetchedUser = await userUserCase.fetchMe();
      if (!_isCurrentAuthRequest(requestId)) return false;
      _applyUser(fetchedUser);
      return true;
    } catch (error) {
      if (!_isCurrentAuthRequest(requestId)) return false;
      if (error is UnauthorizedException) {
        clearSession();
      } else if (kDebugMode) {
        // A temporary network failure does not establish that a session ended.
        debugPrint('Could not refresh the settings profile.');
      }
      return false;
    } finally {
      if (_isCurrentAuthRequest(requestId)) notifyListeners();
    }
  }

  String? get _currentUserId {
    final id = user?.id?.trim();
    if (id != null && id.isNotEmpty) return id;

    final username = user?.username?.trim();
    if (username != null && username.isNotEmpty) return username;

    return null;
  }

  bool get hasPendingExpertRequest => currentExpertRequest?.status == 'pending';

  bool get hasReviewedExpertRequest {
    final status = currentExpertRequest?.status;
    return status == 'approved' || status == 'denied';
  }

  void _clearExpertRequestMetadata() {
    pendingExpertRequestCount = 0;
    currentExpertRequest = null;
    isLoadingExpertRequestMetadata = false;
  }

  Future<void> refreshExpertRequestMetadata() async {
    if (_isDisposed) return;
    final generation = _sessionGeneration;
    final requestId = ++_expertRequestId;
    if (!isLoggedIn) {
      _clearExpertRequestMetadata();
      notifyListeners();
      return;
    }

    isLoadingExpertRequestMetadata = true;
    notifyListeners();

    try {
      if (isAdmin) {
        final requests = await userUserCase.fetchPendingExpertRequests();
        if (!_isCurrentExpertRequest(generation, requestId)) return;
        pendingExpertRequestCount = requests.length;
        currentExpertRequest = null;
      } else if (!isExpert) {
        final userId = _currentUserId;
        final request = userId == null
            ? null
            : await userUserCase.fetchExpertRequestForUser(userId);
        if (!_isCurrentExpertRequest(generation, requestId)) return;
        currentExpertRequest = request;
        pendingExpertRequestCount = 0;
      } else {
        _clearExpertRequestMetadata();
      }
    } catch (error) {
      if (!_isCurrentExpertRequest(generation, requestId)) return;
      if (error is UnauthorizedException) {
        clearSession();
      } else if (kDebugMode) {
        debugPrint('Could not refresh expert request metadata.');
      }
    } finally {
      if (_isCurrentExpertRequest(generation, requestId)) {
        isLoadingExpertRequestMetadata = false;
        notifyListeners();
      }
    }
  }

  Future<void> initPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (_isDisposed) return;
      version = info.version;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to fetch package info: $e");
      }
    }
  }

  Future<void> newLogout(BuildContext context) async {
    if (_isDisposed || _isLoggingOut) return;
    _isLoggingOut = true;
    final generation = _sessionGeneration;
    try {
      await authUseCase.logout();
      if (!_isCurrentSession(generation)) return;
      clearSession();
      if (!context.mounted) return;

      // Display Snackbar for success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged out"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black,
        ),
      );
    } catch (_) {
      if (!_isCurrentSession(generation)) return;
      if (kDebugMode) debugPrint('Could not clear the local settings session.');
      if (!context.mounted) return;
      // Display Snackbar for error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to log out. Please try again."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionGeneration++;
    _authRequestId++;
    _expertRequestId++;
    super.dispose();
  }

  Future<void> openFeedback() async {
    if (kIsWeb) {
      final url =
          Uri.parse("https://github.com/banghuazhao/swiftcomp-flutter/issues");
      launchUrl(url);
      return;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String device;
    String systemVersion;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
      systemVersion = androidInfo.version.sdkInt.toString();
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
      systemVersion = iosInfo.systemVersion;
    } else {
      device = "";
      systemVersion = "";
    }

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appName = packageInfo.appName;
    final String version = packageInfo.version;

    final Uri params = Uri(
      scheme: 'mailto',
      path: 'appsbayarea@gmail.com',
      query:
          'subject=$appName Feedback&body=\n\n\nVersion=$version\nDevice=$device\nSystem Version=$systemVersion',
    );

    final url = params.toString();
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      debugPrint("Could not launch feedback URL");
    }
  }

  void openAppStore() async {
    if (kIsWeb) {
      // Handle the web case if necessary, such as showing an error or a message.
      debugPrint("App store link is not supported on web.");
      return;
    }

    final Uri androidUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp');
    final Uri iOSUrl = Uri.parse('https://apps.apple.com/app/id1297825946');

    final Uri url = Platform.isAndroid ? androidUrl : iOSUrl;

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open the app store URL';
    }
  }

  void rateApp() async {
    openAppStore();
  }

  Future<void> shareApp(BuildContext context) async {
    final Size size = MediaQuery.sizeOf(context);
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final String appName = packageInfo.appName;

    if (Platform.isIOS) {
      await SharePlus.instance.share(
        ShareParams(
          text: "http://itunes.apple.com/app/id1297825946",
          subject: appName,
          sharePositionOrigin: Rect.fromLTRB(0, 0, size.width, size.height / 2),
        ),
      );
    } else if (Platform.isAndroid) {
      await SharePlus.instance.share(
        ShareParams(
          text:
              "https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp",
          subject: appName,
        ),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: "https://compositesai.com"));
    }
  }

  void handleTap(Function navigateToFeatureFlagPage) {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds > _tapTimeout) {
      _tapCount = 0; // Reset tap count if taps are not continuous
    }
    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == _maxTaps) {
      _tapCount = 0; // Reset tap count after navigating
      navigateToFeatureFlagPage();
    }
  }

  Future<void> updateUserName(String newName) async {
    final generation = _sessionGeneration;
    try {
      // Call the update method in userUserCase to update the name in the backend or database
      await userUserCase.updateMe(newName);
      if (!_isCurrentSession(generation)) return;

      // Update the local user object if it exists
      if (user != null) {
        user!.name = newName; // Update the user’s name
        notifyListeners(); // Notify the UI to refresh
      }
    } catch (_) {
      if (_isCurrentSession(generation)) {
        debugPrint('Could not update the account name.');
      }
    }
  }

  Future<String> submitApplication(String reason, String link) async {
    final generation = _sessionGeneration;
    String result = '';
    try {
      final response = await userUserCase.submitApplication(reason, link);
      if (!_isCurrentSession(generation)) {
        return 'Your session changed. Please try again.';
      }
      submission = response;
      if (submission == 'success') {
        result =
            'Application successfully submitted. Please wait for approval.';
        return result;
      } else if (submission == 'failed') {
        result =
            'This user has already submitted an expert application. Please wait for approval.';
        return result;
      } else {
        result =
            'Submission failed due to an internal error. Please try again later.';
        return result;
      }
    } catch (_) {
      result = 'Submission failed. Please try again later.';
      return result;
    }
  }

  Future<String> submitExpertRequest(String reason, String link) async {
    final userId = _currentUserId;
    if (userId == null) {
      return 'Could not find your user account. Please sign in again.';
    }

    final notes = _buildExpertRequestNotes(reason, link);
    final generation = _sessionGeneration;
    final requestId = ++_expertRequestId;

    try {
      final request = await userUserCase.requestExpertUpgrade(userId, notes);
      if (!_isCurrentExpertRequest(generation, requestId)) {
        return 'Your session changed. Please try again.';
      }
      currentExpertRequest = request;
      isLoadingExpertRequestMetadata = false;
      notifyListeners();
      return 'Application successfully submitted. Please wait for approval.';
    } catch (error) {
      if (!_isCurrentExpertRequest(generation, requestId)) {
        return 'Your session changed. Please try again.';
      }
      final message = error.toString();
      if (message.toLowerCase().contains('cooldown')) {
        return 'You already submitted an expert request recently. Please wait for approval.';
      }
      if (message.toLowerCase().contains('already')) {
        await refreshExpertRequestMetadata();
        return 'This user has already submitted an expert application. Please wait for approval.';
      }
      return 'Submission failed due to an internal error. Please try again later.';
    } finally {
      if (_isCurrentExpertRequest(generation, requestId)) {
        isLoadingExpertRequestMetadata = false;
        notifyListeners();
      }
    }
  }

  String _buildExpertRequestNotes(String reason, String link) {
    final parts = <String>[];
    final trimmedReason = reason.trim();
    final trimmedLink = link.trim();

    if (trimmedReason.isNotEmpty) {
      parts.add('Reason: $trimmedReason');
    }
    if (trimmedLink.isNotEmpty) {
      parts.add('Profile: $trimmedLink');
    }

    return parts.join('\n');
  }

  Future<List<ExpertUpgradeRequest>> fetchPendingExpertRequests() {
    return userUserCase.fetchPendingExpertRequests();
  }

  Future<void> approveExpertRequest(ExpertUpgradeRequest request) {
    final generation = _sessionGeneration;
    return userUserCase.approveExpertRequest(request).then((_) {
      if (!_isCurrentSession(generation)) return;
      if (pendingExpertRequestCount > 0) {
        pendingExpertRequestCount -= 1;
        notifyListeners();
      }
    });
  }

  Future<void> denyExpertRequest(ExpertUpgradeRequest request) {
    final generation = _sessionGeneration;
    return userUserCase.denyExpertRequest(request).then((_) {
      if (!_isCurrentSession(generation)) return;
      if (pendingExpertRequestCount > 0) {
        pendingExpertRequestCount -= 1;
        notifyListeners();
      }
    });
  }
}
