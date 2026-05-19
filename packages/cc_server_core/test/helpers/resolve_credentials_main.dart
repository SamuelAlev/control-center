// A fixture for `cc_server_config_credentials_test.dart`, not a test.
//
// `CcServerConfig.resolve` reads `Platform.environment`, which a running test
// cannot change, so the environment tier of the credential precedence is
// exercised by spawning this in a child process with the variables set. Prints
// one JSON object per argument group (groups separated by `--`), so a single
// spawn can cover several flag combinations under one environment.
//
// ignore_for_file: avoid_print — stdout IS this fixture's interface.
import 'dart:convert';

import 'package:cc_server_core/cc_server_core.dart';

void main(List<String> args) {
  final groups = <List<String>>[[]];
  for (final arg in args) {
    arg == '--' ? groups.add([]) : groups.last.add(arg);
  }
  for (final group in groups) {
    final config = CcServerConfig.resolve(group);
    print(
      jsonEncode({
        'googleClientId': config.googleClientId,
        'googleClientSecret': config.googleClientSecret,
        'klipyAppKey': config.klipyAppKey,
        'klipyConfigured': config.klipyConfigured,
      }),
    );
  }
}
