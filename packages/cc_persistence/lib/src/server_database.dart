import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

/// Opens the Control Center SQLite database for the **headless server**, with
/// no Flutter dependency.
///
/// This is the pure-Dart counterpart to the desktop app's connection (which
/// resolves its file path through `path_provider` and bundles the native
/// sqlite via `sqlite3_flutter_libs`). Here the caller supplies an explicit
/// [dataDir] (from an env var / `dart:io`) and the native `libsqlite3` is
/// bundled by the `sqlite3` package's build hook when the server is compiled
/// with `dart build cli` — so the resulting binary needs neither the Flutter
/// engine nor a system sqlite.
///
/// Returns a lazily-opened [QueryExecutor]; pass it to the generated
/// `AppDatabase(connection)` once the schema is extracted into this package.
///
/// The vector-search extension (`sqlite_vector`) IS loaded here so the server's
/// embedding/semantic queries work (`vector_init` on `memory_facts_table` +
/// `code_symbols`, and `vector_full_scan` for KNN search). It is registered as a
/// process-global SQLite auto-extension *before* the connection is opened, so it
/// applies to the connection drift opens on its background isolate. The native
/// library is a prebuilt `DynamicLoadingBundled` code asset that `dart build
/// cli` bundles beside the binary (same mechanism as libsqlite3). If the asset
/// is ever unavailable, `AppDatabase` still degrades gracefully — its
/// `vector_init` calls warn and skip rather than crash.
QueryExecutor openServerDatabase({
  required String dataDir,
  // Matches CcPaths.databaseFile() ('control_center.db') so a desktop-spawned
  // local server opens the SAME database the desktop already created under its
  // app-support root — no data loss across the thin-client flip. (Older headless
  // deployments that created 'control_center.sqlite' have no production data.)
  String fileName = 'control_center.db',
}) {
  return LazyDatabase(() async {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    // Keep sqlite's scratch files inside the data dir (mirrors the app).
    sqlite3.sqlite3.tempDirectory = dir.path;
    // Register the vector-search extension as a process-global auto-extension
    // BEFORE opening, so the connection drift opens on its background isolate
    // has vector_init/vector_full_scan available. Best-effort: a missing/broken
    // native asset must not block the database — AppDatabase already degrades
    // gracefully (its vector_init calls warn and skip).
    try {
      sqlite3.sqlite3.loadSqliteVectorExtension();
    } on Object {
      // Extension unavailable on this build/platform — vector search degrades.
    }
    return NativeDatabase.createInBackground(file);
  });
}
