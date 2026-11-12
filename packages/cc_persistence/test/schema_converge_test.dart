import 'package:cc_persistence/database/schema/schema_converge.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';

// One SQL statement often wraps over two string literals inside a list of
// statements; that is what the adjacent strings here are.
// ignore_for_file: no_adjacent_strings_in_list

/// The convergence engine on its own, over small hand-written schemas.
const _vectorTable = '_sqliteai_vector';

void main() {
  const version = 7;
  const applicationId = 0x43435753;

  late RawDatabase db;

  setUp(() {
    // Each test holds the file under test and a second database that only
    // exists to spell out the declared schema.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = RawDatabase.memory();
    addTearDown(db.close);
  });

  /// The schema a file holding exactly [statements] has.
  Future<SchemaSnapshot> declare(List<String> statements) async {
    final declared = RawDatabase.memory();
    try {
      for (final statement in statements) {
        await declared.customStatement(statement);
      }
      return await SchemaSnapshot.read(declared);
    } finally {
      await declared.close();
    }
  }

  Future<SchemaConvergeReport> converge(
    List<String> statements, {
    Map<String, Object> fills = const {},
    Set<String> preserve = const {},
  }) async => SchemaConverger(
    db: db,
    declared: await declare(statements),
    version: version,
    applicationId: applicationId,
    fills: fills,
    preserve: preserve,
  ).converge();

  Future<void> run(String sql, [List<Object?> args = const []]) =>
      db.customStatement(sql, args);

  Future<List<Map<String, Object?>>> rows(String sql) async =>
      (await db.customSelect(sql).get()).map((row) => row.data).toList();

  Future<int> pragma(String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).read<int>(name);

  Future<Set<String>> names(String type) async => {
    for (final row in await rows(
      "SELECT name FROM sqlite_master WHERE type = '$type' "
      "AND name NOT LIKE 'sqlite_%' "
      // The vector extension is process-wide once any test file loads it,
      // and from then on creates its table in every connection.
      "AND name != '$_vectorTable'",
    ))
      row['name']! as String,
  };

  group('tables', () {
    test('a table the file lacks is created', () async {
      final report = await converge(['CREATE TABLE notes (id TEXT)']);

      expect(await names('table'), {'notes'});
      expect(report.createdTables, ['notes']);
      expect(report.rebuiltTables, isEmpty);
    });

    test('a table that already matches is not touched', () async {
      await run('CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)');
      await run("INSERT INTO notes VALUES ('n1', 'hello')");

      // Line breaks and indentation are not a difference: the stored text is
      // compared with each run of whitespace collapsed.
      final report = await converge([
        'CREATE TABLE notes\n  (id TEXT PRIMARY KEY,\n   body   TEXT)',
      ]);

      expect(report.changedAnything, isFalse);
      expect(report.describe(), 'no change');
    });

    test('a differing table is rebuilt and its rows copied by column name, '
        'whatever the column order', () async {
      await run('CREATE TABLE notes (body TEXT, id TEXT, gone TEXT)');
      await run("INSERT INTO notes VALUES ('hello', 'n1', 'x')");
      await run("INSERT INTO notes VALUES ('world', 'n2', 'y')");

      final report = await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT, '
            "added TEXT NOT NULL DEFAULT 'fresh', loose TEXT)",
      ]);

      expect(report.rebuiltTables, ['notes']);
      expect(report.droppedRows, isEmpty);
      expect(await rows('SELECT * FROM notes ORDER BY id'), [
        {'id': 'n1', 'body': 'hello', 'added': 'fresh', 'loose': null},
        {'id': 'n2', 'body': 'world', 'added': 'fresh', 'loose': null},
      ]);
    });

    test('a rebuilt table keeps the rowids its rows had', () async {
      await run('CREATE TABLE notes (id TEXT, body TEXT)');
      await run("INSERT INTO notes (rowid, id, body) VALUES (40, 'n1', 'a')");
      await run("INSERT INTO notes (rowid, id, body) VALUES (7, 'n2', 'b')");

      await converge(['CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)']);

      expect(await rows('SELECT rowid AS r, id FROM notes ORDER BY r'), [
        {'r': 7, 'id': 'n2'},
        {'r': 40, 'id': 'n1'},
      ]);
    });

    test('a NOT NULL column the rows cannot supply takes its fill, and '
        'failing that the zero of its type', () async {
      await run('CREATE TABLE notes (id TEXT, workspace_id TEXT)');
      await run("INSERT INTO notes VALUES ('n1', NULL)");
      await run("INSERT INTO notes VALUES ('n2', 'kept')");

      await converge(
        [
          'CREATE TABLE notes (id TEXT PRIMARY KEY, '
              'workspace_id TEXT NOT NULL, owner TEXT NOT NULL, '
              'size INTEGER NOT NULL, label TEXT NOT NULL, '
              'payload BLOB NOT NULL)',
        ],
        fills: {'workspace_id': 'ws', 'owner': 'someone'},
      );

      expect(
        await rows(
          'SELECT id, workspace_id, owner, size, label, '
          'length(payload) AS payload_length FROM notes ORDER BY id',
        ),
        [
          {
            'id': 'n1',
            'workspace_id': 'ws',
            'owner': 'someone',
            'size': 0,
            'label': '',
            'payload_length': 0,
          },
          {
            'id': 'n2',
            'workspace_id': 'kept',
            'owner': 'someone',
            'size': 0,
            'label': '',
            'payload_length': 0,
          },
        ],
      );
    });

    test('rows the declared constraints refuse are left behind and '
        'counted', () async {
      await run('CREATE TABLE notes (id TEXT, status TEXT)');
      await run("INSERT INTO notes VALUES ('n1', 'open')");
      await run("INSERT INTO notes VALUES ('n2', 'nonsense')");
      await run("INSERT INTO notes VALUES ('n1', 'done')");

      final report = await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, '
            "status TEXT NOT NULL CHECK (status IN ('open', 'done')))",
      ]);

      expect(await rows('SELECT id, status FROM notes'), [
        {'id': 'n1', 'status': 'open'},
      ]);
      expect(report.droppedRows, {'notes': 2});
      expect(report.describe(), contains('rows left behind: notes=2'));
    });

    test('a WITHOUT ROWID table is rebuilt without touching a rowid', () async {
      await run('CREATE TABLE pairs (a TEXT, b TEXT, PRIMARY KEY (a, b))');
      await run("INSERT INTO pairs VALUES ('x', 'y')");

      await converge([
        'CREATE TABLE pairs (a TEXT NOT NULL, b TEXT NOT NULL, '
            'PRIMARY KEY (a, b)) WITHOUT ROWID',
      ]);

      expect(await rows('SELECT * FROM pairs'), [
        {'a': 'x', 'b': 'y'},
      ]);
    });

    test('a generated column is declared, not copied', () async {
      await run('CREATE TABLE notes (id TEXT, body TEXT, size INTEGER)');
      await run("INSERT INTO notes VALUES ('n1', 'hello', 99)");

      await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT, '
            'size INTEGER GENERATED ALWAYS AS (length(body)) VIRTUAL)',
      ]);

      expect(await rows('SELECT id, size FROM notes'), [
        {'id': 'n1', 'size': 5},
      ]);
    });
  });

  group('what the schema does not declare', () {
    test('tables, indexes, triggers and views are dropped', () async {
      await run('CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)');
      await run('CREATE TABLE leftover (id TEXT)');
      await run('CREATE INDEX idx_notes_stale ON notes (body)');
      await run('CREATE VIEW notes_view AS SELECT id FROM notes');
      await run(
        'CREATE TRIGGER notes_spy AFTER INSERT ON notes BEGIN '
        'INSERT INTO leftover VALUES (new.id); END',
      );

      final report = await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)',
      ]);

      expect(await names('table'), {'notes'});
      expect(await names('index'), isEmpty);
      expect(await names('trigger'), isEmpty);
      expect(await names('view'), isEmpty);
      expect(report.droppedTables, ['leftover']);
      expect(report.droppedIndexes, ['idx_notes_stale']);
    });

    test('a table an extension owns is neither rebuilt nor dropped', () async {
      await run('CREATE TABLE _extension (key TEXT)');
      await run("INSERT INTO _extension VALUES ('k')");

      final report = await converge(
        ['CREATE TABLE notes (id TEXT)'],
        preserve: {'_extension'},
      );

      expect(await names('table'), {'notes', '_extension'});
      expect(report.droppedTables, isEmpty);
      expect(await rows('SELECT key FROM _extension'), [
        {'key': 'k'},
      ]);
    });

    test('a full-text index whose definition changed is dropped, shadow '
        'tables and all', () async {
      await run('CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)');
      await run(
        'CREATE VIRTUAL TABLE notes_fts USING fts5('
        'body, extra, content=notes, content_rowid=rowid)',
      );

      await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)',
        'CREATE VIRTUAL TABLE notes_fts USING fts5('
            'body, content=notes, content_rowid=rowid)',
      ]);

      // The converger never creates a virtual table: the database installs
      // its full-text indexes when it opens.
      expect(await names('table'), {'notes'});
    });

    test('the shadow tables of a matching full-text index stay', () async {
      const statements = [
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)',
        'CREATE VIRTUAL TABLE notes_fts USING fts5('
            'body, content=notes, content_rowid=rowid)',
      ];
      for (final statement in statements) {
        await run(statement);
      }
      await run("INSERT INTO notes VALUES ('n1', 'hello')");
      await run("INSERT INTO notes_fts(rowid, body) VALUES (1, 'hello')");

      final report = await converge(statements);

      expect(report.changedAnything, isFalse);
      expect(
        await rows("SELECT rowid AS r FROM notes_fts WHERE body MATCH 'hello'"),
        [
          {'r': 1},
        ],
      );
    });
  });

  group('indexes', () {
    test('missing ones are created and differing ones replaced', () async {
      await run('CREATE TABLE notes (id TEXT PRIMARY KEY, a TEXT, b TEXT)');
      await run('CREATE INDEX idx_notes_a ON notes (a)');
      await run('CREATE INDEX idx_notes_b ON notes (a, b)');

      final report = await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, a TEXT, b TEXT)',
        'CREATE INDEX idx_notes_a ON notes (a)',
        'CREATE INDEX idx_notes_b ON notes (b)',
        'CREATE INDEX idx_notes_c ON notes (b, a)',
      ]);

      expect(report.createdIndexes, ['idx_notes_b', 'idx_notes_c']);
      expect(report.droppedIndexes, isEmpty);
      expect(
        await rows("SELECT sql FROM sqlite_master WHERE name = 'idx_notes_b'"),
        [
          {'sql': 'CREATE INDEX idx_notes_b ON notes (b)'},
        ],
      );
    });

    test('a rebuilt table gets its declared indexes back', () async {
      await run('CREATE TABLE notes (id TEXT, a TEXT)');
      await run('CREATE INDEX idx_notes_a ON notes (a)');

      await converge([
        'CREATE TABLE notes (id TEXT PRIMARY KEY, a TEXT)',
        'CREATE INDEX idx_notes_a ON notes (a)',
      ]);

      expect(await names('index'), {'idx_notes_a'});
    });

    test('a new unique index keeps the newest row of each duplicate key '
        'and counts the rest', () async {
      await run('CREATE TABLE links (id TEXT PRIMARY KEY, a TEXT, b TEXT)');
      await run("INSERT INTO links VALUES ('old', 'x', 'y')");
      await run("INSERT INTO links VALUES ('other', 'x', 'z')");
      await run("INSERT INTO links VALUES ('new', 'x', 'y')");
      // NULL never collides under a unique index, so these both stay.
      await run("INSERT INTO links VALUES ('null-1', 'x', NULL)");
      await run("INSERT INTO links VALUES ('null-2', 'x', NULL)");

      final report = await converge([
        'CREATE TABLE links (id TEXT PRIMARY KEY, a TEXT, b TEXT)',
        'CREATE UNIQUE INDEX idx_links_pair ON links (a, b)',
      ]);

      expect(
        (await rows('SELECT id FROM links ORDER BY id')).map((r) => r['id']),
        ['new', 'null-1', 'null-2', 'other'],
      );
      expect(report.droppedRows, {'links': 1});
    });

    test('a partial unique index only dedupes the rows it covers', () async {
      await run('CREATE TABLE links (id TEXT PRIMARY KEY, key TEXT, live INT)');
      await run("INSERT INTO links VALUES ('dead-1', 'k', 0)");
      await run("INSERT INTO links VALUES ('dead-2', 'k', 0)");
      await run("INSERT INTO links VALUES ('live-1', 'k', 1)");
      await run("INSERT INTO links VALUES ('live-2', 'k', 1)");

      await converge([
        'CREATE TABLE links (id TEXT PRIMARY KEY, key TEXT, live INT)',
        'CREATE UNIQUE INDEX idx_links_live ON links (lower(key)) '
            'WHERE live = 1',
      ]);

      expect(
        (await rows('SELECT id FROM links ORDER BY id')).map((r) => r['id']),
        ['dead-1', 'dead-2', 'live-2'],
      );
    });
  });

  group('foreign keys', () {
    const parents = 'CREATE TABLE parents (id TEXT PRIMARY KEY)';

    test('an orphan is removed, and so is what hung off it', () async {
      await run(parents);
      await run('CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT)');
      await run('CREATE TABLE toys (id TEXT PRIMARY KEY, child_id TEXT)');
      await run("INSERT INTO parents VALUES ('p1')");
      await run("INSERT INTO children VALUES ('c1', 'p1'), ('c2', 'gone')");
      await run("INSERT INTO toys VALUES ('t1', 'c1'), ('t2', 'c2')");

      final report = await converge([
        parents,
        'CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT NOT NULL '
            'REFERENCES parents (id) ON DELETE CASCADE)',
        'CREATE TABLE toys (id TEXT PRIMARY KEY, child_id TEXT NOT NULL '
            'REFERENCES children (id) ON DELETE CASCADE)',
      ]);

      expect(await rows('SELECT id FROM children'), [
        {'id': 'c1'},
      ]);
      expect(await rows('SELECT id FROM toys'), [
        {'id': 't1'},
      ]);
      expect(report.droppedRows, {'children': 1, 'toys': 1});
      expect(await rows('PRAGMA foreign_key_check'), isEmpty);
    });

    test('a SET NULL reference to a missing parent is cleared and the row '
        'stays', () async {
      await run(parents);
      await run('CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT)');
      await run("INSERT INTO children VALUES ('c1', 'gone')");

      final report = await converge([
        parents,
        'CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT '
            'REFERENCES parents (id) ON DELETE SET NULL)',
      ]);

      expect(await rows('SELECT * FROM children'), [
        {'id': 'c1', 'parent_id': null},
      ]);
      expect(report.clearedReferences, {'children.parent_id': 1});
      expect(report.droppedRows, isEmpty);
    });

    test('rebuilding a parent does not cascade into its children', () async {
      await run('CREATE TABLE parents (id TEXT PRIMARY KEY, gone TEXT)');
      await run(
        'CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT NOT NULL '
        'REFERENCES parents (id) ON DELETE CASCADE)',
      );
      await run("INSERT INTO parents VALUES ('p1', 'x')");
      await run("INSERT INTO children VALUES ('c1', 'p1')");
      await run('PRAGMA foreign_keys = ON');

      await converge([
        parents,
        'CREATE TABLE children (id TEXT PRIMARY KEY, parent_id TEXT NOT NULL '
            'REFERENCES parents (id) ON DELETE CASCADE)',
      ]);

      expect(await rows('SELECT id FROM children'), [
        {'id': 'c1'},
      ]);
      // The child still points at the table called `parents`, not at the
      // renamed-away copy of it.
      expect(
        (await rows('PRAGMA foreign_key_list(children)')).single['table'],
        'parents',
      );
      expect(await pragma('foreign_keys'), 1);
    });
  });

  group('the run as a whole', () {
    test('stamps the version and the application id', () async {
      await converge(['CREATE TABLE notes (id TEXT)']);

      expect(await pragma('user_version'), version);
      expect(await pragma('application_id'), applicationId);
    });

    test('a second run finds nothing to do', () async {
      await run('CREATE TABLE notes (body TEXT, id TEXT)');
      await run("INSERT INTO notes VALUES ('hello', 'n1')");
      const statements = [
        'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT)',
        'CREATE INDEX idx_notes_body ON notes (body)',
      ];

      expect((await converge(statements)).changedAnything, isTrue);
      expect((await converge(statements)).changedAnything, isFalse);
    });

    test('a failure leaves the file exactly as it was, at its old '
        'version', () async {
      await run('PRAGMA user_version = 3');
      await run('CREATE TABLE parents (id TEXT PRIMARY KEY)');
      await run('CREATE TABLE children (a TEXT, b TEXT, parent_id TEXT)');
      await run('CREATE TABLE leftover (id TEXT)');
      await run('CREATE INDEX idx_children_a ON children (a)');
      await run("INSERT INTO children VALUES ('x', 'y', 'gone')");
      final before = await rows(
        'SELECT type, name, sql FROM sqlite_master ORDER BY name',
      );

      // An orphan in a table without rowids is the one thing the repair
      // cannot address, and it is found last: after every table and index
      // has already been rebuilt.
      await expectLater(
        converge([
          'CREATE TABLE parents (id TEXT PRIMARY KEY)',
          'CREATE TABLE children (a TEXT NOT NULL, b TEXT NOT NULL, '
              'parent_id TEXT NOT NULL REFERENCES parents (id), '
              'PRIMARY KEY (a, b)) WITHOUT ROWID',
        ]),
        throwsStateError,
      );

      expect(
        await rows('SELECT type, name, sql FROM sqlite_master ORDER BY name'),
        before,
      );
      expect(await rows('SELECT * FROM children'), [
        {'a': 'x', 'b': 'y', 'parent_id': 'gone'},
      ]);
      expect(await pragma('user_version'), 3);
      expect(await pragma('application_id'), 0);
      expect(await pragma('foreign_keys'), 1);
      expect(await pragma('legacy_alter_table'), 0);
    });

    test('a leftover from a hand-edited file is cleared away', () async {
      await run('CREATE TABLE notes (id TEXT)');
      await run('CREATE TABLE __cc_converge_old_notes (id TEXT)');

      await converge(['CREATE TABLE notes (id TEXT)']);

      expect(await names('table'), {'notes'});
    });
  });

  group('SchemaSnapshot.differencesFrom', () {
    test('names what is missing, unexpected and different', () async {
      await run('CREATE TABLE notes (id TEXT)');
      await run('CREATE TABLE extra (id TEXT)');
      await run('CREATE TABLE _extension (id TEXT)');
      await run(
        'CREATE TRIGGER notes_spy AFTER INSERT ON notes BEGIN '
        'DELETE FROM extra; END',
      );

      final declared = await declare([
        'CREATE TABLE notes (id TEXT PRIMARY KEY)',
        'CREATE TABLE wanted (id TEXT)',
        'CREATE INDEX idx_wanted ON wanted (id)',
      ]);
      final differences = (await SchemaSnapshot.read(
        db,
      )).differencesFrom(declared, ignore: {'_extension'});

      expect(differences, [
        'table notes differs',
        'unexpected table extra',
        'unexpected trigger notes_spy',
        'missing table wanted',
        'missing index idx_wanted',
      ]);
    });

    test('is empty for the same schema, automatic indexes aside', () async {
      const statements = [
        'CREATE TABLE notes (id TEXT PRIMARY KEY, key TEXT UNIQUE)',
        'CREATE VIRTUAL TABLE notes_fts USING fts5(key)',
      ];
      for (final statement in statements) {
        await run(statement);
      }

      expect(
        (await SchemaSnapshot.read(
          db,
        )).differencesFrom(await declare(statements)),
        isEmpty,
      );
    });
  });
}
