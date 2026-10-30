import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _startupTimeout = Duration(seconds: 45);
const _actionTimeout = Duration(seconds: 15);

// A plain Dart host driver. Suppress driver transport logs and raw exceptions,
// which may contain a VM-service URL; emit only fixed stage names and booleans.
Future<void> main() async {
  driverLog = (_, __) {};
  FlutterDriver? driver;
  var stage = 'connecting';
  var result = 0;
  try {
    driver = await FlutterDriver.connect(logCommunicationToFile: false)
        .timeout(_startupTimeout);
    stage = 'first native raster';
    await driver.waitUntilFirstFrameRasterized().timeout(_startupTimeout);
    stage = 'production guest screen';
    await driver.waitFor(find.byType('ChatScreen'), timeout: _startupTimeout);
    final guest = await _status(driver);
    _requireStartup(guest);
    _require(guest['guestCurrent'] == true);
    final tooltip = guest['toolsTooltip'];
    _require(tooltip is String && tooltip.isNotEmpty);

    stage = 'tools navigation';
    await driver.tap(find.byTooltip(tooltip as String),
        timeout: _actionTimeout);
    await driver.waitFor(find.byType('ToolPage'), timeout: _actionTimeout);
    final tools = await _status(driver);
    _requireStartup(tools);
    _require(tools['toolsCurrent'] == true);

    stage = 'back navigation';
    await driver.tap(find.byType('BackButton'), timeout: _actionTimeout);
    await driver.waitForAbsent(find.byType('ToolPage'),
        timeout: _actionTimeout);
    await driver.waitFor(find.byType('ChatScreen'), timeout: _actionTimeout);
    final returned = await _status(driver);
    _requireStartup(returned);
    _require(returned['guestCurrent'] == true);
    stdout.writeln('iOS startup smoke passed: first native raster, production '
        'main, signed-out state, native preferences/package, tools and back.');
  } catch (_) {
    result = 1;
    stderr.writeln('iOS startup smoke failed during $stage. '
        'Native rasterization is not verified unless the complete flow passes.');
  } finally {
    if (driver != null) {
      try {
        await driver.close().timeout(_actionTimeout);
      } catch (_) {
        result = 1;
        stderr.writeln('iOS startup smoke could not close its driver cleanly.');
      }
    }
  }
  // A timed-out connection may still hold a socket; do not leave a host process
  // running indefinitely or turn an incomplete verification into a success.
  exit(result);
}

Future<Map<String, dynamic>> _status(FlutterDriver driver) async {
  final decoded = jsonDecode(
      await driver.requestData('startup-status', timeout: _actionTimeout));
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Invalid startup status.');
  }
  return decoded;
}

void _requireStartup(Map<String, dynamic> state) {
  for (final key in [
    'supportedRequest',
    'nativeIOS',
    'precheckComplete',
    'freshSession',
    'noInitialRaster',
    'productionMainStarted',
    'productionOwnedDeferral',
    'framesReleased',
    'firstFrameRasterized',
    'signedOut',
    'preferencesReady',
    'packageReady',
  ]) {
    _require(state[key] == true);
  }
  _require(state['blocked'] == false);
  _require(state['packageName'] == 'com.cdmHUB.SwiftComp');
  _require(
      state['version'] is String && (state['version'] as String).isNotEmpty);
  _require(state['buildNumber'] is String &&
      (state['buildNumber'] as String).isNotEmpty);
}

void _require(bool condition) {
  if (!condition) throw StateError('A startup smoke requirement was not met.');
}
