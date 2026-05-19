import 'dart:io';

import 'package:control_center/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

/// Builds an in-memory [AppDatabase] for tests.
///
/// Loads the sqlite_vector extension globally (mirroring production's
/// `_openConnection`) so `vector_init` is available; without it `onCreate`'s
/// vector-index setup logs a "sqlite_vector extension unavailable" warning
/// once per vector table on every database build. Also points SQLite's temp
/// directory at the system temp dir for scratch files.
///
/// Always construct test databases through this helper rather than calling
/// `AppDatabase.forTesting(NativeDatabase.memory())` directly, so the native
/// setup stays in one place.
AppDatabase createTestDatabase() {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  sqlite3.sqlite3.loadSqliteVectorExtension();
  return AppDatabase.forTesting(NativeDatabase.memory());
}
