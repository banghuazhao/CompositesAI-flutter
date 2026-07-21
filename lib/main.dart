import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:infrastructure/in_app_reviewer_helper.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/app_theme.dart';
import 'package:swiftcomp/util/others.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/bottom_navigator.dart';
import 'app/injection_container.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load();
  } catch (error) {
    debugPrint('Failed to load .env: $error');
  }

  InAppReviewHelper.checkAndAskForReview();

  await SharedPreferencesHelper.init();

  initInjection();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
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
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 讲en设置为第一项,没有适配语言时,英语为首选项
          supportedLocales: S.delegate.supportedLocales,
          // 插件目前不完善手动处理简繁体
          localeResolutionCallback: (locale, supportLocales) {
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
          title: 'CompositesAI',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const BottomNavigator(),
        ));
  }
}
