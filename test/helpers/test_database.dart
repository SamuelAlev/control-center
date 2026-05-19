import 'dart:io';

import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds an in-memory [AppDatabase] for tests.
///
/// Mirrors the headless server's `openServerDatabase`: the `sqlite_vector`
/// extension is NOT loaded (it lived in the deleted `cc_app_native` desktop
/// connector). `onCreate`'s vector-index setup degrades gracefully without it
/// — vector search is unavailable in tests, which never exercise it. Points
/// SQLite's temp directory at the system temp dir for scratch files.
///
/// Always construct test databases through this helper rather than calling
/// `AppDatabase.forTesting(NativeDatabase.memory())` directly, so the native
/// setup stays in one place.
AppDatabase createTestDatabase() {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  return AppDatabase.forTesting(NativeDatabase.memory());
}
