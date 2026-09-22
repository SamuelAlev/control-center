import 'dart:async';
import 'dart:io';

import 'package:control_center/core/storage/app_support_path_provider.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;

/// Runs once before any test file: temp dir for [AppSupportPathProvider].
/// Do NOT call [TestWidgetsFlutterBinding.ensureInitialized] here — hangs the
/// suite. Prefer `flutter test --timeout 30s`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Create a fake app-support directory in the system temp folder so
  // AppSupportPathProvider can resolve without hitting real user paths.
  final tempDir = Directory.systemTemp.createTempSync('control_center_test_');
  final appSupportDir = Directory('${tempDir.path}/app_support');
  if (!appSupportDir.existsSync()) {
    appSupportDir.createSync(recursive: true);
  }
  AppSupportPathProvider.setRealAppSupportDirForTesting(appSupportDir);

  await testMain();

  // Best-effort cleanup.
  try {
    tempDir.deleteSync(recursive: true);
  } catch (_) {}
}
