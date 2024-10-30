import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/providers/feature_flag_provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/in_app_reviewer_helper.dart';
import 'package:swiftcomp/util/others.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'presentation/bottom_navigator.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  Future.delayed(Duration(seconds: 1), () {
    AppTrackingTransparency.requestTrackingAuthorization();
  });

  InAppReviewHelper.checkAndAskForReview();

  await SharedPreferencesHelper.init();

  initInjection();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _configureAmplify() async {
    try {
      // Add the following line to add Auth plugin to your app.
      await Amplify.addPlugin(AmplifyAuthCognito());

      // call Amplify.configure to use the initialized categories in your app
      final amplifyconfig = dotenv.env['AMPLIFY_CONFIG'] ?? "";
      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      print('An error occurred configuring Amplify: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _configureAmplify();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => NumberPrecisionHelper()),
          ChangeNotifierProvider(
              create: (context) => sl<FeatureFlagProvider>()),
          ChangeNotifierProvider(create: (context) => sl<SettingsViewModel>()),
          ChangeNotifierProvider(create: (context) => sl<ChatViewModel>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 讲en设置为第一项,没有适配语言时,英语为首选项
          supportedLocales: S.delegate.supportedLocales,
          // 插件目前不完善手动处理简繁体
          localeResolutionCallback: (locale, supportLocales) {
            print(locale);
            // 中文 简繁体处理
            if (locale?.languageCode == 'zh') {
              if (locale?.scriptCode == 'Hant') {
                return const Locale('zh', 'HK'); //繁体
              } else {
                return const Locale('zh', ''); //简体
              }
            }
            return Locale('en', '');
          },
          title: 'SwiftComp',
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(51, 66, 78, 1),
              secondary: Color.fromRGBO(51, 66, 78, 1),
              onSecondary: Colors.white,
            ),
            appBarTheme: AppBarTheme(
                color: Color.fromRGBO(51, 66, 78, 1),
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20)),
            scaffoldBackgroundColor: const Color.fromRGBO(239, 239, 244, 1),
            textTheme: const TextTheme(),
          ),
          home: const BottomNavigator(),
        ));
  }
}
