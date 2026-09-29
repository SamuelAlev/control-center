import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The vector scan ranks every embedding in the file, so each DAO's filters
/// (repo, checkout, superseded) must run before the top-k cut. In every case
/// below the rows a filter drops sit NEARER the query than the rows it keeps:
/// ranking first and filtering afterwards returns nothing.
void main() {
  // Process-global auto-extension, as `openServerDatabase` registers it. It
  // must be in place before a database's first (lazy) open runs vector_init.
  setUpAll(() => sqlite3.sqlite3.loadSqliteVectorExtension());

  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    for (final id in ['repo1', 'repo2']) {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: id, name: id, path: '/tmp/$id'),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  /// A 384-d vector on axis 0, tilted toward axis 1 by [tilt]; its distance
  /// from the query `vec(0)` grows with [tilt].
  Float32List vec(double tilt) => Float32List(384)
    ..[0] = 1
    ..[1] = tilt;

  CodeSymbolsTableCompanion symbol(
    String id, {
    required String repoId,
    required double tilt,
    String? checkoutId,
  }) => CodeSymbolsTableCompanion.insert(
    id: id,
    workspaceId: 'ws1',
    repoId: repoId,
    checkoutId: Value(checkoutId),
    kind: 'method',
    name: id,
    qualifiedName: 'A.$id',
    filePath: 'a.dart',
    language: 'dart',
    startLine: 1,
    endLine: 2,
    embedding: Value(vec(tilt).buffer.asUint8List()),
  );

  test('a repo ranked below another repo in the file still gets its hits, '
      'nearest first', () async {
    await db.codeGraphDao.upsertSymbols([
      symbol('r2_a', repoId: 'repo2', tilt: 0),
      symbol('r2_b', repoId: 'repo2', tilt: 0.01),
      symbol('r2_c', repoId: 'repo2', tilt: 0.02),
      symbol('r1_far', repoId: 'repo1', tilt: 1),
      symbol('r1_near', repoId: 'repo1', tilt: 0.5),
    ]);

    final hits = await db.codeGraphDao.searchVector(
      'ws1',
      'repo1',
      vec(0),
      limit: 2,
    );
    expect(hits.map((s) => s.id), ['r1_near', 'r1_far']);
  });

  test("a worktree's delta does not crowd out the linked checkout", () async {
    // The worktree registry row the checkout partition hangs off (FK target).
    await db
        .into(db.isolatedReposTable)
        .insert(
          IsolatedReposTableCompanion.insert(
            id: 'wt1',
            workspaceId: 'ws1',
            spaceId: 'ch1',
            repoId: 'repo1',
            path: '/wt/repo1',
            branch: 'pr-42',
            sourcePath: '/tmp/repo1',
          ),
        );
    await db.codeGraphDao.upsertSymbols([
      symbol('wt_a', repoId: 'repo1', tilt: 0, checkoutId: 'wt1'),
      symbol('wt_b', repoId: 'repo1', tilt: 0.01, checkoutId: 'wt1'),
      symbol('linked', repoId: 'repo1', tilt: 0.5),
    ]);

    final hits = await db.codeGraphDao.searchVector(
      'ws1',
      'repo1',
      vec(0),
      limit: 1,
    );
    expect(hits.map((s) => s.id), ['linked']);
  });

  test('superseded memory facts do not crowd out live ones', () async {
    MemoryFactsTableCompanion fact(String id, double tilt, {String? by}) =>
        MemoryFactsTableCompanion.insert(
          id: id,
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 'deploy',
          content: 'deployment runbook $id',
          supersededBy: Value(by),
          embedding: Value(vec(tilt).buffer.asUint8List()),
        );
    await db.memoryFactDao.upsert(fact('f-old', 0, by: 'f-live'));
    await db.memoryFactDao.upsert(fact('f-older', 0.01, by: 'f-old'));
    await db.memoryFactDao.upsert(fact('f-live', 0.5));

    final hits = await db.memoryFactDao.searchVector('ws-1', vec(0), limit: 1);
    expect(hits.map((f) => f.id), ['f-live']);
  });
}
