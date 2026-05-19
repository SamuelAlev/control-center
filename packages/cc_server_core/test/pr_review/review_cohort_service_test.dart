import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/pr_review/review_axis_service.dart';
import 'package:cc_server_core/src/pr_review/review_cohort_service.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// A patch that adds [added] lines starting at head line [start].
String patchAdding(List<String> added, {int start = 10}) {
  final buf = StringBuffer('@@ -$start,1 +$start,${added.length + 1} @@\n')
    ..writeln(' context');
  for (final line in added) {
    buf.writeln('+$line');
  }
  return buf.toString();
}

void main() {
  const wsId = 'ws-test';
  const repoId = 'repo-a';
  const prId = 'PR_node';

  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late ReviewCohortService service;
  late DaoReviewCohortRepository cohorts;
  var idCounter = 0;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, wsId, name: 'Test Workspace');
    db = dbs.of(wsId);
    await db
        .into(db.reposTable)
        .insert(
          const ReposTableCompanion(
            id: Value(repoId),
            name: Value('test/repo'),
            path: Value('/tmp/test-repo'),
          ),
        );
    idCounter = 0;
    cohorts = DaoReviewCohortRepository(dbs);
    service = ReviewCohortService(
      workspaceDbs: dbs,
      cohorts: cohorts,
      idFactory: () => 'cohort-${idCounter++}',
    );
  });

  tearDown(() async {
    await db.close();
  });

  CodeSymbol sym({
    required String file,
    required String name,
    int startLine = 1,
    int endLine = 40,
    CodeSymbolKind kind = CodeSymbolKind.function,
  }) => CodeSymbol(
    id: codeSymbolId(wsId, repoId, file, name),
    workspaceId: wsId,
    repoId: repoId,
    kind: kind,
    name: name,
    qualifiedName: name,
    filePath: file,
    language: 'dart',
    startLine: startLine,
    endLine: endLine,
  );

  Future<void> ingest(String file, List<CodeSymbol> symbols) =>
      DaoCodeGraphRepository(dbs).ingestFile(
        workspaceId: wsId,
        repoId: repoId,
        filePath: file,
        contentHash: 'hash-$file',
        symbols: symbols,
        edges: const [],
      );

  /// Links `from`'s symbol to `to`'s symbol (a call), so the layer planner
  /// sees `to` as the more foundational file.
  Future<void> link(CodeSymbol from, CodeSymbol to) =>
      DaoCodeGraphRepository(dbs).ingestFile(
        workspaceId: wsId,
        repoId: repoId,
        filePath: from.filePath,
        contentHash: 'hash-${from.filePath}-linked',
        symbols: [from],
        edges: [
          CodeEdge(
            id: codeEdgeId(
              wsId,
              repoId,
              from.id,
              to.qualifiedName,
              CodeEdgeKind.calls.name,
            ),
            workspaceId: wsId,
            repoId: repoId,
            sourceSymbolId: from.id,
            sourceFilePath: from.filePath,
            targetSymbolId: to.id,
            targetName: to.qualifiedName,
            kind: CodeEdgeKind.calls,
          ),
        ],
      );

  group('ReviewCohortService.compute', () {
    test('an empty diff clears the PR\'s cohorts', () async {
      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const [],
      );
      expect(result, isEmpty);
      expect(await cohorts.forPr(wsId, prId), isEmpty);
    });

    test('an unindexed repo falls back to path grouping, honestly', () async {
      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/a.dart', 'lib/b.dart'],
      );
      expect(result, isNotEmpty);
      expect(result.first.derivation, CohortDerivation.path);
      expect(
        result.first.insights.symbolSource,
        SymbolSource.none,
        reason: 'no symbols were available, and the row says so',
      );
    });

    test('coverage stays UNKNOWN for an unindexed repo', () async {
      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/a.dart'],
      );
      final insights = result.first.insights;
      expect(insights.testCoverageKnown, isFalse);
      expect(
        insights.coveringTestCount,
        isNull,
        reason: '"cannot tell" must never render as "no tests"',
      );
    });

    test('emits real layers, not one per file basename', () async {
      final model = sym(file: 'lib/model.dart', name: 'Model');
      final handler = sym(file: 'lib/handler.dart', name: 'handle');
      await ingest('lib/model.dart', [model]);
      await ingest('lib/handler.dart', [handler]);
      await link(handler, model);

      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/handler.dart', 'lib/model.dart'],
      );

      final all = [for (final c in result) ...c.layers];
      expect(all, isNotEmpty);
      // The layer is titled by its dominant symbol and carries its span.
      final modelLayer = all.firstWhere((l) => l.filePath == 'lib/model.dart');
      expect(modelLayer.title, 'Model');
      expect(modelLayer.hasRange, isTrue);

      // Within whichever cohort holds both, the depended-upon file reads first.
      for (final cohort in result) {
        final paths = [for (final l in cohort.layers) l.filePath];
        if (paths.contains('lib/model.dart') &&
            paths.contains('lib/handler.dart')) {
          expect(
            paths.indexOf('lib/model.dart'),
            lessThan(paths.indexOf('lib/handler.dart')),
          );
        }
      }
    });

    test('records the symbols the diff actually touched', () async {
      final refresh = sym(
        file: 'lib/auth.dart',
        name: 'refresh',
        startLine: 5,
        endLine: 30,
      );
      await ingest('lib/auth.dart', [refresh]);

      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/auth.dart'],
        patchByFile: {
          'lib/auth.dart': patchAdding(['final x = 1;']),
        },
      );

      final changed = result.first.insights.changedSymbols;
      expect(changed, hasLength(1));
      expect(changed.single.symbol.name, 'refresh');
      expect(changed.single.addedLines, 1);
      expect(result.first.insights.symbolSource, SymbolSource.head);
    });

    test('finds the test file that references a changed symbol', () async {
      final refresh = sym(
        file: 'lib/auth.dart',
        name: 'refresh',
        startLine: 5,
        endLine: 30,
      );
      final testFn = sym(
        file: 'test/auth_test.dart',
        name: 'main',
        startLine: 1,
        endLine: 20,
      );
      await ingest('lib/auth.dart', [refresh]);
      await ingest('test/auth_test.dart', [testFn]);
      await link(testFn, refresh);

      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/auth.dart'],
        patchByFile: {
          'lib/auth.dart': patchAdding(['final x = 1;']),
        },
      );

      final insights = result.first.insights;
      expect(insights.testCoverageKnown, isTrue);
      expect(insights.coveringTests, contains('test/auth_test.dart'));
      expect(insights.coveringTestCount, 1);
    });

    test('reports known-zero coverage when no test references it', () async {
      final refresh = sym(
        file: 'lib/auth.dart',
        name: 'refresh',
        startLine: 5,
        endLine: 30,
      );
      await ingest('lib/auth.dart', [refresh]);

      final result = await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/auth.dart'],
        patchByFile: {
          'lib/auth.dart': patchAdding(['final x = 1;']),
        },
      );

      final insights = result.first.insights;
      expect(insights.testCoverageKnown, isTrue);
      expect(insights.coveringTestCount, 0);
    });

    test('replaces the previous cohort set on recompute', () async {
      await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha1',
        changedFiles: const ['lib/a.dart', 'lib/b.dart'],
      );
      await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha2',
        changedFiles: const ['lib/c.dart'],
      );
      final stored = await cohorts.forPr(wsId, prId);
      final paths = [for (final c in stored) ...c.filePaths];
      expect(paths, ['lib/c.dart']);
      expect(stored.every((c) => c.headSha == 'sha2'), isTrue);
    });

    test('insights survive the database round-trip', () async {
      final refresh = sym(file: 'lib/auth.dart', name: 'refresh');
      await ingest('lib/auth.dart', [refresh]);
      await service.compute(
        workspaceId: wsId,
        repoId: repoId,
        prExternalId: prId,
        headSha: 'sha',
        changedFiles: const ['lib/auth.dart'],
        patchByFile: {
          'lib/auth.dart': patchAdding(['final x = 1;']),
        },
      );
      final stored = await cohorts.forPr(wsId, prId);
      expect(stored.first.insights.changedSymbols, hasLength(1));
      expect(stored.first.insights.symbolSource, SymbolSource.head);
    });
  });

  group('ReviewAxisService.testGapAxisFromCohorts', () {
    ReviewCohort cohort({
      required String key,
      required CohortInsights insights,
      String title = 'Area',
    }) => ReviewCohort(
      id: key,
      workspaceId: wsId,
      prExternalId: prId,
      cohortKey: key,
      title: title,
      orderIndex: 0,
      impactScore: 1,
      insights: insights,
    );

    test('is UNAVAILABLE, never pass, when nothing could be determined', () {
      final result = ReviewAxisService.testGapAxisFromCohorts([
        cohort(key: 'a', insights: const CohortInsights()),
      ]);
      expect(result.verdict, ReviewAxisVerdict.unavailable);
      expect(
        result.verdict.clearsGate,
        isFalse,
        reason: 'absence of evidence must never green a gate',
      );
    });

    test('warns and names the areas with no covering test', () {
      final result = ReviewAxisService.testGapAxisFromCohorts([
        cohort(
          key: 'a',
          title: 'Auth flow',
          insights: const CohortInsights(testCoverageKnown: true),
        ),
      ]);
      expect(result.verdict, ReviewAxisVerdict.warn);
      expect(result.note, contains('Auth flow'));
    });

    test('passes when every determinable area has a referencing test', () {
      final result = ReviewAxisService.testGapAxisFromCohorts([
        cohort(
          key: 'a',
          insights: const CohortInsights(
            coveringTests: ['test/a_test.dart'],
            testCoverageKnown: true,
          ),
        ),
      ]);
      expect(result.verdict, ReviewAxisVerdict.pass);
    });

    test('is advisory, so it never re-gates the verdict', () {
      final result = ReviewAxisService.testGapAxisFromCohorts([
        cohort(
          key: 'a',
          insights: const CohortInsights(testCoverageKnown: true),
        ),
      ]);
      expect(result.gated, isFalse);
      expect(result.blocks, isFalse);
    });
  });
}
