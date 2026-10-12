import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/catalog_file.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  const ref =
      'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const other =
      'blob:sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test(
    'fresh schema catalogs artifacts and uploads without a global table',
    () async {
      final global = createTestGlobalDatabase();
      final dbs = createTestWorkspaceDatabases(global: global);
      addTearDown(dbs.closeAll);
      addTearDown(global.close);
      final catalog = DaoFileCatalogRepository(dbs);
      final upload = await catalog.createUpload(
        workspaceId: 'ws',
        uploaderUserId: 'alice',
        name: 'sheet.csv',
        path: ref,
        mediaType: 'text/csv',
        bytes: 3,
        ownedBytes: true,
      );
      expect(upload.state, CatalogFileState.draft);
      expect(upload.ownedBytes, isTrue);
      expect((await catalog.byId('ws', upload.id))!.name, 'sheet.csv');
      expect(await catalog.byId('foreign', upload.id), isNull);
      final artifact = await catalog.recordArtifact(
        workspaceId: 'ws',
        name: 'screenshot.png',
        path: other,
        mediaType: 'image/png',
        bytes: 9,
        creatorId: 'agent-7',
      );
      expect(artifact.creatorId, 'agent-7');
      expect(
        (await catalog.recordArtifact(
          workspaceId: 'ws',
          name: 'updated.png',
          path: other,
          mediaType: 'image/png',
          bytes: 10,
        )).id,
        artifact.id,
      );
      final globalTables = await global
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'catalog_files'",
          )
          .get();
      expect(globalTables, isEmpty);
    },
  );

  test(
    'workspace mismatch and foreign uploader cannot promote or discard',
    () async {
      final global = createTestGlobalDatabase();
      final dbs = createTestWorkspaceDatabases(global: global);
      addTearDown(dbs.closeAll);
      addTearDown(global.close);
      final catalog = DaoFileCatalogRepository(dbs);
      final upload = await catalog.createUpload(
        workspaceId: 'ws1',
        uploaderUserId: 'alice',
        name: 'a',
        path: ref,
        mediaType: 'text/plain',
        bytes: 1,
      );
      final reference = (fileId: upload.id, path: ref);
      await expectLater(
        catalog.claim('ws2', 'alice', [reference]),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        catalog.claim('ws1', 'bob', [reference]),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        catalog.claim('ws1', 'alice', [(fileId: upload.id, path: other)]),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        catalog.discard('ws1', 'bob', upload.id),
        throwsA(isA<ValidationException>()),
      );
      expect(
        (await catalog.byId('ws1', upload.id))!.state,
        CatalogFileState.draft,
      );
      await catalog.claim('ws1', 'alice', [reference]);
      expect(
        (await catalog.byId('ws1', upload.id))!.state,
        CatalogFileState.attached,
      );
      await expectLater(
        catalog.discard('ws1', 'alice', upload.id),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'removal is idempotent and cannot reclaim shared or historic bytes',
    () async {
      final global = createTestGlobalDatabase();
      final dbs = createTestWorkspaceDatabases(global: global);
      addTearDown(dbs.closeAll);
      addTearDown(global.close);
      final catalog = DaoFileCatalogRepository(dbs);
      final first = await catalog.createUpload(
        workspaceId: 'ws',
        uploaderUserId: 'alice',
        name: 'a',
        path: ref,
        mediaType: 'image/png',
        bytes: 4,
        ownedBytes: true,
      );
      final second = await catalog.createUpload(
        workspaceId: 'ws',
        uploaderUserId: 'alice',
        name: 'b',
        path: ref,
        mediaType: 'image/png',
        bytes: 4,
      );
      await catalog.discard('ws', 'alice', first.id);
      await catalog.discard('ws', 'alice', first.id);
      expect(await catalog.canReclaim('ws', ref), isFalse);
      await catalog.claim('ws', 'alice', [(fileId: second.id, path: ref)]);
      expect(await catalog.canReclaim('ws', ref), isFalse);
      final third = await catalog.createUpload(
        workspaceId: 'ws',
        uploaderUserId: 'alice',
        name: 'c',
        path: other,
        mediaType: 'text/plain',
        bytes: 4,
        ownedBytes: true,
      );
      await catalog.discard('ws', 'alice', third.id);
      expect(await catalog.canReclaim('ws', other), isTrue);
      await catalog.recordArtifact(
        workspaceId: 'ws',
        name: 'agent-output',
        path: other,
        mediaType: 'text/plain',
        bytes: 4,
      );
      expect(await catalog.canReclaim('ws', other), isFalse);
    },
  );

  test('v19 migration backfills old message refs', () async {
    final root = await Directory.systemTemp.createTemp('catalog-v19-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/workspace.db');
    final setup = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'ws',
    );
    await setup.customStatement('''
      INSERT INTO spaces (id, workspace_id, name, created_at, updated_at)
      VALUES ('space', 'ws', 'Space', 0, 0)
    ''');
    await setup.customStatement('''
      INSERT INTO conversations (id, workspace_id, space_id, created_at, updated_at)
      VALUES ('conv', 'ws', 'space', 0, 0)
    ''');
    await setup.customStatement(
      '''
      INSERT INTO conversation_messages
        (id, space_id, conversation_id, sender_id, sender_type, content, metadata,
         created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0)
    ''',
      [
        'message',
        'space',
        'conv',
        'alice',
        'user',
        'file',
        jsonEncode({
          'attachments': [
            {'name': 'old.png', 'path': ref, 'size': 4},
          ],
        }),
      ],
    );
    await setup.customStatement('DROP TABLE catalog_files');
    await setup.customStatement('PRAGMA user_version = 19');
    await setup.close();
    final db = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'ws',
    );
    addTearDown(db.close);
    final rows = await db.customSelect('SELECT * FROM catalog_files').get();
    expect(rows, hasLength(1));
    expect(rows.single.read<String>('path'), ref);
    expect(rows.single.read<String>('state'), 'attached');
    expect(rows.single.read<int>('owned_bytes'), 0);
  });
}
