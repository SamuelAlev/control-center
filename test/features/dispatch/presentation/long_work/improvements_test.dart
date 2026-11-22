import 'dart:async';

import 'package:cc_data/cc_data.dart'
    show SkillCampaignCapabilities, SkillCorporaView, SkillCorpusView;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_harness/provider.dart' show HarnessModelInfo;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvements_list.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

void main() {
  late FakeInboxRepository repo;

  setUp(() => repo = FakeInboxRepository());

  AppLocalizations l10n(WidgetTester tester, Type type) =>
      AppLocalizations.of(tester.element(find.byType(type)));

  final campaignOverrides = [
    skillCorporaProvider.overrideWith(
      (ref, ws) async => const SkillCorporaView(
        corpora: [
          SkillCorpusView(
            id: 'corpus-1',
            name: 'Release tasks',
            description: '',
            taskCount: 4,
            tags: [],
          ),
        ],
        capabilities: SkillCampaignCapabilities(
          available: true,
          reason: null,
          backends: ['harness'],
        ),
      ),
    ),
    harnessModelsProvider.overrideWith(
      (ref) async => const [
        HarnessModelInfo(id: 'openai/gpt-x', providerId: 'openai'),
      ],
    ),
  ];

  ImprovementProposalView view({
    ImprovementKind kind = ImprovementKind.memoryFact,
    ImprovementStatus status = ImprovementStatus.proposed,
    ImprovementCampaignState campaign = ImprovementCampaignState.none,
    bool needsAdmin = false,
    String id = 'prop-1',
    String? candidate,
    ImprovementEvaluationSummary? evaluation,
  }) => ImprovementProposalView(
    proposal: proposalFixture(
      id: id,
      kind: kind,
      status: status,
      campaignState: campaign,
      candidateRevisionId: candidate,
    ),
    needsAdmin: needsAdmin,
    evaluation: evaluation,
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    WorkspaceRole role = WorkspaceRole.admin,
    TextDirection? dir,
    bool settle = true,
  }) => pumpLongWork(
    tester,
    const ImprovementPage(workspaceId: kTestWorkspaceId, proposalId: 'prop-1'),
    overrides: [
      ...longWorkOverrides(inbox: repo, role: role),
      ...campaignOverrides,
    ],
    textDirection: dir,
    settle: settle,
  );

  CcButton button(WidgetTester tester, String label) => tester.widget<CcButton>(
    find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
  );

  group('inbox', () {
    Future<void> pumpList(WidgetTester tester) => pumpLongWork(
      tester,
      const ImprovementsList(workspaceId: kTestWorkspaceId),
      overrides: longWorkOverrides(inbox: repo),
      settle: repo.views != null,
    );

    testWidgets('loading', (tester) async {
      repo.views = null;
      await pumpList(tester);
      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpList(tester);
      expect(
        find.text(l10n(tester, ImprovementsList).improvementsEmpty),
        findsOneWidget,
      );
    });

    testWidgets('refused', (tester) async {
      repo.watchError = refusal('mystery_kind');
      await pumpList(tester);
      expect(find.textContaining('mystery_kind'), findsOneWidget);
    });

    testWidgets('grouped by status, with the admin note', (tester) async {
      repo.views = [
        view(needsAdmin: true),
        view(id: 'prop-2', status: ImprovementStatus.accepted),
      ];
      await pumpList(tester);
      final l = l10n(tester, ImprovementsList);
      expect(find.textContaining(l.improvementStatusProposed), findsWidgets);
      expect(find.textContaining(l.improvementStatusAccepted), findsWidgets);
      expect(find.text(l.improvementRowNeedsAdmin), findsOneWidget);
    });
  });

  group('page', () {
    testWidgets('not found', (tester) async {
      await pumpPage(tester);
      expect(
        find.text(l10n(tester, ImprovementPage).improvementNotFound),
        findsOneWidget,
      );
    });

    testWidgets('a replace shows a before and after diff and evidence', (
      tester,
    ) async {
      repo.views = [view()];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.byType(InlineDiffView), findsOneWidget);
      expect(find.text('Fewer weekend incidents'), findsOneWidget);
      expect(find.text('run-7'), findsOneWidget);
      expect(find.text(l.improvementOpenMessage(1)), findsOneWidget);
    });

    testWidgets('accept and reject send their operations', (tester) async {
      repo.views = [view()];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      await tester.tap(find.text(l.improvementAccept));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.improvementReject));
      await tester.pumpAndSettle();
      expect(repo.calls, [
        'accept:$kTestWorkspaceId:prop-1',
        'reject:$kTestWorkspaceId:prop-1',
      ]);
    });

    testWidgets('roll back confirms first', (tester) async {
      repo.views = [view(status: ImprovementStatus.accepted)];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      await tester.tap(find.text(l.improvementRollback));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      await tester.tap(find.text(l.improvementRollback).last);
      await tester.pumpAndSettle();
      expect(repo.calls, ['rollback:$kTestWorkspaceId:prop-1']);
    });

    testWidgets('a member cannot decide what needs an admin, and is told why', (
      tester,
    ) async {
      repo.views = [view(needsAdmin: true)];
      await pumpPage(tester, role: WorkspaceRole.member);
      final l = l10n(tester, ImprovementPage);
      expect(button(tester, l.improvementAccept).onPressed, isNull);
      expect(button(tester, l.improvementReject).onPressed, isNull);
      expect(find.text(l.improvementNeedsAdmin), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is WorkTip && w.message == l.improvementNeedsAdmin,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('an admin sees it is theirs to decide', (tester) async {
      repo.views = [view(needsAdmin: true)];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementAdminDecides), findsOneWidget);
      expect(button(tester, l.improvementAccept).onPressed, isNotNull);
    });

    testWidgets('a skill change is accepted only after a passed campaign', (
      tester,
    ) async {
      repo.views = [view(kind: ImprovementKind.skillEdit)];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(button(tester, l.improvementAccept).onPressed, isNull);
      expect(find.text(l.improvementNeedsCampaign), findsOneWidget);

      await tester.tap(find.text(l.improvementRunEvaluation));
      await tester.pumpAndSettle();
      expect(find.text(l.improvementCampaignTitle), findsOneWidget);
      expect(find.textContaining(r'It spends at most $5'), findsOneWidget);
      for (final (label, choice) in [
        (l.improvementCampaignCorpus, 'Release tasks'),
        (l.improvementCampaignProvider, 'openai'),
        (l.improvementCampaignModel, 'gpt-x'),
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(l.improvementCampaignStart));
      await tester.pumpAndSettle();
      expect(repo.calls, [
        'startCampaign:prop-1:corpus-1:openai:gpt-x:3:5000000',
      ]);

      repo.views = [
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.passed,
        ),
      ];
      await pumpPage(tester);
      expect(button(tester, l.improvementAccept).onPressed, isNotNull);
      expect(find.text(l.improvementRunEvaluation), findsNothing);
    });

    testWidgets('a skill change says its candidate is staged, not live', (
      tester,
    ) async {
      // Nothing is stored before a start: the page does not claim it.
      repo.views = [view(kind: ImprovementKind.skillEdit)];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementCandidateStaged), findsNothing);
      await tester.tap(find.text(l.improvementRunEvaluation));
      await tester.pumpAndSettle();
      expect(find.text(l.improvementCandidateStaged), findsOneWidget);

      repo.views = [
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.passed,
          candidate: 'rev-abc',
        ),
      ];
      await pumpPage(tester);
      expect(find.text(l.improvementCandidateStaged), findsOneWidget);
    });

    ImprovementEvaluationSummary evaluation({
      int paired = 12,
      int candidate = 9,
      int baseline = 9,
      int worse = 0,
      int costlier = 0,
      int harness = 0,
      bool complete = true,
      int? violations = 0,
    }) => ImprovementEvaluationSummary(
      pairedRuns: paired,
      candidateSolved: candidate,
      baselineSolved: baseline,
      verdict: ImprovementVerdict.inconclusive,
      qualityLosses: worse,
      costRegressions: costlier,
      harnessErrors: harness,
      coverageComplete: complete,
      planViolations: violations,
    );

    testWidgets('a passed evaluation shows its numbers, without a claim', (
      tester,
    ) async {
      repo.views = [
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.passed,
          candidate: 'rev-abc',
          evaluation: evaluation(worse: 2),
        ),
      ];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementCampaignPassed), findsOneWidget);
      expect(l.improvementCampaignPassed, contains('does not prove'));
      // Zero counts are left out, never printed as a zero.
      expect(
        find.text(
          '${l.improvementEvaluationSolved(12, 9, 9)} '
          '${l.improvementEvaluationWorse(2)}',
        ),
        findsOneWidget,
      );
      expect(find.text(l.improvementEvaluationSolved(12, 9, 9)), findsNothing);
      expect(
        find.textContaining(l.improvementEvaluationHarnessErrors(1)),
        findsNothing,
      );
      expect(button(tester, l.improvementAccept).onPressed, isNotNull);
    });

    testWidgets('a failed evaluation says what went wrong in numbers', (
      tester,
    ) async {
      repo.views = [
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.failed,
          evaluation: evaluation(
            paired: 1,
            candidate: 0,
            baseline: 1,
            costlier: 1,
            harness: 3,
            complete: false,
          ),
        ),
      ];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementCampaignFailed), findsOneWidget);
      expect(
        find.text(
          [
            'In 1 paired run, the change solved 0 and the current skill solved 1.',
            '1 task cost more with the change.',
            '3 runs hit a harness error.',
            'The evaluation did not run in full.',
          ].join(' '),
        ),
        findsOneWidget,
      );
      expect(button(tester, l.improvementRunEvaluation).onPressed, isNotNull);
    });

    testWidgets('no evaluation yet shows no numbers', (tester) async {
      repo.views = [view(kind: ImprovementKind.skillEdit)];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementCampaignNone), findsOneWidget);
      expect(find.textContaining('paired run'), findsNothing);
    });

    testWidgets('accept refused on a moved skill offers the evaluation again', (
      tester,
    ) async {
      final live = StreamController<List<ImprovementProposalView>>();
      addTearDown(live.close);
      repo.live = live;
      final passed = view(
        kind: ImprovementKind.skillEdit,
        campaign: ImprovementCampaignState.passed,
        candidate: 'rev-abc',
        evaluation: evaluation(),
      );
      live.add([passed]);
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementRunEvaluation), findsNothing);

      repo.error = refusal('improvement_campaign_required');
      await tester.tap(find.text(l.improvementAccept));
      await tester.pumpAndSettle();
      expect(find.text(l.improvementRefusalCampaignRequired), findsOneWidget);
      expect(
        l.improvementRefusalCampaignRequired,
        contains('the skill changed after it was measured'),
      );

      // The server left the row failed and dropped its stage.
      live.add([
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.failed,
          evaluation: evaluation(),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(l.improvementCampaignFailed), findsOneWidget);
      expect(find.text(l.improvementCandidateStaged), findsNothing);
      expect(button(tester, l.improvementAccept).onPressed, isNull);
      expect(button(tester, l.improvementRunEvaluation).onPressed, isNotNull);
    });

    testWidgets('a campaign being staged reads as running', (tester) async {
      repo.views = [
        view(
          kind: ImprovementKind.skillEdit,
          campaign: ImprovementCampaignState.staging,
        ),
      ];
      // The Run evaluation button spins while the campaign starts.
      await pumpPage(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      final l = l10n(tester, ImprovementPage);
      expect(find.text(l.improvementCampaignRunning), findsOneWidget);
      expect(button(tester, l.improvementRunEvaluation).onPressed, isNull);
      expect(button(tester, l.improvementAccept).onPressed, isNull);
    });

    testWidgets('accept refused because the skill changed says so', (
      tester,
    ) async {
      repo.views = [view()];
      await pumpPage(tester);
      final l = l10n(tester, ImprovementPage);
      repo.error = refusal('improvement_changed_since');
      await tester.tap(find.text(l.improvementAccept));
      await tester.pumpAndSettle();
      expect(find.text(l.improvementRefusalChangedSince), findsOneWidget);
    });

    testWidgets('right to left lays the page out without errors', (
      tester,
    ) async {
      repo.views = [view()];
      await pumpPage(tester, dir: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.byType(InlineDiffView), findsOneWidget);
    });
  });
}
