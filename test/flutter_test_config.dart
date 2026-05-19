import 'dart:async';
import 'dart:io';

import 'package:control_center/core/storage/font_cache_path_provider.dart';

/// Runs once before any test file is loaded.
///
/// Sets up a temp directory for [FontCachePathProvider] so that tests which
/// create [ProviderContainer] with the default [databaseProvider] can open
/// a database without hitting real user directories or platform channels.
///
/// IMPORTANT: do NOT call [TestWidgetsFlutterBinding.ensureInitialized] here —
/// `flutter test` manages binding initialization per-test file. Doing it in
/// `testExecutable` causes the whole suite to hang.
///
/// ## Timeouts
/// To prevent any single test from hanging the entire suite, always run with:
/// ```sh
/// flutter test --timeout 30s
/// ```
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Create a fake app-support directory in the system temp folder so
  // FontCachePathProvider can resolve without hitting real user paths.
  final tempDir = Directory.systemTemp.createTempSync('control_center_test_');
  final appSupportDir = Directory('${tempDir.path}/app_support');
  if (!appSupportDir.existsSync()) {
    appSupportDir.createSync(recursive: true);
  }
  FontCachePathProvider.setRealAppSupportDirForTesting(appSupportDir);

  await testMain();

  // Best-effort cleanup.
  try {
    tempDir.deleteSync(recursive: true);
  } catch (_) {}
}
