import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late CodeIndexDatabase db;

  CodeSymbolsTableCompanion symbol(
    String id,
    String name,
    String qualifiedName, {
    String repoId = 'repo1',
    String? checkoutId,
    String filePath = 'a.dart',
  }) => CodeSymbolsTableCompanion.insert(
    id: id,
    repoId: repoId,
    checkoutId: Value(checkoutId),
    kind: 'method',
    name: name,
    qualifiedName: qualifiedName,
    filePath: filePath,
    language: 'dart',
    startLine: 1,
    endLine: 2,
  );

  CodeEdgesTableCompanion calls(
    String id,
    String source,
    String target, {
    String repoId = 'repo1',
    String? checkoutId,
  }) => CodeEdgesTableCompanion.insert(
    id: id,
    repoId: repoId,
    checkoutId: Value(checkoutId),
    sourceSymbolId: source,
    kind: CodeEdgeKind.calls.name,
    targetSymbolId: Value(target),
    sourceFilePath: const Value('a.dart'),
  );

  CodeFilesTableCompanion file(
    String id, {
    String repoId = 'repo1',
    String? checkoutId,
  }) => CodeFilesTableCompanion.insert(
    id: id,
    repoId: repoId,
    checkoutId: Value(checkoutId),
    path: 'a.dart',
    contentHash: 'h',
  );

  CodeIndexCheckpointsTableCompanion checkpoint(
    String id, {
    String repoId = 'repo1',
    String? checkoutId,
  }) => CodeIndexCheckpointsTableCompanion.insert(
    id: id,
    repoId: repoId,
    checkoutId: Value(checkoutId),
    headSha: 'head',
    worktreeDigest: 'digest',
    indexerFingerprint: 'fp',
  );

  setUp(() async {
    db = createTestCodeIndexDatabase();
    await db.codeGraphDao.upsertSymbols([
      symbol('s_foo', 'foo', 'A.foo'),
      symbol('s_bar', 'bar', 'A.bar'),
    ]);
    await db.codeGraphDao.upsertEdges([calls('e1', 's_foo', 's_bar')]);
  });

  tearDown(() async {
    await db.close();
  });

  group('CodeGraphDao', () {
    test('FTS search finds a symbol by name', () async {
      final hits = await db.codeGraphDao.searchFts('repo1', 'foo');
      expect(hits.map((s) => s.id), contains('s_foo'));
    });

    test('FTS search is scoped to the repo', () async {
      await db.codeGraphDao.upsertSymbols([
        symbol('s_foo_r2', 'foo', 'A.foo', repoId: 'repo2'),
      ]);
      expect(
        (await db.codeGraphDao.searchFts('repo1', 'foo')).map((s) => s.id),
        ['s_foo'],
      );
      expect(
        (await db.codeGraphDao.searchFts('repo2', 'foo')).map((s) => s.id),
        ['s_foo_r2'],
      );
    });

    test('getCallees returns outgoing call targets', () async {
      final callees = await db.codeGraphDao.getCallees('s_foo');
      expect(callees.map((s) => s.id), ['s_bar']);
    });

    test('getCallers returns incoming callers', () async {
      final callers = await db.codeGraphDao.getCallers('s_bar');
      expect(callers.map((s) => s.id), ['s_foo']);
    });

    test('getImpactRadius walks reverse dependencies with depth', () async {
      final impact = await db.codeGraphDao.getImpactRadius('s_bar');
      expect(impact.depthById['s_bar'], 0);
      expect(impact.depthById['s_foo'], 1);
      expect(impact.nodes.length, 2);
    });

    test("deleteByFile removes a file's symbols and edges", () async {
      await db.codeGraphDao.deleteByFile('repo1', 'a.dart');
      expect(await db.codeGraphDao.getSymbolsByRepo('repo1'), isEmpty);
      expect(await db.codeGraphDao.getCallees('s_foo'), isEmpty);
    });

    test('setEdgeTarget rebinds an edge by id', () async {
      await db.codeGraphDao.upsertSymbols([symbol('s_baz', 'baz', 'A.baz')]);
      await db.codeGraphDao.setEdgeTarget('e1', 's_baz');
      final callees = await db.codeGraphDao.getCallees('s_foo');
      expect(callees.map((s) => s.id), ['s_baz']);
    });
  });

  group('partition deletes', () {
    setUp(() async {
      await db.codeGraphDao.upsertSymbols([
        symbol('s_wt', 'wt', 'A.wt', checkoutId: 'wt1'),
        symbol('s_other', 'other', 'B.other', repoId: 'repo2'),
      ]);
      await db.codeGraphDao.upsertEdges([
        calls('e_wt', 's_wt', 's_bar', checkoutId: 'wt1'),
        calls('e_other', 's_other', 's_other', repoId: 'repo2'),
      ]);
      await db.codeGraphDao.upsertFile(file('f1'));
      await db.codeGraphDao.upsertFile(file('f_wt', checkoutId: 'wt1'));
      await db.codeGraphDao.upsertFile(file('f_other', repoId: 'repo2'));
      await db.codeGraphDao.upsertCheckpoint(checkpoint('c1'));
      await db.codeGraphDao.upsertCheckpoint(
        checkpoint('c_wt', checkoutId: 'wt1'),
      );
      await db.codeGraphDao.upsertCheckpoint(
        checkpoint('c_other', repoId: 'repo2'),
      );
    });

    Future<Map<String, List<String>>> rows() async => {
      for (final table in const [
        'code_symbols',
        'code_edges',
        'code_files',
        'code_index_checkpoints',
      ])
        table: [
          for (final row
              in await db
                  .customSelect('SELECT id FROM $table ORDER BY id')
                  .get())
            row.read<String>('id'),
        ],
    };

    test('deleteByRepo removes every partition of the repo and nothing '
        'else', () async {
      await db.codeGraphDao.deleteByRepo('repo1');

      expect(await rows(), {
        'code_symbols': ['s_other'],
        'code_edges': ['e_other'],
        'code_files': ['f_other'],
        'code_index_checkpoints': ['c_other'],
      });
      expect(await db.codeGraphDao.searchFts('repo1', 'foo'), isEmpty);
    });

    test('deleteByCheckout removes the worktree partition only', () async {
      await db.codeGraphDao.deleteByCheckout('repo1', 'wt1');

      expect(await rows(), {
        'code_symbols': ['s_bar', 's_foo', 's_other'],
        'code_edges': ['e1', 'e_other'],
        'code_files': ['f1', 'f_other'],
        'code_index_checkpoints': ['c1', 'c_other'],
      });
      expect(
        await db.codeGraphDao.searchFts('repo1', 'wt', checkoutId: 'wt1'),
        isEmpty,
      );
    });
  });

  group('query plans', () {
    /// The `detail` lines of `EXPLAIN QUERY PLAN` for [sql].
    Future<String> plan(String sql, List<Object> args) async {
      final rows = await db
          .customSelect(
            'EXPLAIN QUERY PLAN $sql',
            variables: [for (final a in args) Variable(a)],
          )
          .get();
      return rows.map((r) => r.read<String>('detail')).join('\n');
    }

    test(
      'symbols of a file in a partition come from the partition index',
      () async {
        expect(
          await plan(
            'SELECT id FROM code_symbols '
            'WHERE repo_id = ? AND checkout_id IS NULL AND file_path = ?',
            ['repo1', 'a.dart'],
          ),
          contains('USING INDEX idx_code_symbols_partition_file'),
        );
      },
    );

    test('edges by source and by target use their own indexes', () async {
      expect(
        await plan(
          'SELECT id FROM code_edges e '
          'WHERE e.source_symbol_id = ? AND e.checkout_id IS NULL',
          ['s_foo'],
        ),
        contains('idx_code_edges_source'),
      );
      expect(
        await plan(
          'SELECT id FROM code_edges e '
          'WHERE e.target_symbol_id = ? AND e.checkout_id IS NULL',
          ['s_bar'],
        ),
        contains('idx_code_edges_target'),
      );
    });

    test('a checkpoint is found by repo and checkout', () async {
      expect(
        await plan(
          'SELECT id FROM code_index_checkpoints '
          'WHERE repo_id = ? AND checkout_id = ?',
          ['repo1', 'wt1'],
        ),
        contains('USING INDEX idx_code_index_checkpoints_partition'),
      );
    });

    test(
      'unresolved edges of a partition come from the partial index',
      () async {
        expect(
          await plan(
            'SELECT COUNT(*) FROM code_edges '
            'WHERE repo_id = ? AND checkout_id IS NULL '
            'AND target_symbol_id IS NULL AND target_name IS NOT NULL',
            ['repo1'],
          ),
          contains('idx_code_edges_unresolved'),
        );
      },
    );
  });
}
