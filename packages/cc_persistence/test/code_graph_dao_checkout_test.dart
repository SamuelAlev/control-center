import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Checkout-partition isolation: the code graph is partitioned per checkout
/// within a repo — NULL `checkout_id` for the linked checkout, an
/// `isolated_repos` row id for each conversation/PR worktree. A worktree's
/// tree (a PR head, a feature branch) differs from the linked checkout, so
/// partitions must never mix: reads scoped to one partition must not see the
/// other's rows, deletes must not cross partitions and deleting a worktree's
/// partition leaves the linked partition intact.
void main() {
  late CodeIndexDatabase db;

  CodeSymbolsTableCompanion symbol(
    String id,
    String filePath,
    String qualifiedName, {
    String? checkoutId,
  }) => CodeSymbolsTableCompanion.insert(
    id: id,
    repoId: 'repo1',
    checkoutId: Value(checkoutId),
    kind: 'method',
    name: qualifiedName.split('.').last,
    qualifiedName: qualifiedName,
    filePath: filePath,
    language: 'dart',
    startLine: 1,
    endLine: 2,
  );

  CodeEdgesTableCompanion edge(
    String id,
    String sourceSymbolId, {
    String? checkoutId,
  }) => CodeEdgesTableCompanion.insert(
    id: id,
    repoId: 'repo1',
    checkoutId: Value(checkoutId),
    sourceSymbolId: sourceSymbolId,
    kind: CodeEdgeKind.calls.name,
    targetName: const Value('external.Thing'),
    sourceFilePath: const Value('a.dart'),
  );

  CodeFilesTableCompanion file(String id, String path, {String? checkoutId}) =>
      CodeFilesTableCompanion.insert(
        id: id,
        repoId: 'repo1',
        checkoutId: Value(checkoutId),
        path: path,
        contentHash: 'hash-$id',
      );

  setUp(() async {
    db = createTestCodeIndexDatabase();

    // Linked checkout partition (checkoutId NULL): a.dart with foo.
    await db.codeGraphDao.upsertSymbols([symbol('s_foo', 'a.dart', 'A.foo')]);
    await db.codeGraphDao.upsertEdges([edge('e_linked', 's_foo')]);
    await db.codeGraphDao.upsertFile(file('f_linked_a', 'a.dart'));

    // Worktree partition (checkoutId 'wt1'): a.dart changed (foo'), plus a
    // new file pr.dart that only exists in the PR.
    await db.codeGraphDao.upsertSymbols([
      symbol('s_foo_pr', 'a.dart', 'A.foo', checkoutId: 'wt1'),
      symbol('s_new', 'pr.dart', 'A.newThing', checkoutId: 'wt1'),
    ]);
    await db.codeGraphDao.upsertEdges([
      edge('e_wt', 's_foo_pr', checkoutId: 'wt1'),
    ]);
    await db.codeGraphDao.upsertFile(
      file('f_wt_a', 'a.dart', checkoutId: 'wt1'),
    );
    await db.codeGraphDao.upsertFile(
      file('f_wt_pr', 'pr.dart', checkoutId: 'wt1'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('checkout partition isolation', () {
    test('getFiles returns only the requested partition', () async {
      final linked = await db.codeGraphDao.getFiles('repo1');
      expect(linked.map((f) => f.path), ['a.dart']);

      final worktree = await db.codeGraphDao.getFiles(
        'repo1',
        checkoutId: 'wt1',
      );
      expect(worktree.map((f) => f.path), ['a.dart', 'pr.dart']);
    });

    test('getFile scopes the single-file lookup to the partition', () async {
      expect(
        (await db.codeGraphDao.getFile('repo1', 'a.dart'))!.id,
        'f_linked_a',
      );
      expect(
        (await db.codeGraphDao.getFile(
          'repo1',
          'a.dart',
          checkoutId: 'wt1',
        ))!.id,
        'f_wt_a',
      );
      // pr.dart exists only in the worktree partition.
      expect(await db.codeGraphDao.getFile('repo1', 'pr.dart'), isNull);
    });

    test(
      'getSymbolsByRepo and getSymbolsByName are partition-scoped',
      () async {
        expect(
          (await db.codeGraphDao.getSymbolsByRepo('repo1')).map((s) => s.id),
          ['s_foo'],
        );
        expect(
          (await db.codeGraphDao.getSymbolsByRepo(
            'repo1',
            checkoutId: 'wt1',
          )).map((s) => s.id),
          ['s_foo_pr', 's_new'],
        );
        // The PR-only symbol is invisible from the linked partition.
        expect(
          await db.codeGraphDao.getSymbolsByName('repo1', 'newThing'),
          isEmpty,
        );
        expect(
          (await db.codeGraphDao.getSymbolsByName(
            'repo1',
            'newThing',
            checkoutId: 'wt1',
          )).single.id,
          's_new',
        );
      },
    );

    test('watchSymbolsByRepo streams only the requested partition', () async {
      expect(
        (await db.codeGraphDao.watchSymbolsByRepo('repo1').first).map(
          (s) => s.id,
        ),
        ['s_foo'],
      );
      expect(
        (await db.codeGraphDao
                .watchSymbolsByRepo('repo1', checkoutId: 'wt1')
                .first)
            .length,
        2,
      );
    });

    test('getUnresolvedEdges is partition-scoped', () async {
      expect(
        (await db.codeGraphDao.getUnresolvedEdges('repo1')).map((e) => e.id),
        ['e_linked'],
      );
      expect(
        (await db.codeGraphDao.getUnresolvedEdges(
          'repo1',
          checkoutId: 'wt1',
        )).map((e) => e.id),
        ['e_wt'],
      );
    });

    test('searchFts is partition-scoped', () async {
      expect(await db.codeGraphDao.searchFts('repo1', 'newThing'), isEmpty);
      expect(
        (await db.codeGraphDao.searchFts(
          'repo1',
          'newThing',
          checkoutId: 'wt1',
        )).single.id,
        's_new',
      );
      // The linked partition answers its own row for the shared file.
      expect(
        (await db.codeGraphDao.searchFts('repo1', 'foo')).single.id,
        's_foo',
      );
    });

    test('deleteByFile touches only the requested partition', () async {
      await db.codeGraphDao.deleteByFile('repo1', 'a.dart');

      // Linked a.dart is gone (symbols, edges, file row)...
      expect(await db.codeGraphDao.getFile('repo1', 'a.dart'), isNull);
      expect(await db.codeGraphDao.getUnresolvedEdges('repo1'), isEmpty);
      // ...but the worktree partition's a.dart and everything else survives.
      expect(
        await db.codeGraphDao.getFile('repo1', 'a.dart', checkoutId: 'wt1'),
        isNotNull,
      );
      expect(
        (await db.codeGraphDao.getUnresolvedEdges(
          'repo1',
          checkoutId: 'wt1',
        )).single.id,
        'e_wt',
      );
    });

    test('deleteByCheckout removes the partition, FTS entries included', () async {
      await db.codeGraphDao.deleteByCheckout('repo1', 'wt1');

      // The whole worktree partition is gone...
      expect(
        await db.codeGraphDao.getFiles('repo1', checkoutId: 'wt1'),
        isEmpty,
      );
      // Reads are MERGED, so a reader of the (now deleted) partition falls back
      // to the base rows — the invariant is that none of the worktree's OWN
      // rows survive, not that the view is empty.
      expect(
        (await db.codeGraphDao.getSymbolsByRepo(
          'repo1',
          checkoutId: 'wt1',
        )).map((s) => s.checkoutId),
        everyElement(isNull),
      );
      expect(
        await db.codeGraphDao.getUnresolvedEdges('repo1', checkoutId: 'wt1'),
        isEmpty,
      );
      // ...and the FTS copy of its rows went with it. Asserted against the FTS
      // index directly, not through searchFts: that joins back to code_symbols,
      // so it returns empty whether or not the index still holds the orphaned
      // entry. An orphan would be live corruption — SQLite reuses rowids, so a
      // later symbol inheriting this rowid would match the deleted symbol's
      // terms. The delete trigger is what keeps this clean.
      final orphans = await db
          .customSelect(
            'SELECT rowid AS r FROM code_symbols_fts '
            "WHERE code_symbols_fts MATCH 'newThing'",
          )
          .get();
      expect(orphans, isEmpty);
      expect(
        await db.codeGraphDao.searchFts('repo1', 'newThing', checkoutId: 'wt1'),
        isEmpty,
      );
      // The linked partition is untouched.
      expect(
        (await db.codeGraphDao.getSymbolsByRepo('repo1')).single.id,
        's_foo',
      );
    });

    test(
      'a worktree read inherits base rows for files it did not change',
      () async {
        // `b.dart` exists only in the linked checkout: the worktree never diverged
        // on it, so under delta indexing it owns no row for it — and must still
        // see it. This is the whole point of merging on read.
        await db.codeGraphDao.upsertSymbols([symbol('s_b', 'b.dart', 'B.bar')]);
        await db.codeGraphDao.upsertFile(file('f_linked_b', 'b.dart'));

        final seen = await db.codeGraphDao.getSymbolsByRepo(
          'repo1',
          checkoutId: 'wt1',
        );
        expect(
          seen.map((s) => s.id).toSet(),
          // base b.dart (inherited) + the worktree's own a.dart and pr.dart
          {'s_b', 's_foo_pr', 's_new'},
        );
        // ...and the base's a.dart does NOT leak through: the worktree changed
        // that file, so its rows are the complete answer for that path.
        expect(seen.map((s) => s.id), isNot(contains('s_foo')));
      },
    );

    test('a name lookup prefers the worktree row over the base row', () async {
      final rows = await db.codeGraphDao.getSymbolsByName(
        'repo1',
        'foo',
        checkoutId: 'wt1',
      );
      expect(rows.map((s) => s.id), ['s_foo_pr']);
      // The linked reader still gets the base row.
      expect(
        (await db.codeGraphDao.getSymbolsByName(
          'repo1',
          'foo',
        )).map((s) => s.id),
        ['s_foo'],
      );
    });

    test(
      'search from a worktree finds base symbols it never indexed',
      () async {
        await db.codeGraphDao.upsertSymbols([
          symbol('s_b', 'b.dart', 'B.uniqueBaseThing'),
        ]);
        expect(
          (await db.codeGraphDao.searchFts(
            'repo1',
            'uniqueBaseThing',
            checkoutId: 'wt1',
          )).map((s) => s.id),
          ['s_b'],
        );
      },
    );

    test('edge traversal never crosses into another conversation', () async {
      // Delta partitions resolve their edges to BASE symbol ids, so a base
      // symbol is a shared traversal target. Two worktrees calling it must not
      // see each other — that would be one conversation reading another's code.
      await db.codeGraphDao.upsertSymbols([
        symbol('s_caller_wt1', 'x.dart', 'X.callerOne', checkoutId: 'wt1'),
        symbol('s_caller_wt2', 'y.dart', 'Y.callerTwo', checkoutId: 'wt2'),
      ]);
      // Both worktrees' edges point at the SAME base symbol.
      await db.codeGraphDao.upsertEdges([
        CodeEdgesTableCompanion.insert(
          id: 'e_wt1_to_base',
          repoId: 'repo1',
          checkoutId: const Value('wt1'),
          sourceSymbolId: 's_caller_wt1',
          kind: CodeEdgeKind.calls.name,
          targetSymbolId: const Value('s_foo'),
          sourceFilePath: const Value('x.dart'),
        ),
        CodeEdgesTableCompanion.insert(
          id: 'e_wt2_to_base',
          repoId: 'repo1',
          checkoutId: const Value('wt2'),
          sourceSymbolId: 's_caller_wt2',
          kind: CodeEdgeKind.calls.name,
          targetSymbolId: const Value('s_foo'),
          sourceFilePath: const Value('y.dart'),
        ),
      ]);

      expect(
        (await db.codeGraphDao.getCallers(
          's_foo',
          checkoutId: 'wt1',
        )).map((s) => s.id),
        ['s_caller_wt1'],
      );
      expect(
        (await db.codeGraphDao.getCallers(
          's_foo',
          checkoutId: 'wt2',
        )).map((s) => s.id),
        ['s_caller_wt2'],
      );
      // The linked reader sees neither worktree's caller.
      expect(await db.codeGraphDao.getCallers('s_foo'), isEmpty);
    });

    test('hasFiles answers per partition', () async {
      expect(await db.codeGraphDao.hasFiles('repo1'), isTrue);
      expect(
        await db.codeGraphDao.hasFiles('repo1', checkoutId: 'wt1'),
        isTrue,
      );
      // An unbuilt partition (worktree row exists, nothing indexed yet) is the
      // case the read path probes for before it trusts a worktree partition.
      expect(
        await db.codeGraphDao.hasFiles('repo1', checkoutId: 'wt2'),
        isFalse,
      );
      expect(await db.codeGraphDao.hasFiles('nope'), isFalse);
    });

    test('deleteByRepo wipes every partition of the repo', () async {
      await db.codeGraphDao.deleteByRepo('repo1');
      expect(await db.codeGraphDao.getFiles('repo1'), isEmpty);
      expect(
        await db.codeGraphDao.getFiles('repo1', checkoutId: 'wt1'),
        isEmpty,
      );
      expect(await db.codeGraphDao.getSymbolsByRepo('repo1'), isEmpty);
      expect(
        await db.codeGraphDao.getSymbolsByRepo('repo1', checkoutId: 'wt1'),
        isEmpty,
      );
    });
  });
}
