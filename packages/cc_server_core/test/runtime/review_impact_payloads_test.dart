import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/runtime/review_impact_payloads.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

CodeSymbolsTableCompanion _symbol(
  String id,
  String file, {
  required int lines,
}) => CodeSymbolsTableCompanion.insert(
  id: id,
  workspaceId: 'ws1',
  repoId: 'repo1',
  kind: 'method',
  name: id,
  qualifiedName: 'A.$id',
  filePath: file,
  language: 'dart',
  startLine: 1,
  endLine: 1 + lines,
);

CodeEdgesTableCompanion _calls(String source, String target) =>
    CodeEdgesTableCompanion.insert(
      id: '$source-$target',
      workspaceId: 'ws1',
      repoId: 'repo1',
      sourceSymbolId: source,
      kind: CodeEdgeKind.calls.name,
      targetSymbolId: Value(target),
      sourceFilePath: const Value('x.dart'),
    );

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    final global = createTestGlobalDatabase();
    final dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1', name: 'Test');
    db = dbs.of('ws1');
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'repo1', name: 'r', path: '/tmp/r'),
        );
    // a.dart's largest symbol is `big`. Impact walks reverse dependencies, so
    // both files reach `shared` through its calls: it calls b.dart's `solo`
    // directly and a.dart's `big` through `middle`.
    await db.codeGraphDao.upsertSymbols([
      _symbol('small', 'a.dart', lines: 1),
      _symbol('big', 'a.dart', lines: 20),
      _symbol('solo', 'b.dart', lines: 5),
      _symbol('middle', 'c.dart', lines: 2),
      _symbol('shared', 'd.dart', lines: 2),
    ]);
    await db.codeGraphDao.upsertEdges([
      _calls('middle', 'big'),
      _calls('shared', 'middle'),
      _calls('shared', 'solo'),
    ]);
  });

  group('fileBlastRadiusPayload', () {
    Future<Map<String, dynamic>> blast(String file) => fileBlastRadiusPayload(
      dao: db.codeGraphDao,
      workspaceId: 'ws1',
      repoId: 'repo1',
      filePath: file,
      depth: 2,
    );

    test('reports an unindexed file rather than an empty graph', () async {
      expect(await blast('missing.dart'), {
        'nodes': const <Object>[],
        'edges': const <Object>[],
        'indexed': false,
      });
    });

    test('roots at the file\'s largest symbol', () async {
      final payload = await blast('a.dart');
      expect(payload['indexed'], isTrue);
      expect(payload['root'], {
        'id': 'big',
        'name': 'big',
        'qualifiedName': 'A.big',
        'filePath': 'a.dart',
      });
    });
  });

  group('cohortImpactPayload', () {
    Future<Map<String, dynamic>> cohort(List<String> files) =>
        cohortImpactPayload(
          dao: db.codeGraphDao,
          workspaceId: 'ws1',
          repoId: 'repo1',
          filePaths: files,
          cohortKey: 'k',
          depth: 2,
        );

    test('reports an unindexed cohort', () async {
      expect((await cohort(['missing.dart']))['indexed'], isFalse);
    });

    test('takes one root per file and carries the cohort key', () async {
      final payload = await cohort(['a.dart', 'b.dart']);
      final roots = payload['roots'] as List<Object?>;
      expect(payload['cohort_key'], 'k');
      expect(roots.map((r) => (r! as Map<String, dynamic>)['id']).toSet(), {
        'big',
        'solo',
      });
    });

    test('a symbol reached twice keeps its shortest distance', () async {
      final payload = await cohort(['a.dart', 'b.dart']);
      final nodes = (payload['nodes'] as List<Object?>)
          .cast<Map<String, dynamic>>();
      final shared = nodes.where((n) => n['id'] == 'shared').toList();
      final solo = await db.codeGraphDao.getImpactRadius('ws1', 'solo');
      final big = await db.codeGraphDao.getImpactRadius('ws1', 'big');
      expect(big.depthById['shared'], 2);
      expect(solo.depthById['shared'], 1);
      expect(shared, hasLength(1));
      expect(shared.single['depth'], 1);
    });
  });
}
