import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// `backupTo` is `VACUUM INTO`, and both halves of the split database expose it.
///
/// It is what makes a backup safe on a live WAL database (it takes a read
/// transaction and writes a clean copy, so the server never has to stop), and —
/// on a workspace database — it is the entire implementation of
/// `workspace.export`: one workspace is one file, so exporting it is a single
/// statement rather than a table-by-table dump.
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_db_backup');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('the global database writes a consistent, reopenable snapshot', () async {
    final db = createTestGlobalDatabase();
    await db.workspaceRegistryDao.upsertWorkspace(
      const WorkspacesTableCompanion(
        id: Value('ws-1'),
        name: Value('Backup me'),
      ),
    );

    final backupPath = '${tmp.path}/global-snapshot.sqlite';
    await db.backupTo(backupPath);
    await db.close();

    expect(File(backupPath).existsSync(), isTrue);
    expect(File(backupPath).lengthSync(), greaterThan(0));

    // Reopen the snapshot and confirm the row is present — proves it is a valid,
    // consistent database, not a truncated or locked copy.
    final restored = GlobalDatabase.forTesting(
      NativeDatabase(File(backupPath)),
    );
    addTearDown(restored.close);
    final rows = await restored.workspaceRegistryDao.getAll();
    expect(rows.map((r) => r.name), ['Backup me']);
  });

  test('a workspace database snapshots to one self-contained file', () async {
    final db = createTestDatabase(workspaceId: 'ws-1');
    await db.agentDao.upsert(
      AgentsTableCompanion.insert(
        id: 'a-1',
        name: 'Ada',
        title: 't',
        agentMdPath: '/a.md',
        workspaceId: 'ws-1',
        skills: '',
      ),
    );

    final backupPath = '${tmp.path}/ws-1-snapshot.sqlite';
    await db.backupTo(backupPath);
    await db.close();

    final restored = WorkspaceDatabase.forTesting(
      NativeDatabase(File(backupPath)),
      workspaceId: 'ws-1',
    );
    addTearDown(restored.close);
    expect((await restored.agentDao.getAll()).map((a) => a.name), [
      'Ada',
    ], reason: 'the exported file must stand alone — this is workspace.export');
    // The file knows which workspace it holds, which is what lets an import tell
    // "my own file, re-adopted" from "a file from another install".
    final meta = await restored.select(restored.workspaceMetaTable).get();
    expect(meta.single.workspaceId, 'ws-1');
  });
}
