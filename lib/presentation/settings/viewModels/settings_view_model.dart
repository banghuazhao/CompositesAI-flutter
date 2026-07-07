// lib/presentation/viewmodels/settings_view_model.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:domain/auth/entities/expert_upgrade_request.dart';
import 'package:domain/auth/entities/linkedin_user_profile.dart';
import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';
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

  SettingsViewModel(
      {required this.authUseCase,
      required this.userUserCase,
      required this.featureFlagProvider}) {
    initPackageInfo();
    fetchAuthSessionNew();
  }

  void updateUser(User user) {
    this.user = user;
    isLoggedIn = true;
    isExpert = user.isCompositeExpert;
    isAdmin = user.isAdmin; // Ensure isLoggedIn is updated correctly
    notifyListeners();
  }

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await authUseCase.isLoggedIn();
      if (isLoggedIn) {
        await fetchUser();
        await refreshExpertRequestMetadata();
      } else {
        user = null; // Ensure user is null if not logged in
        _clearExpertRequestMetadata();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }
      isLoggedIn = false;
      user = null; // Ensure proper reset
      _clearExpertRequestMetadata();
    }
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      user = await userUserCase.fetchMe();
      if (kDebugMode) {
        debugPrint('user: $user');
      }
      isLoggedIn = true;
      isExpert = user!.isCompositeExpert;
      isAdmin = user!.isAdmin; // Ensure isLoggedIn is updated correctly
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }
      isLoggedIn = false; // Handle fetch user failure
      user = null;
      _clearExpertRequestMetadata();
    }
    notifyListeners();
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
        pendingExpertRequestCount = requests.length;
        currentExpertRequest = null;
      } else if (!isExpert) {
        final userId = _currentUserId;
        currentExpertRequest = userId == null
            ? null
            : await userUserCase.fetchExpertRequestForUser(userId);
        pendingExpertRequestCount = 0;
      } else {
        _clearExpertRequestMetadata();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to refresh expert request metadata: $error');
      }
    } finally {
      isLoadingExpertRequestMetadata = false;
      notifyListeners();
    }
  }

  Future<void> initPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      version = info.version;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to fetch package info: $e");
      }
    }
  }

  Future<void> newLogout(BuildContext context) async {
    try {
      await authUseCase.logout();
      if (!context.mounted) return;

      // Display Snackbar for success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged out"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black,
        ),
      );
      isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }
      if (!context.mounted) return;
      // Display Snackbar for error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to log out. Please try again."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    try {
      // Call the update method in userUserCase to update the name in the backend or database
      await userUserCase.updateMe(newName);

      // Update the local user object if it exists
      if (user != null) {
        user!.name = newName; // Update the user’s name
        notifyListeners(); // Notify the UI to refresh
      }
    } catch (error) {
      // Handle any errors that may occur
      debugPrint("Failed to update user name: $error");
    }
  }

  Future<String> submitApplication(String reason, String link) async {
    String result = '';
    try {
      submission = await userUserCase.submitApplication(reason, link);
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
    } catch (error) {
      result = 'failed to submit: $error';
      return result;
    }
  }

  Future<String> submitExpertRequest(String reason, String link) async {
    final userId = _currentUserId;
    if (userId == null) {
      return 'Could not find your user account. Please sign in again.';
    }

    final notes = _buildExpertRequestNotes(reason, link);

    try {
      currentExpertRequest =
          await userUserCase.requestExpertUpgrade(userId, notes);
      notifyListeners();
      return 'Application successfully submitted. Please wait for approval.';
    } catch (error) {
      final message = error.toString();
      if (message.toLowerCase().contains('cooldown')) {
        return 'You already submitted an expert request recently. Please wait for approval.';
      }
      if (message.toLowerCase().contains('already')) {
        await refreshExpertRequestMetadata();
        return 'This user has already submitted an expert application. Please wait for approval.';
      }
      return 'Submission failed due to an internal error. Please try again later.';
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
    return userUserCase.approveExpertRequest(request).then((_) {
      if (pendingExpertRequestCount > 0) {
        pendingExpertRequestCount -= 1;
        notifyListeners();
      }
    });
  }

  Future<void> denyExpertRequest(ExpertUpgradeRequest request) {
    return userUserCase.denyExpertRequest(request).then((_) {
      if (pendingExpertRequestCount > 0) {
        pendingExpertRequestCount -= 1;
        notifyListeners();
      }
    });
  }

  // LinkedIn Credentials
  Future<void> handleAuthorizationCodeFromLinked(
      String? authorizationCode) async {
    isLoading = true;
    notifyListeners();

    if (authorizationCode == null) {
      throw Exception("Failed to get authorization code from LinkedIn.");
    }
    if (kDebugMode) {
      debugPrint("authorizationCode: $authorizationCode");
    }

    // **Step 3: Exchange Code for Access Token**
    final accessToken =
        await authUseCase.handleAuthorizationCodeFromLinked(authorizationCode);

    if (kDebugMode) {
      debugPrint("accessToken: $accessToken");
    }

    // **Step 4: Fetch LinkedIn User Info**
    final LinkedinUserProfile userProfile =
        await authUseCase.fetchLinkedInUserProfile(accessToken);

    if (kDebugMode) {
      debugPrint('LinkedinUserProfile: $userProfile');
    }
    final email = userProfile.email;
    final String? name = userProfile.name;
    final String? profile = userProfile.picture;

    await syncUser(name, email, profile);
    await fetchAuthSessionNew();
    isLoading = false;
    notifyListeners();
  }

  Future<void> syncUser(
      String? displayName, String email, String? photoUrl) async {
    await authUseCase.syncUser(displayName, email, photoUrl);
  }
}
