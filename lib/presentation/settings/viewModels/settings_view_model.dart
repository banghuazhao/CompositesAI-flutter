// lib/presentation/viewmodels/settings_view_model.dart

import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swiftcomp/presentation/settings/providers/feature_flag_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share/share.dart';


class SettingsViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final UserUseCase userUserCase;
  final FeatureFlagProvider featureFlagProvider;

  bool isLoggedIn = false;
  String version = '';
  User? user;

  int _tapCount = 0;
  final int _maxTaps = 5;
  final int _tapTimeout = 1000; // Timeout in milliseconds
  DateTime _lastTapTime = DateTime.now();

  SettingsViewModel(
      {required this.authUseCase,
      required this.userUserCase,
      required this.featureFlagProvider}) {
    initPackageInfo();
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
    try {
      user = await userUserCase.fetchMe();
      print(user);
      notifyListeners();
    } catch (e) {
      isLoggedIn = false;
    }
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

    final Uri androidUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.banghuazhao.swiftcomp');
    final Uri iOSUrl = Uri.parse('https://apps.apple.com/app/id1297825946');

    final Uri url = Platform.isAndroid ? androidUrl : iOSUrl;

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open the app store URL';
    }
  }

  void rateApp() async {
    try {
      await LaunchReview.launch(
        androidAppId: "com.banghuazhao.swiftcomp",
        iOSAppId: "1297825946",
        writeReview: true,
      );
    } catch (e) {
      // Use fallback to open the app store directly if `LaunchReview` fails
      openAppStore();
    }
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
}
