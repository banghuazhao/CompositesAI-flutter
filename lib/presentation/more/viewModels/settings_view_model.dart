// lib/presentation/viewmodels/settings_view_model.dart

import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:device_info/device_info.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiftcomp/presentation/more/providers/feature_flag_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share/share.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final FeatureFlagProvider featureFlagProvider;

  bool isNewLoginEnabled = false;
  bool isLoggedIn = false;
  bool isSignedIn = false;
  String version = '';
  User? user;

  int _tapCount = 0;
  final int _maxTaps = 5;
  final int _tapTimeout = 1000; // Timeout in milliseconds
  DateTime _lastTapTime = DateTime.now();

  SettingsViewModel(
      {required this.authUseCase, required this.featureFlagProvider}) {
    fetchAuthSession();
    initPackageInfo();
    fetchFeatureFlags();
  }

  Future<void> fetchAuthSession() async {
    try {
      AuthSession authResult = await Amplify.Auth.fetchAuthSession();
      isSignedIn = authResult.isSignedIn;

      notifyListeners();
    } catch (e) {
      print("Failed to fetch auth session: $e");
    }
  }

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await authUseCase.isLoggedIn();
      notifyListeners();
      if (isLoggedIn) {
        fetchUser();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
    }
  }

  Future<void> fetchUser() async {
    user = User(email: "email");
    notifyListeners();
  }

  void fetchFeatureFlags() {
    isNewLoginEnabled = featureFlagProvider.getFeatureFlag('NewLogin');
    notifyListeners();

    featureFlagProvider.addListener(() {
      final newFlagStatus = featureFlagProvider.getFeatureFlag('NewLogin');
      if (newFlagStatus != isNewLoginEnabled) {
        isNewLoginEnabled = newFlagStatus;
        notifyListeners();
      }
    });
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
      Fluttertoast.showToast(
        msg: "Logged out",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      isSignedIn = false;
      Fluttertoast.showToast(
        msg: "Logged out",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      notifyListeners();
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      await Amplify.Auth.deleteUser();
      isSignedIn = false;
      Fluttertoast.showToast(
        msg: "Account deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      notifyListeners();
    } catch (e) {
      print("Account deletion failed: $e");
      Fluttertoast.showToast(
        msg: "Delete account failed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
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

  void rateApp() {
    LaunchReview.launch(
        androidAppId: "com.banghuazhao.swiftcomp", iOSAppId: "1297825946");
  }

  Future<void> shareApp(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String appName = packageInfo.appName;
    final Size size = MediaQuery.of(context).size;

    if (Platform.isIOS) {
      Share.share("http://itunes.apple.com/app/id1297825946",
          subject: appName,
          sharePositionOrigin:
              Rect.fromLTRB(0, 0, size.width, size.height / 2));
    } else {
      Share.share(
          "https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp",
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
}
