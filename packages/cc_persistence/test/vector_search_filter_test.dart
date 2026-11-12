import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The vector scan ranks every embedding in the file, so each DAO's filters
/// (repo, checkout, superseded) must run before the top-k cut. In every case
/// below the rows a filter drops sit NEARER the query than the rows it keeps:
/// ranking first and filtering afterwards returns nothing.
void main() {
  late WorkspaceDatabase db;
  late CodeIndexDatabase codeIndex;

  setUp(() {
    db = createTestDatabase();
    codeIndex = createTestCodeIndexDatabase();
  });

  tearDown(() async {
    await db.close();
    await codeIndex.close();
  });

  /// A 384-d vector on axis 0, tilted toward axis 1 by [tilt]; its distance
  /// from the query `vec(0)` grows with [tilt].
  Float32List vec(double tilt) => Float32List(384)
    ..[0] = 1
    ..[1] = tilt;

  /// Writes embedded symbols: each id with its tilt.
  Future<void> upsertSymbols(
    List<({String id, String repoId, double tilt, String? checkoutId})> rows,
  ) async {
    await codeIndex.codeGraphDao.upsertSymbols([
      for (final r in rows)
        CodeSymbolsTableCompanion.insert(
          id: r.id,
          repoId: r.repoId,
          checkoutId: Value(r.checkoutId),
          kind: 'method',
          name: r.id,
          qualifiedName: 'A.${r.id}',
          filePath: 'a.dart',
          language: 'dart',
          startLine: 1,
          endLine: 2,
        ),
    ]);
    await codeIndex.codeGraphDao.putEmbeddings({
      for (final r in rows) r.id: vec(r.tilt).buffer.asUint8List(),
    });
  }

  ({String id, String repoId, double tilt, String? checkoutId}) symbol(
    String id, {
    required String repoId,
    required double tilt,
    String? checkoutId,
  }) => (id: id, repoId: repoId, tilt: tilt, checkoutId: checkoutId);

  test('a repo ranked below another repo in the file still gets its hits, '
      'nearest first', () async {
    await upsertSymbols([
      symbol('r2_a', repoId: 'repo2', tilt: 0),
      symbol('r2_b', repoId: 'repo2', tilt: 0.01),
      symbol('r2_c', repoId: 'repo2', tilt: 0.02),
      symbol('r1_far', repoId: 'repo1', tilt: 1),
      symbol('r1_near', repoId: 'repo1', tilt: 0.5),
    ]);

    final hits = await codeIndex.codeGraphDao.searchVector(
      'repo1',
      vec(0),
      limit: 2,
    );
    expect(hits.map((s) => s.id), ['r1_near', 'r1_far']);
  });

  test("a worktree's delta does not crowd out the linked checkout", () async {
    await upsertSymbols([
      symbol('wt_a', repoId: 'repo1', tilt: 0, checkoutId: 'wt1'),
      symbol('wt_b', repoId: 'repo1', tilt: 0.01, checkoutId: 'wt1'),
      symbol('linked', repoId: 'repo1', tilt: 0.5),
    ]);

    final hits = await codeIndex.codeGraphDao.searchVector(
      'repo1',
      vec(0),
      limit: 1,
    );
    expect(hits.map((s) => s.id), ['linked']);
  });

  test('superseded memory facts do not crowd out live ones', () async {
    Future<void> fact(String id, double tilt, {String? by}) async {
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: id,
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 'deploy',
          content: 'deployment runbook $id',
          supersededBy: Value(by),
        ),
      );
      await db.memoryFactDao.putEmbedding(id, vec(tilt).buffer.asUint8List());
    }

    await fact('f-old', 0, by: 'f-live');
    await fact('f-older', 0.01, by: 'f-old');
    await fact('f-live', 0.5);

    final hits = await db.memoryFactDao.searchVector('ws-1', vec(0), limit: 1);
    expect(hits.map((f) => f.id), ['f-live']);
  });
}
