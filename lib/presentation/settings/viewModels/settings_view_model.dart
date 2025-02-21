// lib/presentation/viewmodels/settings_view_model.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:domain/entities/linkedinuserprofile.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  int _tapCount = 0;
  final int _maxTaps = 5;
  final int _tapTimeout = 1000; // Timeout in milliseconds
  DateTime _lastTapTime = DateTime.now();

  SettingsViewModel(
      {required this.authUseCase, required this.userUserCase, required this.featureFlagProvider}) {
    initPackageInfo();
    fetchAuthSessionNew();
  }

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await authUseCase.isLoggedIn();
      if (isLoggedIn) {
        await fetchUser();
      } else {
        user = null; // Ensure user is null if not logged in
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
      user = null; // Ensure proper reset
    }
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      user = await userUserCase.fetchMe();
      print("user: " + user.toString());
      isLoggedIn = true;
      isExpert = user!.isCompositeExpert;
      isAdmin = user!.isAdmin; // Ensure isLoggedIn is updated correctly
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false; // Handle fetch user failure
      user = null;
    }
    notifyListeners();
  }

  Future<void> initPackageInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      version = info.version;
      notifyListeners();
    } catch (e) {
      print("Failed to fetch package info: $e");
    }
  }

  Future<void> newLogout(BuildContext context) async {
    try {
      await authUseCase.logout();

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
        print(e);
      }
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
      print("Could not launch feedback URL");
    }
  }

  void openAppStore() async {
    if (kIsWeb) {
      // Handle the web case if necessary, such as showing an error or a message.
      print("App store link is not supported on web.");
      return;
    }

    final Uri androidUrl =
        Uri.parse('https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp');
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
    final packageInfo = await PackageInfo.fromPlatform();
    final String appName = packageInfo.appName;
    final Size size = MediaQuery.of(context).size;

    if (Platform.isIOS) {
      Share.share("http://itunes.apple.com/app/id1297825946",
          subject: appName, sharePositionOrigin: Rect.fromLTRB(0, 0, size.width, size.height / 2));
    } else {
      Share.share("https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp",
          subject: appName);
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
      print("Failed to update user name: $error");
    }
  }

  Future<String> submitApplication(String reason, String link) async {
    String result = '';
    try {
      submission = await userUserCase.submitApplication(reason, link);
      if (submission == 'success') {
        result = 'Application successfully submitted. Please wait for approval.';
        return result;
      } else if (submission == 'failed') {
        result = 'This user has already submitted an expert application. Please wait for approval.';
        return result;
      } else {
        result = 'Submission failed due to an internal error. Please try again later.';
        return result;
      }
    } catch (error) {
      result = 'failed to submit: $error';
      return result;
    }
  }

  // LinkedIn Credentials
  Future<void> handleAuthorizationCodeFromLinked(String? authorizationCode) async {
    isLoading = true;
    notifyListeners();

    if (authorizationCode == null) {
      throw Exception("Failed to get authorization code from LinkedIn.");
    }
    print("authorizationCode: " + authorizationCode);

    // **Step 3: Exchange Code for Access Token**
    final accessToken = await authUseCase.handleAuthorizationCodeFromLinked(authorizationCode);

    if (accessToken == null) {
      throw Exception("Failed to get access token.");
    }
    print("accessToken: " + accessToken);

    // **Step 4: Fetch LinkedIn User Info**
    final LinkedinUserProfile userProfile = await authUseCase.fetchLinkedInUserProfile(accessToken);

    print('LinkedinUserProfile: ' + userProfile.toString());
    final email = userProfile.email;
    final String? name = userProfile.name;
    final String? profile = userProfile.picture;

    await syncUser(name, email, profile);
    await fetchAuthSessionNew();
    isLoading = false;
    notifyListeners();
  }

  Future<void> syncUser(String? displayName, String email, String? photoUrl) async {
    await authUseCase.syncUser(displayName, email, photoUrl);
  }
}
