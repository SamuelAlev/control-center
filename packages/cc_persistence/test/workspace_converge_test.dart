import 'dart:io';
import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';

/// What happens to a workspace file that an earlier build wrote.
///
/// There is no ladder of steps to test one by one. A file of any earlier
/// version is converged to the declared schema, so the tests start from the
/// schemas installs really hold (`test/fixtures/schema`) and check the one
/// property that matters: the file ends up exactly as a fresh one, with its
/// rows.
void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('cc_ws_converge');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    file = File('${tmp.path}/workspace.db');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  final warnings = <String>[];
  setUp(warnings.clear);

  WorkspaceDatabase open({String? snapshots}) {
    final db = WorkspaceDatabase(
      NativeDatabase(file),
      workspaceId: 'ws',
      upgradeSnapshotDirectory: snapshots,
      onWarn: (tag, message) => warnings.add('$tag: $message'),
    );
    addTearDown(db.close);
    return db;
  }

  Future<int> pragma(WorkspaceDatabase db, String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).read<int>(name);

  Future<List<Object?>> column(WorkspaceDatabase db, String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data.values.first,
  ];

  /// The rows a real file would hold, written the way the old build wrote
  /// them (the fixture's own triggers feed its full-text indexes).
  void seed(sqlite3.Database db) {
    db
      ..execute(
        'INSERT INTO workspace_meta (id, workspace_id, install_id, '
        "created_with_schema_version) VALUES (0, 'ws', 'install-1', 1)",
      )
      ..execute(
        'INSERT INTO spaces (id, name, workspace_id) '
        "VALUES ('s1', 'General', 'ws')",
      )
      ..execute(
        'INSERT INTO conversations (id, workspace_id, space_id) '
        "VALUES ('c1', 'ws', 's1')",
      )
      ..execute(
        'INSERT INTO conversation_messages '
        '(id, space_id, conversation_id, sender_id, sender_type, content) '
        "VALUES ('m1', 's1', 'c1', 'u1', 'user', 'the heron landed'), "
        "('m2', 's1', 'c1', 'u1', 'user', 'a second message')",
      )
      ..execute(
        'INSERT INTO memory_facts (id, workspace_id, domain, topic, content) '
        "VALUES ('f1', 'ws', 'ops', 'birds', 'herons fish at dawn')",
      )
      ..execute(
        'INSERT INTO catalog_events '
        '(id, workspace_id, component_id, kind, occurred_at) '
        "VALUES ('e1', 'ws', 'comp', 'deploy', 0)",
      );
  }

  for (final name in [
    'workspace_v29_a',
    'workspace_v29_b',
    'workspace_v29_c',
  ]) {
    test('$name converges to the schema of a fresh file and keeps its '
        'rows', () async {
      SchemaFixture.load(name).writeTo(file.path, seed: seed);

      final db = open();

      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(
        await pragma(db, 'application_id'),
        WorkspaceDatabase.fileApplicationId,
      );
      expect(await pragma(db, 'foreign_keys'), 1);
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);

      expect(await column(db, 'SELECT name FROM spaces'), ['General']);
      expect(
        await column(db, 'SELECT id FROM conversation_messages ORDER BY id'),
        ['m1', 'm2'],
      );
      expect(await column(db, 'SELECT install_id FROM workspace_meta'), [
        'install-1',
      ]);

      // The tables no table class declares any more are gone, and the log
      // says so.
      final report = db.lastConvergeReport!;
      expect(report.droppedTables, contains('catalog_events'));
      expect(
        await column(
          db,
          "SELECT name FROM sqlite_master WHERE name LIKE 'catalog_%' "
          "AND type = 'table' AND name != 'catalog_files'",
        ),
        isEmpty,
      );
      expect(
        warnings.single,
        allOf(
          startsWith('SchemaConverge: workspace ws v29 -> v'),
          contains('catalog_events'),
        ),
      );
    });
  }

  test('search still finds what the file held, and keeps following '
      'writes', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

    final db = open();

    Future<List<Object?>> messagesMatching(String term) => column(
      db,
      'SELECT m.id FROM conversation_messages_fts f '
      'JOIN conversation_messages m ON m.rowid = f.rowid '
      "WHERE conversation_messages_fts MATCH '$term'",
    );

    expect(await messagesMatching('heron'), ['m1']);
    expect(
      await column(
        db,
        'SELECT m.id FROM memory_facts_fts f '
        'JOIN memory_facts m ON m.rowid = f.rowid '
        "WHERE memory_facts_fts MATCH 'herons'",
      ),
      ['f1'],
    );

    // The sync triggers were dropped with every other trigger and installed
    // again on open: an edit and a delete both reach the index.
    await db.customStatement(
      "UPDATE conversation_messages SET content = 'the egret left' "
      "WHERE id = 'm1'",
    );
    await db.customStatement(
      "DELETE FROM conversation_messages WHERE id = 'm2'",
    );
    expect(await messagesMatching('heron'), isEmpty);
    expect(await messagesMatching('egret'), ['m1']);
    expect(await messagesMatching('second'), isEmpty);
    // An external-content index checks itself against its content table.
    await db.customStatement(
      'INSERT INTO conversation_messages_fts(conversation_messages_fts, rank) '
      "VALUES ('integrity-check', 1)",
    );
  });

  test('a converged file opens again without converging', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);
    final first = open();
    await first.customSelect('SELECT 1').get();
    expect(first.lastConvergeReport, isNotNull);
    await first.close();
    warnings.clear();

    final second = open();

    expect(await second.schemaDifferences(), isEmpty);
    expect(second.lastConvergeReport, isNull);
    expect(warnings, isEmpty);
  });

  test('a fresh file is at the current version, carries the workspace '
      'application id and matches the declared schema', () async {
    final db = open();

    expect(await db.schemaDifferences(), isEmpty);
    expect(
      await pragma(db, 'user_version'),
      WorkspaceDatabase.currentSchemaVersion,
    );
    expect(
      await pragma(db, 'application_id'),
      WorkspaceDatabase.fileApplicationId,
    );
    expect(db.lastConvergeReport, isNull);
  });

  group('convergeSchema on a file somebody else prepared', () {
    test('removes what the schema does not declare and restores what it '
        'does', () async {
      final db = open();
      await db.customSelect('SELECT 1').get();
      await db.customStatement('CREATE TABLE planted (id TEXT)');
      await db.customStatement(
        'CREATE TRIGGER planted_spy AFTER INSERT ON spaces BEGIN '
        'INSERT INTO planted VALUES (new.id); END',
      );
      await db.customStatement('CREATE VIEW planted_view AS SELECT 1');
      // Any declared index will do: which ones exist is the tables'
      // business, not this test's.
      final declaredIndex =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    'AND sql IS NOT NULL ORDER BY name LIMIT 1',
                  )
                  .getSingle())
              .read<String>('name');
      await db.customStatement('DROP INDEX "$declaredIndex"');
      await db.customStatement(
        'ALTER TABLE spaces ADD COLUMN planted_column TEXT',
      );
      expect(await db.schemaDifferences(), isNotEmpty);

      await db.convergeSchema();
      await db.close();

      // The full-text triggers come back when the file opens.
      final reopened = open();
      expect(await reopened.schemaDifferences(), isEmpty);
    });
  });

  group('refusals', () {
    test('a file a newer build wrote is refused and left as it is', () async {
      final current = open();
      await current.customSelect('SELECT 1').get();
      await current.close();
      const newer = WorkspaceDatabase.currentSchemaVersion + 1;
      sqlite3.sqlite3.open(file.path)
        ..execute('ALTER TABLE spaces ADD COLUMN from_the_future TEXT')
        ..execute('PRAGMA user_version = $newer')
        ..close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseNewerThanBinaryException>()
              .having((e) => e.fileVersion, 'fileVersion', newer)
              .having(
                (e) => e.binaryVersion,
                'binaryVersion',
                WorkspaceDatabase.currentSchemaVersion,
              )
              .having((e) => e.database, 'database', 'workspace ws'),
        ),
      );
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(raw.select('PRAGMA user_version').single.values.single, newer);
      expect(
        raw.select('PRAGMA table_info(spaces)').map((r) => r['name']),
        contains('from_the_future'),
      );
    });

    test('a global database put where a workspace belongs is '
        'refused', () async {
      final global = GlobalDatabase.forTesting(NativeDatabase(file));
      await global.customSelect('SELECT 1').get();
      await global.close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<ForeignDatabaseFileException>().having(
            (e) => e.applicationId,
            'applicationId',
            GlobalDatabase.fileApplicationId,
          ),
        ),
      );
    });

    test('an unrelated SQLite file is refused, not emptied', () async {
      sqlite3.sqlite3.open(file.path)
        ..execute('CREATE TABLE recipes (id TEXT PRIMARY KEY)')
        ..execute("INSERT INTO recipes VALUES ('soup')")
        ..execute('PRAGMA user_version = 4')
        ..close();

      final db = open(snapshots: '${tmp.path}/pre_upgrade');

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(isA<ForeignDatabaseFileException>()),
      );
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(raw.select('SELECT id FROM recipes').single['id'], 'soup');
      expect(Directory('${tmp.path}/pre_upgrade').existsSync(), isFalse);
    });

    test('a current-version file without the application id is '
        'refused', () async {
      final current = open();
      await current.customSelect('SELECT 1').get();
      await current.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA application_id = 0')
        ..close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(isA<ForeignDatabaseFileException>()),
      );
    });
  });

  group('the copy taken before an upgrade', () {
    late Directory snapshots;

    setUp(() => snapshots = Directory('${tmp.path}/pre_upgrade'));

    List<File> copies() =>
        snapshots.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('holds the file as it was', () async {
      SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final copy = copies().single;
      expect(
        copy.uri.pathSegments.last,
        matches(RegExp(r'^v29\.\d{8}T\d{6}Z\.db$')),
      );
      final raw = sqlite3.sqlite3.open(copy.path);
      addTearDown(raw.close);
      expect(raw.select('PRAGMA user_version').single.values.single, 29);
      // Still the old shape, old tables and all.
      expect(raw.select('SELECT id FROM catalog_events').single['id'], 'e1');
      expect(raw.select('PRAGMA quick_check').single.values.single, 'ok');
    });

    test('is one of the two newest kept', () async {
      snapshots.createSync();
      final old = DateTime.utc(2026);
      for (final (index, name) in [
        'v27.a.db',
        'v28.b.db',
        'v28.c.db',
      ].indexed) {
        File('${snapshots.path}/$name')
          ..writeAsStringSync('old copy')
          ..setLastModifiedSync(old.add(Duration(days: index)));
      }
      SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final names = copies().map((f) => f.uri.pathSegments.last).toList();
      expect(names, hasLength(2));
      expect(names.first, startsWith('v28.c'));
      expect(names.last, startsWith('v29.'));
    });

    test('is not taken when nothing is upgraded', () async {
      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      expect(snapshots.existsSync(), isFalse);
    });
  });

  group('through the server connection', () {
    WorkspaceDatabase openServer() {
      final db = WorkspaceDatabase(
        openWorkspaceDatabase(dataDir: tmp.path, workspaceId: 'ws'),
        workspaceId: 'ws',
        upgradeSnapshotDirectory: workspaceUpgradeSnapshotDir(tmp.path, 'ws'),
      );
      addTearDown(db.close);
      return db;
    }

    Float32List vector(double tilt) => Float32List(384)
      ..[0] = 1
      ..[1] = tilt;

    Future<void> addFact(WorkspaceDatabase db, String id, double tilt) =>
        db.transaction(() async {
          await db.memoryFactDao.upsert(
            MemoryFactsTableCompanion.insert(
              id: id,
              workspaceId: 'ws',
              domain: 'ops',
              topic: id,
              content: 'fact $id',
            ),
          );
          await db.memoryFactDao.putEmbedding(
            id,
            vector(tilt).buffer.asUint8List(),
          );
        });

    test('a new file reclaims freed pages incrementally and journals in '
        'WAL', () async {
      final db = openServer();

      expect(await pragma(db, 'auto_vacuum'), 2);
      expect(await column(db, 'PRAGMA journal_mode'), ['wal']);
      expect(await db.schemaDifferences(), isEmpty);
    });

    test('an upgraded file is switched to incremental reclaim, and search '
        'survives the rewrite', () async {
      final path = workspaceDatabasePath(tmp.path, 'ws');
      Directory(workspaceDirPath(tmp.path, 'ws')).createSync();
      SchemaFixture.load('workspace_v29_a').writeTo(
        path,
        seed: (raw) {
          seed(raw);
          // Rowids that a rewrite would be free to renumber: the full-text
          // index addresses rows by them.
          raw
            ..execute(
              'INSERT INTO conversation_messages (rowid, id, space_id, '
              'conversation_id, sender_id, sender_type, content) '
              "VALUES (9000, 'far', 's1', 'c1', 'u1', 'user', 'kingfisher')",
            )
            ..execute("DELETE FROM conversation_messages WHERE id = 'm2'");
        },
      );

      final db = openServer();

      expect(await pragma(db, 'auto_vacuum'), 2);
      expect(db.fileWasRewritten, isTrue);
      expect(
        await column(
          db,
          'SELECT m.id FROM conversation_messages_fts f '
          'JOIN conversation_messages m ON m.rowid = f.rowid '
          "WHERE conversation_messages_fts MATCH 'kingfisher'",
        ),
        ['far'],
      );
      await db.customStatement(
        'INSERT INTO conversation_messages_fts(conversation_messages_fts, rank) '
        "VALUES ('integrity-check', 1)",
      );
      expect(await db.schemaDifferences(), isEmpty);
    });

    test('vector search works on whichever connection serves the '
        'read', () async {
      final db = openServer();
      await addFact(db, 'near', 0);
      await addFact(db, 'far', 1);

      // Reads rotate over the pool, so a handful of them reaches every
      // reader as well as the writer.
      for (var i = 0; i < 6; i++) {
        final hits = await db.memoryFactDao.searchVector(
          'ws',
          vector(0),
          limit: 1,
        );
        expect(hits.map((fact) => fact.id), ['near']);
      }
    });

    test('vector search works on a file that already existed', () async {
      final first = openServer();
      await addFact(first, 'near', 0);
      await first.close();

      final db = openServer();

      for (var i = 0; i < 6; i++) {
        final hits = await db.memoryFactDao.searchVector(
          'ws',
          vector(0),
          limit: 1,
        );
        expect(hits.map((fact) => fact.id), ['near']);
      }
    });

    test('a read sees the write before it, inside a transaction and '
        'out', () async {
      final db = openServer();

      for (var i = 0; i < 6; i++) {
        await addFact(db, 'fact-$i', 0);
        expect(await db.memoryFactDao.getById('ws', 'fact-$i'), isNotNull);
      }
      await db.transaction(() async {
        await addFact(db, 'in-transaction', 0);
        expect(
          await db.memoryFactDao.getById('ws', 'in-transaction'),
          isNotNull,
        );
      });
    });

    test('snapshotDatabaseFile copies a live file without its '
        'connection', () async {
      final db = openServer();
      await addFact(db, 'kept', 0);
      final copy = '${tmp.path}/copy.db';

      await snapshotDatabaseFile(
        source: workspaceDatabasePath(tmp.path, 'ws'),
        destination: copy,
      );

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT id FROM memory_facts').single['id'], 'kept');
      expect(
        raw.select('PRAGMA application_id').single.values.single,
        WorkspaceDatabase.fileApplicationId,
      );
    });

    test('snapshotDatabaseFile copies a file the vector extension has not '
        'opened yet', () async {
      // Every connection of this process loads the extension from here on.
      ensureVectorExtensionRegistered();
      final source = '${tmp.path}/plain.db';
      // A file as a process without the extension leaves it: the
      // extension's own table is not in it.
      sqlite3.sqlite3.open(source)
        ..execute('CREATE TABLE notes (body TEXT)')
        ..execute("INSERT INTO notes VALUES ('kept')")
        ..execute('DROP TABLE IF EXISTS "$vectorExtensionTable"')
        ..close();
      final copy = '${tmp.path}/plain-copy.db';

      await snapshotDatabaseFile(source: source, destination: copy);

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT body FROM notes').single['body'], 'kept');
    });

    test('snapshotDatabaseFile does not create a missing source', () async {
      final source = '${tmp.path}/absent.db';

      await expectLater(
        snapshotDatabaseFile(
          source: source,
          destination: '${tmp.path}/absent-copy.db',
        ),
        throwsA(anything),
      );
      expect(File(source).existsSync(), isFalse);
    });
  });
}
