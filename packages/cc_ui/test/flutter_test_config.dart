import 'dart:async';

import 'package:cc_ui/cc_ui.dart';

/// Runs once per test file: keeps script-companion FontLoads out of widget
/// tests (see [CcFonts.loadScriptFonts]).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CcFonts.loadScriptFonts = false;
  await testMain();
}
