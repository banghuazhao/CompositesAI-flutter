import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 14),
      writeResponseOnFailure: true,
      responseDataCallback: (data) async {
        if (data != null) {
          stdout.writeln('LOGIN_SMOKE_RESULT ${jsonEncode(data)}');
        }
      },
    );
