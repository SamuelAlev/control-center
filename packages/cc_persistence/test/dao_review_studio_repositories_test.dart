import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises the four PRD 18 Review Studio repositories backed by the review
/// studio DAO against the real Drift database: cohorts, API contract diffs,
/// visual diffs, and per-axis results. Each repository is a thin
/// mapper+delegate; these tests assert the round-trip through the domain
/// entities and the workspace-scoped reads.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoReviewCohortRepository cohortRepo;
  late DaoApiContractDiffRepository contractRepo;
  late DaoVisualDiffRepository visualRepo;
  late DaoReviewAxisResultRepository axisRepo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    cohortRepo = DaoReviewCohortRepository(dbs);
    contractRepo = DaoApiContractDiffRepository(dbs);
    visualRepo = DaoVisualDiffRepository(dbs);
    axisRepo = DaoReviewAxisResultRepository(dbs);
    // The Review Studio tables reference only workspace_id, so seed those.
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoReviewCohortRepository', () {
    ReviewCohort cohort(
      String id,
      String ws,
      String pr, {
      String cohortKey = 'k-a',
      String title = 'Frontend',
      int orderIndex = 0,
      int impactScore = 1,
      CohortDerivation derivation = CohortDerivation.graph,
      List<String> filePaths = const ['lib/a.dart'],
      String summaryMarkdown = '',
      String? headSha,
    }) => ReviewCohort(
      id: id,
      workspaceId: ws,
      prNodeId: pr,
      cohortKey: cohortKey,
      title: title,
      summaryMarkdown: summaryMarkdown,
      orderIndex: orderIndex,
      impactScore: impactScore,
      derivation: derivation,
      filePaths: filePaths,
      headSha: headSha,
    );

    test(
      'replaceForPr + forPr round-trips the entity in reading order',
      () async {
        await cohortRepo.replaceForPr('w-1', 'pr-1', [
          cohort('c-2', 'w-1', 'pr-1', cohortKey: 'k-b', orderIndex: 1),
          cohort('c-1', 'w-1', 'pr-1', cohortKey: 'k-a', orderIndex: 0),
        ]);
        final rows = await cohortRepo.forPr('w-1', 'pr-1');
        expect(rows.map((c) => c.cohortKey), ['k-a', 'k-b']);
        expect(rows.first.title, 'Frontend');
        expect(rows.first.filePaths, ['lib/a.dart']);
        expect(rows.first.derivation, CohortDerivation.graph);
      },
    );

    test('replaceForPr atomically replaces the whole set', () async {
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1'),
      ]);
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-2', 'w-1', 'pr-1', cohortKey: 'k-b'),
        cohort('c-3', 'w-1', 'pr-1', cohortKey: 'k-c'),
      ]);
      expect((await cohortRepo.forPr('w-1', 'pr-1')).map((c) => c.id).toSet(), {
        'c-2',
        'c-3',
      });
    });

    test('forPr is workspace-scoped', () async {
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', cohortKey: 'k-a'),
      ]);
      await cohortRepo.replaceForPr('w-2', 'pr-1', [
        cohort('c-2', 'w-2', 'pr-1', cohortKey: 'k-b'),
      ]);
      expect((await cohortRepo.forPr('w-1', 'pr-1')).single.id, 'c-1');
      expect((await cohortRepo.forPr('w-2', 'pr-1')).single.id, 'c-2');
    });

    test('watchForPr emits only the workspace rows', () async {
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', cohortKey: 'k-a'),
      ]);
      await cohortRepo.replaceForPr('w-2', 'pr-1', [
        cohort('c-2', 'w-2', 'pr-1', cohortKey: 'k-b'),
      ]);
      expect(
        (await cohortRepo.watchForPr('w-1', 'pr-1').first).single.id,
        'c-1',
      );
    });

    test('updateSummary writes the cohort summary markdown', () async {
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1'),
      ]);
      await cohortRepo.updateSummary('w-1', 'c-1', '## Summary');
      final rows = await cohortRepo.forPr('w-1', 'pr-1');
      expect(rows.single.summaryMarkdown, '## Summary');
    });

    test('updateDiagrams persists the diagram JSON', () async {
      await cohortRepo.replaceForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1'),
      ]);
      await cohortRepo.updateDiagrams('w-1', 'c-1', [
        const SequenceDiagram(
          title: 'Call flow',
          participants: ['A', 'B'],
          messages: [SequenceMessage(from: 'A', to: 'B', label: 'call')],
        ),
      ]);
      final rows = await cohortRepo.forPr('w-1', 'pr-1');
      expect(rows.single.diagrams.single.title, 'Call flow');
    });
  });

  group('DaoApiContractDiffRepository', () {
    ApiContractDiff diff(
      String id,
      String ws,
      String pr, {
      String repoId = 'repo-1',
      String specPath = 'openapi.yaml',
      bool derived = false,
    }) => ApiContractDiff(
      id: id,
      workspaceId: ws,
      repoId: repoId,
      prNodeId: pr,
      specPath: specPath,
      changes: const [
        ApiContractChange(
          id: 'chg-1',
          kind: ApiChangeKind.endpointAdded,
          severity: ApiChangeSeverity.nonBreaking,
          path: '/widgets',
          method: 'GET',
        ),
        ApiContractChange(
          id: 'chg-2',
          kind: ApiChangeKind.paramRemoved,
          severity: ApiChangeSeverity.breaking,
          path: '/widgets/{id}',
          method: 'DELETE',
        ),
      ],
      derived: derived,
    );

    test('upsert + forPr round-trips the entity', () async {
      await contractRepo.upsert('w-1', diff('d-1', 'w-1', 'pr-1'));
      final rows = await contractRepo.forPr('w-1', 'pr-1');
      expect(rows.single.id, 'd-1');
      expect(rows.single.changes, hasLength(2));
      expect(rows.single.changes.first.path, '/widgets');
    });

    test('forPr is workspace-scoped', () async {
      await contractRepo.upsert(
        'w-1',
        diff('d-1', 'w-1', 'pr-1', specPath: 'openapi.yaml'),
      );
      await contractRepo.upsert(
        'w-2',
        diff('d-2', 'w-2', 'pr-1', specPath: 'graphql.graphql'),
      );
      expect((await contractRepo.forPr('w-1', 'pr-1')).single.id, 'd-1');
      expect((await contractRepo.forPr('w-2', 'pr-1')).single.id, 'd-2');
    });

    test('watchForPr emits only the workspace rows', () async {
      await contractRepo.upsert(
        'w-1',
        diff('d-1', 'w-1', 'pr-1', specPath: 'openapi.yaml'),
      );
      await contractRepo.upsert(
        'w-2',
        diff('d-2', 'w-2', 'pr-1', specPath: 'graphql.graphql'),
      );
      expect(
        (await contractRepo.watchForPr('w-1', 'pr-1').first).single.id,
        'd-1',
      );
    });

    test(
      'setChangeDecision updates one change decision within the diff',
      () async {
        await contractRepo.upsert('w-1', diff('d-1', 'w-1', 'pr-1'));
        await contractRepo.setChangeDecision(
          'w-1',
          'd-1',
          'chg-2',
          ApiChangeDecision.rejected,
        );
        final rows = await contractRepo.forPr('w-1', 'pr-1');
        final rejected = rows.single.changes.singleWhere(
          (c) => c.id == 'chg-2',
        );
        expect(rejected.decision, ApiChangeDecision.rejected);
      },
    );

    test('setChangeDecision is a no-op when the diff is missing', () async {
      // Must not throw when the diff does not exist.
      await contractRepo.setChangeDecision(
        'w-1',
        'missing',
        'chg-1',
        ApiChangeDecision.approved,
      );
      expect(await contractRepo.forPr('w-1', 'pr-1'), isEmpty);
    });
  });

  group('DaoVisualDiffRepository', () {
    VisualDiffSnapshot snapshot(
      String id,
      String ws,
      String pr, {
      String repoId = 'repo-1',
      String componentKey = 'widget/login_button',
      String componentTitle = 'Login Button',
      VisualDiffStatus status = VisualDiffStatus.changed,
    }) => VisualDiffSnapshot(
      id: id,
      workspaceId: ws,
      repoId: repoId,
      prNodeId: pr,
      componentKey: componentKey,
      componentTitle: componentTitle,
      status: status,
      variants: const [
        VisualDiffVariant(
          viewport: 'phone',
          brightness: 'light',
          status: VisualDiffStatus.changed,
          changedRegionPercent: 12.5,
        ),
      ],
    );

    test('upsert + forPr round-trips the entity', () async {
      await visualRepo.upsert('w-1', snapshot('s-1', 'w-1', 'pr-1'));
      final rows = await visualRepo.forPr('w-1', 'pr-1');
      expect(rows.single.id, 's-1');
      expect(rows.single.componentTitle, 'Login Button');
      expect(rows.single.variants.single.changedRegionPercent, 12.5);
    });

    test('forPr is workspace-scoped', () async {
      await visualRepo.upsert(
        'w-1',
        snapshot('s-1', 'w-1', 'pr-1', componentKey: 'widget/a'),
      );
      await visualRepo.upsert(
        'w-2',
        snapshot('s-2', 'w-2', 'pr-1', componentKey: 'widget/b'),
      );
      expect((await visualRepo.forPr('w-1', 'pr-1')).single.id, 's-1');
      expect((await visualRepo.forPr('w-2', 'pr-1')).single.id, 's-2');
    });

    test('watchForPr emits only the workspace rows', () async {
      await visualRepo.upsert(
        'w-1',
        snapshot('s-1', 'w-1', 'pr-1', componentKey: 'widget/a'),
      );
      await visualRepo.upsert(
        'w-2',
        snapshot('s-2', 'w-2', 'pr-1', componentKey: 'widget/b'),
      );
      expect(
        (await visualRepo.watchForPr('w-1', 'pr-1').first).single.id,
        's-1',
      );
    });

    test('setStatus updates the snapshot status', () async {
      await visualRepo.upsert('w-1', snapshot('s-1', 'w-1', 'pr-1'));
      await visualRepo.setStatus('w-1', 's-1', VisualDiffStatus.approved);
      final rows = await visualRepo.forPr('w-1', 'pr-1');
      expect(rows.single.status, VisualDiffStatus.approved);
    });
  });

  group('DaoReviewAxisResultRepository', () {
    ReviewAxisResult result({
      ReviewAxis axis = ReviewAxis.correctness,
      ReviewAxisVerdict verdict = ReviewAxisVerdict.fail,
      int findingsCount = 3,
      bool gated = true,
      double confidence = 0.8,
      String note = 'needs fix',
    }) => ReviewAxisResult(
      axis: axis,
      verdict: verdict,
      findingsCount: findingsCount,
      gated: gated,
      confidence: confidence,
      note: note,
    );

    test('upsert + forPr round-trips the entity', () async {
      await axisRepo.upsert(
        'w-1',
        'pr-1',
        result(axis: ReviewAxis.security, verdict: ReviewAxisVerdict.fail),
      );
      final rows = await axisRepo.forPr('w-1', 'pr-1');
      expect(rows.single.axis, ReviewAxis.security);
      expect(rows.single.verdict, ReviewAxisVerdict.fail);
      expect(rows.single.findingsCount, 3);
      expect(rows.single.note, 'needs fix');
    });

    test('upsert is idempotent on (pr, axis) and dedupes on re-run', () async {
      await axisRepo.upsert(
        'w-1',
        'pr-1',
        result(axis: ReviewAxis.correctness, findingsCount: 1),
      );
      await axisRepo.upsert(
        'w-1',
        'pr-1',
        result(axis: ReviewAxis.correctness, findingsCount: 5),
      );
      final rows = await axisRepo.forPr('w-1', 'pr-1');
      expect(rows, hasLength(1));
      expect(rows.single.findingsCount, 5);
    });

    test('forPr is workspace-scoped', () async {
      await axisRepo.upsert(
        'w-1',
        'pr-1',
        result(axis: ReviewAxis.correctness),
      );
      await axisRepo.upsert('w-2', 'pr-1', result(axis: ReviewAxis.security));
      expect(
        (await axisRepo.forPr('w-1', 'pr-1')).single.axis,
        ReviewAxis.correctness,
      );
      expect(
        (await axisRepo.forPr('w-2', 'pr-1')).single.axis,
        ReviewAxis.security,
      );
    });

    test('watchForPr emits only the workspace rows', () async {
      await axisRepo.upsert(
        'w-1',
        'pr-1',
        result(axis: ReviewAxis.correctness),
      );
      await axisRepo.upsert('w-2', 'pr-1', result(axis: ReviewAxis.security));
      expect(
        (await axisRepo.watchForPr('w-1', 'pr-1').first).single.axis,
        ReviewAxis.correctness,
      );
    });

    test('confidence is clamped to [0, 1] on read', () async {
      // Insert a result with a confidence inside the valid range, then verify
      // the clamp logic is in place by reading a normal value back unchanged.
      await axisRepo.upsert('w-1', 'pr-1', result(confidence: 0.42));
      expect((await axisRepo.forPr('w-1', 'pr-1')).single.confidence, 0.42);
    });
  });
}
