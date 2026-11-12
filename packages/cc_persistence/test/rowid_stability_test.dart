import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/windows_safe_delete.dart';

/// Tables whose rows are addressed by SQLite's implicit `rowid` besides their
/// own id, each with the column that holds that id: the two search indexes
/// point at it (`content_rowid=rowid`), message lists break timestamp ties
/// with it, read marks store it as the position last seen, and the vector
/// scan over `memory_fact_embeddings` yields it.
///
/// None of them declares an `INTEGER PRIMARY KEY`, so the number is SQLite's
/// to assign. It stays put through a compaction only because each table has
/// an index (its primary key): SQLite renumbers the rows of a table that has
/// none. These tests hold that in place, in the schema and on a real file.
const _addressedByRowid = {
  'conversation_messages': 'id',
  'memory_facts': 'id',
  'memory_fact_embeddings': 'fact_id',
  'notification_feed': 'id',
};

/// A unit vector on [axis], so the query on the same axis finds its fact
/// first.
Uint8List _axis(int axis) =>
    (Float32List(384)..[axis] = 1).buffer.asUint8List();

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMessagingRepository messaging;
  late String spaceId;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cc_rowid');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    global = GlobalDatabase.atDataDir(tmp.path);
    dbs = WorkspaceDatabaseManager(dataDir: tmp.path, global: global);
    await DaoWorkspaceRepository(global.workspaceRegistryDao, dbs).upsert(
      Workspace(
        id: 'ws',
        name: 'ws',
        createdAt: DateTime(2026, 5, 18),
        updatedAt: DateTime(2026, 5, 18),
      ),
    );
    messaging = DaoMessagingRepository(dbs);
    spaceId = (await messaging.createSpace('ws', 'General', const [])).id;
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
    await deleteDirBestEffort(tmp);
  });

  Future<String> say(String content) => messaging.sendMessage(
    workspaceId: 'ws',
    spaceId: spaceId,
    content: content,
    senderId: 'u-1',
    senderType: 'user',
  );

  Future<void> remember(String id, String content, int axis) async {
    final dao = dbs.of('ws').memoryFactDao;
    await dao.upsert(
      MemoryFactsTableCompanion.insert(
        id: id,
        workspaceId: 'ws',
        domain: 'ops',
        topic: id,
        content: content,
      ),
    );
    await dao.putEmbedding(id, _axis(axis));
  }

  /// Rows with holes between them, which is what a renumbering would close.
  Future<void> seed() async {
    final db = dbs.of('ws');
    final spoken = [
      for (final fruit in ['apple', 'banana', 'cherry', 'damson', 'elder'])
        await say('the $fruit crate arrived'),
    ];
    for (final id in [spoken[1], spoken[3]]) {
      await db.customStatement(
        'DELETE FROM conversation_messages WHERE id = ?',
        [id],
      );
    }
    await say('the kiwi crate arrived');

    for (final (i, tree) in ['oak', 'pine', 'rowan', 'spruce'].indexed) {
      await remember('f-$i', 'the $tree stand was thinned', i);
    }
    await db.memoryFactDao.deleteById('ws', 'f-1');
    await remember('f-9', 'the willow stand was thinned', 9);
  }

  Map<String, int> rowidsOf(sqlite3.Database raw, String table) => {
    for (final row in raw.select(
      'SELECT ${_addressedByRowid[table]} AS id, rowid AS n FROM "$table"',
    ))
      row['id']! as String: row['n']! as int,
  };

  /// Which vector each fact holds, read from the file at [path]: a rowid
  /// renumbered under the vectors must not move one to another fact.
  Map<String, List<int>> vectorsOf(String path) {
    final raw = sqlite3.sqlite3.open(path, mode: sqlite3.OpenMode.readOnly);
    try {
      return {
        for (final row in raw.select(
          'SELECT fact_id, embedding FROM memory_fact_embeddings',
        ))
          row['fact_id']! as String: row['embedding']! as List<int>,
      };
    } finally {
      raw.close();
    }
  }

  /// The rowid of every row of every table in [_addressedByRowid], read by a
  /// connection of its own so nothing is answered from a cache.
  Map<String, Map<String, int>> rowids(String path) {
    final raw = sqlite3.sqlite3.open(path, mode: sqlite3.OpenMode.readOnly);
    try {
      return {
        for (final table in _addressedByRowid.keys) table: rowidsOf(raw, table),
      };
    } finally {
      raw.close();
    }
  }

  /// Fails when a search index and the table it indexes disagree.
  Future<void> expectSearchIndexesMatch(WorkspaceDatabase db) async {
    for (final index in ['conversation_messages_fts', 'memory_facts_fts']) {
      await db.customStatement(
        "INSERT INTO $index($index, rank) VALUES ('integrity-check', 1)",
      );
    }
  }

  test('every table addressed by rowid has an index, and every search index '
      'points at one of them', () async {
    final db = dbs.of('ws');
    for (final table in _addressedByRowid.keys) {
      final indexes = await db
          .customSelect('PRAGMA index_list("$table")')
          .get();
      expect(
        indexes,
        isNotEmpty,
        reason:
            '$table has no index, so VACUUM is free to renumber its '
            'rows and everything that stored a rowid would point elsewhere',
      );
    }

    final searchIndexes = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' "
          "AND sql LIKE 'CREATE VIRTUAL TABLE%content_rowid=rowid%'",
        )
        .get();
    final indexed = {
      for (final row in searchIndexes)
        RegExp(r'content=(\w+)').firstMatch(row.read<String>('sql'))!.group(1)!,
    };
    expect(indexed, isNotEmpty);
    expect(
      _addressedByRowid.keys.toSet().containsAll(indexed),
      isTrue,
      reason:
          'a search index over '
          '${indexed.difference(_addressedByRowid.keys.toSet())} '
          'points at rowids this test does not hold in place: add the table '
          'to _addressedByRowid and seed it',
    );
  });

  test('a compaction in place moves no row and search still finds the right '
      'message', () async {
    await seed();
    final db = dbs.of('ws');
    await db.checkpoint();
    final before = rowids(dbs.pathFor('ws'));
    final vectors = vectorsOf(dbs.pathFor('ws'));
    expect(before['conversation_messages'], hasLength(4));
    expect(before['memory_facts'], hasLength(4));
    expect(before['memory_fact_embeddings'], hasLength(4));

    await db.customStatement('VACUUM');
    await db.checkpoint();

    expect(rowids(dbs.pathFor('ws')), before);
    expect(vectorsOf(dbs.pathFor('ws')), vectors);
    await expectSearchIndexesMatch(db);
    final found = await messaging.searchInSpace('ws', spaceId, 'kiwi');
    expect(found.single.content, 'the kiwi crate arrived');
    final facts = await db.memoryFactDao.searchFts('ws', 'willow');
    expect(facts.single.id, 'f-9');
    final near = await db.memoryFactDao.searchVector(
      'ws',
      Float32List(384)..[9] = 1,
      limit: 1,
    );
    expect(near.single.id, 'f-9');
  });

  test('a snapshot carries the same rowids as the file it was taken '
      'from', () async {
    await seed();
    await dbs.of('ws').checkpoint();
    final before = rowids(dbs.pathFor('ws'));
    final copy = '${tmp.path}/copy.db';

    await dbs.snapshotTo('ws', copy);

    expect(rowids(copy), before);
    expect(vectorsOf(copy), vectorsOf(dbs.pathFor('ws')));
  });
}
