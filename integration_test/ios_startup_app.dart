import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/main.dart' as app;
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';
import 'package:swiftcomp/presentation/tools/page/tool_page.dart';
import 'package:swiftcomp/util/others.dart';

// Driver-only entry point. The extension uses the normal Flutter frame pipeline;
// no IntegrationTest/WidgetTester binding, empty test frame or fake plugins are
// involved. Never include this entry point in a production release.
Future<void> main() async {
  final probe = _StartupProbe();
  enableFlutterDriverExtension(
    handler: probe.handleRequest,
    enableTextEntryEmulation: false,
  );
  final binding = WidgetsBinding.instance;
  probe.noInitialRaster = !binding.firstFrameRasterized;
  binding.deferFirstFrame();

  // Refuse a signed-in profile without clearing, changing or exposing its token.
  try {
    if (!kIsWeb && Platform.isIOS) {
      probe.freshSession =
          (await TokenProvider().getToken())?.trim().isNotEmpty != true;
    }
  } catch (_) {
    // The host receives a boolean failure; native error details stay private.
  }
  probe.precheckComplete = true;
  if (!probe.freshSession) {
    probe.blocked = true;
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
              'Startup smoke blocked. Use a fresh signed-out iOS profile.'),
        ),
      ),
    ));
    binding.allowFirstFrame();
    return;
  }

  // main() synchronously preserves its own splash frame before its first await.
  // Release only our temporary precheck hold; production removes its own splash.
  probe.productionMainStarted = true;
  app.main();
  binding.allowFirstFrame();
  probe.productionOwnedDeferral = !binding.sendFramesToEngine;
}

class _StartupProbe {
  bool noInitialRaster = false;
  bool precheckComplete = false;
  bool freshSession = false;
  bool blocked = false;
  bool productionMainStarted = false;
  bool productionOwnedDeferral = false;

  Future<String> handleRequest(String? message) async {
    if (message != 'startup-status') {
      return jsonEncode({'supportedRequest': false});
    }
    final binding = WidgetsBinding.instance;
    Element? chat;
    Element? tools;
    void visit(Element element) {
      if (element.widget is ChatScreen) chat = element;
      if (element.widget is ToolPage) tools = element;
      element.visitChildren(visit);
    }

    binding.rootElement?.visitChildren(visit);
    final chatContext = chat;
    final toolsContext = tools;
    var signedOut = false;
    var preferencesReady = false;
    var toolsTooltip = '';
    if (chatContext != null && chatContext.mounted) {
      final model = chatContext.read<ChatViewModel>();
      signedOut = !model.isDisposed &&
          !model.isLoggedIn &&
          model.user == null &&
          model.selectedChat == null &&
          model.messages.isEmpty;
      toolsTooltip = S.maybeOf(chatContext)?.Chat_composite_calculators ??
          'Composite Calculators';
    }
    try {
      // Do not return any preference keys or stored values to the host.
      SharedPreferencesHelper.localStorage.getKeys();
      preferencesReady = true;
    } catch (_) {
      // Production has not initialized native preferences successfully.
    }
    PackageInfo? package;
    try {
      package = await PackageInfo.fromPlatform();
    } catch (_) {
      // Report only the failure flag, never native exception contents.
    }
    return jsonEncode({
      'supportedRequest': true,
      'nativeIOS': !kIsWeb && Platform.isIOS,
      'precheckComplete': precheckComplete,
      'freshSession': freshSession,
      'blocked': blocked,
      'noInitialRaster': noInitialRaster,
      'productionMainStarted': productionMainStarted,
      'productionOwnedDeferral': productionOwnedDeferral,
      'framesReleased': binding.sendFramesToEngine,
      'firstFrameRasterized': binding.firstFrameRasterized,
      'signedOut': signedOut,
      'guestCurrent': chatContext != null &&
          chatContext.mounted &&
          ModalRoute.of(chatContext)?.isCurrent == true &&
          signedOut,
      'toolsCurrent': toolsContext != null &&
          toolsContext.mounted &&
          ModalRoute.of(toolsContext)?.isCurrent == true &&
          signedOut,
      'preferencesReady': preferencesReady,
      'packageReady': package != null,
      'packageName': package?.packageName ?? '',
      'version': package?.version ?? '',
      'buildNumber': package?.buildNumber ?? '',
      'toolsTooltip': toolsTooltip,
    });
  }
}
