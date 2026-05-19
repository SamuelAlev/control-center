import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';

/// Smoke entrypoint: opens the REAL full `AppDatabase` (all 49 tables + the
/// migration strategy + FTS5) over the pure-Dart `openServerDatabase`
/// connection, with NO Flutter. Proves the whole schema compiles into a
/// Flutter-free `dart build cli` native binary and runs real SQLite I/O — the
/// foundation of the headless server. Not shipped; this is the de-risk artifact.
Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('cc_persistence_smoke');
  // openServerDatabase loads the sqlite_vector extension, so vector_init on the
  // memory-facts + code-graph tables succeeds (no onWarn) when the native code
  // asset is bundled; it still degrades gracefully if the asset is missing.
  final db = AppDatabase(
    openServerDatabase(dataDir: tmp.path),
    onWarn: (tag, msg) => stdout.writeln('[warn] $tag: $msg'),
    onError: (tag, msg) => stderr.writeln('[error] $tag: $msg'),
  );

  // Force the connection open + run the full onCreate (creates every table).
  final workspaces = await db.workspaceDao.getAll();
  stdout.writeln(
    'cc_persistence AppDatabase OK schemaVersion=${db.schemaVersion} '
    'workspaces=${workspaces.length}',
  );
  await db.close();
  tmp.deleteSync(recursive: true);
}
