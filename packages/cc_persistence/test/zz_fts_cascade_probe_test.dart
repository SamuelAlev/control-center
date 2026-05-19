// TEMPORARY probe: does an FK ON DELETE CASCADE fire the code_symbols_ad
// trigger that removes the row from the external-content FTS index?
import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  test('probe: FTS index after FK cascade', () async {
    final db = createTestDatabase();
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'repo1', name: 'r', path: '/tmp/r'),
        );
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
            sourcePath: '/tmp/r',
          ),
        );
    await db.codeGraphDao.upsertSymbols([
      CodeSymbolsTableCompanion.insert(
        id: 's_new',
        workspaceId: 'ws1',
        repoId: 'repo1',
        checkoutId: const Value('wt1'),
        kind: 'method',
        name: 'zzUniqueThing',
        qualifiedName: 'A.zzUniqueThing',
        filePath: 'pr.dart',
        language: 'dart',
        startLine: 1,
        endLine: 2,
      ),
    ]);

    Future<List<int>> ftsRowids() async {
      final rows = await db
          .customSelect(
            'SELECT rowid AS r FROM code_symbols_fts '
            "WHERE code_symbols_fts MATCH 'zzUniqueThing'",
          )
          .get();
      return [for (final r in rows) r.data['r'] as int];
    }

    stdout.writeln(
      'recursive_triggers = '
      '${(await db.customSelect('PRAGMA recursive_triggers').getSingle()).data}',
    );
    stdout.writeln('FTS rowids before delete: ${await ftsRowids()}');

    // Direct row delete (control): the AFTER DELETE trigger definitely fires.
    await db.isolatedRepoDao.deleteById('wt1');

    stdout.writeln(
      'code_symbols rows after cascade: '
      '${(await db.codeGraphDao.getSymbolsByRepo('ws1', 'repo1', checkoutId: 'wt1')).length}',
    );
    final after = await ftsRowids();
    stdout.writeln(
      'FTS rowids AFTER cascade delete: $after  '
      '${after.isEmpty ? '=> trigger fired, index clean' : '=> ORPHANED FTS ENTRY'}',
    );

    await db.close();
  });
}
