import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        ImprovementRefusedException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/ports/improvement_apply_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AdmittedSkillEvaluationSnapshot,
        SkillEvaluationSnapshotStore,
        SkillPackageSnapshot;
import 'package:cc_server_core/src/catalog/improvement_ops.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_rpc_ops.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';
import 'package:cc_server_core/src/learning/improvement_adoption_service.dart';
import 'package:cc_server_core/src/learning/improvement_evaluation.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart'
    show storageBusyKind;
import 'package:test/test.dart';

part 'improvement_adoption_fakes.dart';

const _ws = 'ws-1';
const _other = 'ws-2';
final _t0 = DateTime.utc(2026, 11, 19, 14);

void main() {
  group('accept writes with provenance', () {
    test('a memory fact: added, then rolled back', () async {
      final kit = _Kit();
      final accepted = await kit.service.accept(kit.add(), userId: 'user-1');
      expect(accepted.status, ImprovementStatus.accepted);
      expect(accepted.decidedByUserId, 'user-1');
      expect(accepted.beforeText, isNull);
      expect(accepted.afterText, 'Run make gen before make test.');
      expect(accepted.appliedRef, 'memory_fact:refine-p-1');
      final fact = kit.facts.byId['refine-p-1']!;
      expect(fact.domain, kLessonsDomain);
      expect(fact.topic, 'build');
      expect(fact.sourceObservationIds, ['refine:p-1']);

      final rolled = await kit.service.rollback(accepted, userId: 'user-1');
      expect(rolled.status, ImprovementStatus.rolledBack);
      expect(kit.facts.byId, isEmpty);
    });

    test('a policy: replaced, and a later edit stops the rollback', () async {
      final kit = _Kit();
      kit.policies.byId['pol-1'] = MemoryPolicy(
        id: 'pol-1',
        workspaceId: _ws,
        domain: 'build',
        rule: 'Run the tests.',
        sourceFactIds: const [],
        createdAt: _t0,
        updatedAt: _t0,
      );
      final accepted = await kit.service.accept(
        kit.add(
          kind: ImprovementKind.policy,
          operation: ImprovementOperation.replace,
          targetRef: 'pol-1',
        ),
        userId: 'user-1',
      );
      expect(accepted.beforeText, 'Run the tests.');
      final policy = kit.policies.byId['pol-1']!;
      expect(policy.rule, 'Run make gen before make test.');
      expect(policy.sourceFactIds, ['refine:p-1']);

      kit.policies.byId['pol-1'] = policy.copyWith(rule: 'Someone else.');
      await expectLater(
        kit.service.rollback(accepted, userId: 'user-1'),
        _refused(ImprovementRefusedException.changedSinceKind),
      );
      expect(kit.policies.byId['pol-1']!.rule, 'Someone else.');
      expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.accepted);
    });

    test(
      'an agent note: appended with its marker, restored on rollback',
      () async {
        final kit = _Kit();
        kit.notes.byAgent['agent-1'] = AgentWorkingMemory(
          id: 'n-1',
          workspaceId: _ws,
          agentId: 'agent-1',
          content: 'Prefer small commits.',
          updatedAt: _t0,
        );
        final accepted = await kit.service.accept(
          kit.add(
            kind: ImprovementKind.agentNote,
            scope: ImprovementScope.agent,
            targetRef: null,
          ),
          userId: 'user-1',
        );
        expect(
          kit.notes.byAgent['agent-1']!.content,
          'Prefer small commits.\n\n[refine:p-1] Run make gen before make test.',
        );
        await kit.service.rollback(accepted, userId: 'user-1');
        expect(kit.notes.byAgent['agent-1']!.content, 'Prefer small commits.');
      },
    );

    test('a decided proposal is not decided again', () async {
      final kit = _Kit();
      final p = kit.add();
      await kit.service.reject(p, userId: 'user-1');
      await expectLater(
        kit.service.accept(p, userId: 'user-2'),
        _refused(ImprovementRefusedException.alreadyDecidedKind),
      );
      expect(kit.facts.byId, isEmpty);
    });

    test('a replace whose fact is gone refuses and writes nothing', () async {
      final kit = _Kit();
      await expectLater(
        kit.service.accept(
          kit.add(operation: ImprovementOperation.replace, targetRef: 'f-x'),
          userId: 'user-1',
        ),
        _refused(ImprovementRefusedException.targetMissingKind),
      );
      expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.proposed);
    });
  });

  group('accept and rollback write what they read', () {
    AgentWorkingMemory note(String content, DateTime at) => AgentWorkingMemory(
      id: 'n-1',
      workspaceId: _ws,
      agentId: 'agent-1',
      content: content,
      updatedAt: at,
    );

    ImprovementProposal noteProposal(_Kit kit) => kit.add(
      kind: ImprovementKind.agentNote,
      scope: ImprovementScope.agent,
      targetRef: null,
    );

    test("the agent's own note edit between plan and apply is kept: the "
        'accept is refused as changed since', () async {
      final kit = _Kit();
      kit.notes.byAgent['agent-1'] = note('Prefer small commits.', _t0);
      final own = note('Prefer small commits. Rebase daily.', _t0);
      kit.apply.between = () async => kit.notes.byAgent['agent-1'] = own;
      await expectLater(
        kit.service.accept(noteProposal(kit), userId: 'user-1'),
        _refused(ImprovementRefusedException.changedSinceKind),
      );
      expect(kit.notes.byAgent['agent-1'], same(own));
      expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.proposed);
    });

    test('a crash between claim and apply leaves nothing half-done', () async {
      final kit = _Kit();
      kit.notes.byAgent['agent-1'] = note('Prefer small commits.', _t0);
      kit.apply.between = () async => throw StateError('server died');
      await expectLater(
        kit.service.accept(noteProposal(kit), userId: 'user-1'),
        throwsStateError,
      );
      expect(kit.notes.byAgent['agent-1']!.content, 'Prefer small commits.');
      final p = kit.proposals.byId['p-1']!;
      expect(p.status, ImprovementStatus.proposed);
      expect(p.appliedRef, isNull);
    });

    test("a policy's remove is rolled back only while its turning off is the "
        'last change', () async {
      MemoryPolicy policy() => MemoryPolicy(
        id: 'pol-1',
        workspaceId: _ws,
        domain: 'build',
        rule: 'Run the tests.',
        sourceFactIds: const [],
        createdAt: _t0,
        updatedAt: _t0,
      );
      ImprovementProposal remove(_Kit kit) => kit.add(
        kind: ImprovementKind.policy,
        operation: ImprovementOperation.remove,
        targetRef: 'pol-1',
      );

      final kit = _Kit();
      kit.policies.byId['pol-1'] = policy();
      kit.now = _t0.add(const Duration(hours: 1));
      final accepted = await kit.service.accept(remove(kit), userId: 'u-1');
      final off = kit.policies.byId['pol-1']!;
      expect(off.active, isFalse);
      expect(off.sourceFactIds, ['refine:p-1']);
      await kit.service.rollback(accepted, userId: 'u-1');
      final back = kit.policies.byId['pol-1']!;
      expect(back.active, isTrue);
      expect(back.sourceFactIds, isEmpty);

      // A person turned it on and off again after the remove: not ours now.
      final other = _Kit();
      other.policies.byId['pol-1'] = policy();
      other.now = _t0.add(const Duration(hours: 1));
      final removed = await other.service.accept(remove(other), userId: 'u-1');
      other.policies.byId['pol-1'] = other.policies.byId['pol-1']!.copyWith(
        updatedAt: _t0.add(const Duration(hours: 2)),
      );
      await expectLater(
        other.service.rollback(removed, userId: 'u-1'),
        _refused(ImprovementRefusedException.changedSinceKind),
      );
      expect(other.policies.byId['pol-1']!.active, isFalse);
    });
  });

  group('a skill change', () {
    const baseline = '---\nname: lint\n---\n\nRun the linter.';
    const candidate = '---\nname: lint\n---\n\nRun the linter with --fix.';

    ImprovementProposal skillEdit(_Kit kit) {
      kit.files.skills['$_ws/lint'] = baseline;
      return kit.add(
        kind: ImprovementKind.skillEdit,
        scopeRefId: 'lint',
        operation: ImprovementOperation.replace,
        targetRef: 'Run the linter.',
        change: 'Run the linter with --fix.',
      );
    }

    const chosen = {
      'corpus_id': 'corpus-1',
      'provider_id': 'openrouter',
      'model_id': 'vendor/model',
      'repetitions': 2,
      'budget_micros': 500000,
    };

    Future<ImprovementProposal> start(_Kit kit, ImprovementProposal p) =>
        kit.service.startCampaign(
          p,
          actor: const UserPrincipal('user-1'),
          settings: chosen,
        );

    group('after review 6b', () {
      ({List<RepoOp> ops, List<WatchQuery> watches}) pack(_Kit kit) =>
          buildImprovementOps(
            proposals: kit.proposals,
            adoption: kit.service,
            requireSpace: (_, _, _) async {},
          );

      RepoOpContext opCtx(Map<String, dynamic> args) => RepoOpContext(
        args: args,
        workspaceId: _ws,
        deviceId: 'device-1',
        userId: 'user-1',
        role: WorkspaceRole.admin,
      );

      Future<Map<String, dynamic>> read(_Kit kit) async {
        final out =
            await pack(kit).ops
                    .singleWhere((o) => o.name == 'improvements.get')
                    .handler(opCtx({'proposal_id': 'p-1'}))
                as Map;
        return (out['proposal'] as Map).cast<String, dynamic>();
      }

      test('a campaign that ended is read as passed with its numbers, '
          'with no sweep', () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.finish(
          SkillEvaluationCampaignStatus.completed,
          _passing,
        );
        final p = await read(kit);
        expect(p['campaign_state'], 'passed');
        expect(p['evaluation'], isA<Map<String, dynamic>>());
        expect(
          kit.proposals.byId['p-1']!.campaignState,
          ImprovementCampaignState.passed,
        );
      });

      test(
        'the watch moves from running to passed when the campaign ends',
        () async {
          final kit = _Kit();
          await start(kit, skillEdit(kit));
          final frames = <Map<String, dynamic>>[];
          final sub = pack(kit).watches.single
              .handler(
                const WatchQueryContext(
                  args: {},
                  workspaceId: _ws,
                  deviceId: 'device-1',
                  userId: 'user-1',
                ),
              )
              .listen(
                (f) => frames.add(
                  ((f['proposals'] as List).single as Map)
                      .cast<String, dynamic>(),
                ),
              );
          await pumpEventQueue();
          expect(frames.last['campaign_state'], 'running');
          expect(frames.last.containsKey('evaluation'), isFalse);
          final seen = frames.length;
          kit.evaluation.finish(
            SkillEvaluationCampaignStatus.completed,
            _passing,
          );
          await pumpEventQueue();
          expect(frames.length, greaterThan(seen));
          expect(frames.last['campaign_state'], 'passed');
          expect(frames.last['evaluation'], isA<Map<String, dynamic>>());
          await sub.cancel();
        },
      );

      test('a failed campaign drops its stage, a new start goes at once, and '
          'the staging shows none of the old numbers', () async {
        final kit = _Kit();
        final staged = await start(kit, skillEdit(kit));
        kit.evaluation.finish(
          SkillEvaluationCampaignStatus.completed,
          _failing,
        );
        final failed = await read(kit);
        expect(failed['campaign_state'], 'failed');
        expect(failed['evaluation'], isA<Map<String, dynamic>>());
        expect(kit.evaluation.snapshots.discarded, [
          staged.candidateRevisionId,
        ]);
        Map<String, dynamic>? during;
        kit.evaluation.onLaunch = () async => during = await read(kit);
        final again = await start(kit, kit.proposals.byId['p-1']!);
        expect(again.campaignState, ImprovementCampaignState.running);
        expect(again.campaignId, 'camp-2');
        expect(during!['campaign_state'], 'staging');
        expect(during!.containsKey('campaign_id'), isFalse);
        expect(during!.containsKey('evaluation'), isFalse);
      });

      test('two accepts of one skill at once: one is applied, the other '
          'must be measured again', () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        await start(
          kit,
          kit.add(
            id: 'p-2',
            kind: ImprovementKind.skillEdit,
            scopeRefId: 'lint',
            operation: ImprovementOperation.add,
            targetRef: null,
            change: 'Read the lint config first.',
          ),
        );
        for (final id in ['camp-1', 'camp-2']) {
          kit.evaluation.finish(
            SkillEvaluationCampaignStatus.completed,
            _passing,
            id: id,
          );
        }
        Future<Object> accept(String id) => kit.service
            .accept(kit.proposals.byId[id]!, userId: 'user-1')
            .then<Object>((p) => p, onError: (Object e) => e);
        final results = await Future.wait([accept('p-1'), accept('p-2')]);
        final applied = results.whereType<ImprovementProposal>().single;
        expect(
          results.whereType<ImprovementRefusedException>().single.code,
          ImprovementRefusedException.campaignRequiredKind,
        );
        expect(kit.files.skills['$_ws/lint'], applied.afterText);
        expect(
          kit.proposals.byId.values.where(
            (p) => p.status == ImprovementStatus.accepted,
          ),
          hasLength(1),
        );
      });

      test('a skill another writer changed around the accept is not '
          'recorded as applied', () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.finish(
          SkillEvaluationCampaignStatus.completed,
          _passing,
        );
        kit.files.afterWrite = () =>
            kit.files.skills['$_ws/lint'] = 'Someone rewrote it.';
        await expectLater(
          kit.service.accept(kit.proposals.byId['p-1']!, userId: 'user-1'),
          _refused(ImprovementRefusedException.changedSinceKind),
        );
        final p = kit.proposals.byId['p-1']!;
        expect(p.status, ImprovementStatus.rolledBack);
        expect(p.appliedRef, isNull);
        expect(kit.files.skills['$_ws/lint'], 'Someone rewrote it.');
      });

      test('a member cannot cancel an improvement campaign through evals; '
          'an admin can, and a campaign no proposal owns is the member '
          "evaluation's", () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.repository.campaigns['camp-x'] = kit.evaluation.campaign(
          kit.evaluation.launched.single,
          SkillEvaluationCampaignStatus.running,
          id: 'camp-x',
        );
        final cancel = buildSkillEvaluationOps(
          kit.evaluation,
          guardCancel: kit.service.guardCampaignCancel,
        ).singleWhere((o) => o.name == 'evals.cancelCampaign');
        RepoOpContext as(WorkspaceRole role, String id) => RepoOpContext(
          args: {'workspace_id': _ws, 'campaign_id': id},
          workspaceId: _ws,
          deviceId: 'device-1',
          userId: 'user-1',
          role: role,
        );
        await expectLater(
          cancel.handler(as(WorkspaceRole.member, 'camp-1')),
          _refused(ImprovementRefusedException.adminRequiredKind),
        );
        expect(kit.evaluation.cancelledByPerson, isEmpty);
        await cancel.handler(as(WorkspaceRole.member, 'camp-x'));
        await cancel.handler(as(WorkspaceRole.admin, 'camp-1'));
        expect(kit.evaluation.cancelledByPerson, ['camp-x', 'camp-1']);
      });

      test(
        'a reject cancels as the server, after the starter lost access',
        () async {
          final kit = _Kit();
          await start(kit, skillEdit(kit));
          kit.evaluation.removedActors.add('user-1');
          final rejected = await kit.service.reject(
            kit.proposals.byId['p-1']!,
            userId: 'admin-2',
          );
          expect(rejected.status, ImprovementStatus.rejected);
          expect(kit.evaluation.cancelled, ['camp-1']);
        },
      );

      test('a cancel that fails: reject, sweep and a failed start still let '
          'go of the stage and the claim', () async {
        // Reject.
        final kit = _Kit();
        final staged = await start(kit, skillEdit(kit));
        kit.evaluation.failCancel = StateError('evaluation down');
        final rejected = await kit.service.reject(
          kit.proposals.byId['p-1']!,
          userId: 'user-1',
        );
        expect(rejected.status, ImprovementStatus.rejected);
        expect(kit.evaluation.snapshots.discarded, [
          staged.candidateRevisionId,
        ]);

        // Sweep at day 30.
        final swept = _Kit();
        final sweptStage = await start(swept, skillEdit(swept));
        swept.evaluation.failCancel = StateError('evaluation down');
        swept.now = _t0.add(ImprovementProposal.lifetime);
        expect(await swept.service.sweep(_ws), 1);
        expect(swept.proposals.byId['p-1']!.status, ImprovementStatus.expired);
        expect(swept.evaluation.snapshots.discarded, [
          sweptStage.candidateRevisionId,
        ]);

        // A start that lost to a reject while launching.
        final lost = _Kit();
        final p = skillEdit(lost);
        lost.evaluation.onLaunch = () async {
          lost.evaluation.failCancel = StateError('evaluation down');
          await lost.proposals.decide(
            _ws,
            id: 'p-1',
            from: ImprovementStatus.proposed,
            to: ImprovementStatus.rejected,
            decidedByUserId: 'user-2',
            now: _t0,
          );
          return null;
        };
        await expectLater(
          start(lost, p),
          _refused(ImprovementRefusedException.alreadyDecidedKind),
        );
        final after = lost.proposals.byId['p-1']!;
        expect(after.campaignState, ImprovementCampaignState.none);
        expect(lost.evaluation.snapshots.discarded, [
          lost.evaluation.launched.single.candidateHash,
        ]);
      });

      test('a move while recovery runs is refused in time, and nothing '
          'starts later', () async {
        final kit = _Kit(
          recovered: false,
          recoveryWait: const Duration(milliseconds: 50),
        );
        final p = skillEdit(kit);
        final watch = Stopwatch()..start();
        await expectLater(start(kit, p), _refused(storageBusyKind));
        expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
        kit.service.markRecovered();
        await pumpEventQueue();
        expect(kit.evaluation.launched, isEmpty);
        expect(
          kit.proposals.byId['p-1']!.campaignState,
          ImprovementCampaignState.none,
        );
      });

      test("the harness error count is the change's runs that hit one", () {
        Map<String, dynamic> withOutcomes(List<String> regressions) => {
          ..._report(
            verdict: 'superior',
            candidateOnly: 3,
            baselineOnly: 0,
            regressions: regressions,
          ),
          'taskOutcomes': [
            {'taskId': 't-0', 'armId': 'candidate', 'harnessErrors': 3},
            {'taskId': 't-0', 'armId': 'baseline', 'harnessErrors': 1},
            {'taskId': 't-1', 'armId': 'candidate', 'harnessErrors': 2},
            {'taskId': 't-1', 'armId': 'baseline', 'harnessErrors': 2},
          ],
        };
        final regressed = ImprovementEvaluation.fromReport(
          withOutcomes(['harness_error']),
        )!;
        expect((regressed.toWire()['regressions'] as Map)['harness_error'], 5);
        expect(regressed.passes, isFalse);
        // No per-task harness regression: the runs are shown, and it passes.
        final even = ImprovementEvaluation.fromReport(withOutcomes([]))!;
        expect((even.toWire()['regressions'] as Map)['harness_error'], 5);
        expect(even.passes, isTrue);
      });
    });

    test('cannot be accepted before a passing campaign', () async {
      final kit = _Kit();
      await expectLater(
        kit.service.accept(skillEdit(kit), userId: 'user-1'),
        _refused(ImprovementRefusedException.campaignRequiredKind),
      );
    });

    test('is staged, measured against the live revision, and written only '
        'on accept', () async {
      final kit = _Kit();
      final staged = await start(kit, skillEdit(kit));
      final launched = kit.evaluation.launched.single;
      expect(launched.skillSlug, 'lint');
      expect(launched.comparison, SkillEvaluationComparison.previous);
      expect(launched.budgetMicros, 500000);
      final stagedHash = launched.candidateHash!;
      expect(launched.baselineHash, isNot(stagedHash));
      expect(
        utf8.decode(
          kit
              .evaluation
              .snapshots
              .byHash[stagedHash]!
              .package
              .files['SKILL.md']!,
        ),
        candidate,
      );
      expect(staged.campaignState, ImprovementCampaignState.running);
      expect(staged.candidateRevisionId, stagedHash);
      // During the campaign the live skill is the baseline, byte for byte.
      expect(kit.evaluation.liveAtLaunch, baseline);
      expect(kit.files.skills['$_ws/lint'], baseline);
      await expectLater(
        kit.service.accept(staged, userId: 'user-1'),
        _refused(ImprovementRefusedException.campaignRequiredKind),
      );
      expect(kit.files.skills['$_ws/lint'], baseline);
      kit.evaluation.finish(SkillEvaluationCampaignStatus.completed, _passing);
      final accepted = await kit.service.accept(
        kit.proposals.byId['p-1']!,
        userId: 'user-1',
      );
      expect(accepted.status, ImprovementStatus.accepted);
      expect(accepted.campaignState, ImprovementCampaignState.passed);
      expect(accepted.beforeText, baseline);
      expect(accepted.afterText, candidate);
      expect(accepted.appliedRef, 'skill:lint@$stagedHash');
      expect(kit.files.skills['$_ws/lint'], candidate);
    });

    test('accept on a skill that moved since it was measured: failed, the '
        'stage dropped, and it can be measured again', () async {
      final kit = _Kit();
      final staged = await start(kit, skillEdit(kit));
      kit.evaluation.finish(SkillEvaluationCampaignStatus.completed, _passing);
      kit.files.skills['$_ws/lint'] = '$baseline\nRun the linter.';
      await expectLater(
        kit.service.accept(kit.proposals.byId['p-1']!, userId: 'user-1'),
        _refused(ImprovementRefusedException.campaignRequiredKind),
      );
      final p = kit.proposals.byId['p-1']!;
      expect(p.status, ImprovementStatus.proposed);
      expect(p.campaignState, ImprovementCampaignState.failed);
      expect(p.candidateRevisionId, isNull);
      expect(kit.evaluation.snapshots.discarded, [staged.candidateRevisionId]);
      expect(kit.files.skills['$_ws/lint'], '$baseline\nRun the linter.');
      final again = await start(kit, p);
      expect(again.campaignState, ImprovementCampaignState.running);
      expect(kit.evaluation.launched, hasLength(2));
    });

    test('two proposals for one skill both pass; once one is accepted the '
        'other is measured again', () async {
      final kit = _Kit();
      final p1 = skillEdit(kit);
      final p2 = kit.add(
        id: 'p-2',
        kind: ImprovementKind.skillEdit,
        scopeRefId: 'lint',
        operation: ImprovementOperation.add,
        targetRef: null,
        change: 'Read the lint config first.',
      );
      await start(kit, p1);
      await start(kit, p2);
      kit.evaluation.finish(SkillEvaluationCampaignStatus.completed, _passing);
      kit.evaluation.finish(
        SkillEvaluationCampaignStatus.completed,
        _passing,
        id: 'camp-2',
      );
      await kit.service.accept(kit.proposals.byId['p-1']!, userId: 'user-1');
      await expectLater(
        kit.service.accept(kit.proposals.byId['p-2']!, userId: 'user-1'),
        _refused(ImprovementRefusedException.campaignRequiredKind),
      );
      final measuredAgain = await start(kit, kit.proposals.byId['p-2']!);
      expect(measuredAgain.campaignState, ImprovementCampaignState.running);
      // Measured against what is live now: p-1's change.
      expect(
        kit.evaluation.launched.last.baselineHash,
        isNot(kit.evaluation.launched.first.baselineHash),
      );
    });

    test('a campaign that does not recommend it drops the stage; the skill '
        'was never touched', () async {
      final kit = _Kit();
      final staged = await start(kit, skillEdit(kit));
      kit.evaluation.finish(SkillEvaluationCampaignStatus.completed, _failing);
      await kit.service.sweep(_ws);
      final p = kit.proposals.byId['p-1']!;
      expect(p.campaignState, ImprovementCampaignState.failed);
      expect(p.candidateRevisionId, isNull);
      expect(kit.evaluation.snapshots.discarded, [staged.candidateRevisionId]);
      expect(kit.files.skills['$_ws/lint'], baseline);
    });

    test('rejecting cancels the campaign and drops the stage', () async {
      final kit = _Kit();
      final staged = await start(kit, skillEdit(kit));
      await kit.service.reject(staged, userId: 'user-1');
      expect(kit.evaluation.cancelled, ['camp-1']);
      expect(kit.evaluation.snapshots.discarded, [staged.candidateRevisionId]);
      expect(kit.files.skills['$_ws/lint'], baseline);
    });

    test('bad settings refuse before anything is staged and release the '
        'claim', () async {
      final kit2 = _Kit();
      await expectLater(
        kit2.service.startCampaign(
          skillEdit(kit2),
          actor: const UserPrincipal('user-1'),
          settings: const {'corpus_id': 'corpus-1'},
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(kit2.evaluation.launched, isEmpty);
      expect(kit2.evaluation.snapshots.byHash, isEmpty);
      expect(
        kit2.proposals.byId['p-1']!.campaignState,
        ImprovementCampaignState.none,
      );
      expect(kit2.files.skills['$_ws/lint'], baseline);
    });

    test('two starts at once launch one campaign', () async {
      final kit = _Kit();
      final p = skillEdit(kit);
      final results = await Future.wait([
        start(kit, p).then<Object>((v) => v, onError: (Object e) => e),
        start(kit, p).then<Object>((v) => v, onError: (Object e) => e),
      ]);
      expect(kit.evaluation.launched, hasLength(1));
      expect(results.whereType<ImprovementProposal>(), hasLength(1));
      expect(
        results.whereType<ImprovementRefusedException>().single.code,
        ImprovementRefusedException.campaignStateKind,
      );
    });

    for (final passed in [false, true]) {
      test('swept at day 30 with a ${passed ? 'passed' : 'running'} '
          'campaign: the baseline text, no stage, no campaign left '
          'running', () async {
        final kit = _Kit();
        final staged = await start(kit, skillEdit(kit));
        if (passed) {
          kit.evaluation.finish(
            SkillEvaluationCampaignStatus.completed,
            _passing,
          );
        }
        kit.now = _t0.add(const Duration(days: 30));
        expect(await kit.service.sweep(_ws), 1);
        final p = kit.proposals.byId['p-1']!;
        expect(p.status, ImprovementStatus.expired);
        expect(kit.files.skills['$_ws/lint'], baseline);
        expect(
          kit.evaluation.snapshots.byHash,
          isNot(contains(staged.candidateRevisionId)),
        );
        expect(
          kit.evaluation.repository.campaigns['camp-1']!.status,
          passed
              ? SkillEvaluationCampaignStatus.completed
              : SkillEvaluationCampaignStatus.cancelled,
        );
        expect(kit.evaluation.cancelled, passed ? isEmpty : ['camp-1']);
      });
    }

    test(
      'a cleanup that fails keeps the row proposed for the next sweep',
      () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.snapshots.failDiscard = true;
        kit.now = _t0.add(const Duration(days: 30));
        expect(await kit.service.sweep(_ws), 0);
        expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.proposed);
        kit.evaluation.snapshots.failDiscard = false;
        expect(await kit.service.sweep(_ws), 1);
      },
    );

    group('passes when', () {
      ImprovementCampaignState outcome(Map<String, dynamic> report) {
        final kit = _Kit();
        final settings = SkillEvaluationSettings.fromJson({
          ...chosen,
          'skill_slug': 'lint',
          'comparison': SkillEvaluationComparison.previous.wire,
          'baseline_hash': '0' * 64,
        });
        return ImprovementAdoptionService.campaignOutcome(
          kit.evaluation.campaign(
            settings,
            SkillEvaluationCampaignStatus.completed,
            report: report,
          ),
        );
      }

      test('equal results pass, inconclusive or not', () {
        expect(outcome(_report()), ImprovementCampaignState.passed);
        expect(
          outcome(_report(verdict: 'non_inferior')),
          ImprovementCampaignState.passed,
        );
      });

      test('a superior screen passes', () {
        expect(outcome(_passing), ImprovementCampaignState.passed);
      });

      test('the observed task-mean difference decides, not the pair '
          'counts', () {
        // More baseline-only pairs, but the per-task means favour the change
        // (the pairs fall on tasks with different repetition counts).
        expect(
          outcome(_report(candidateOnly: 1, baselineOnly: 2, delta: 0.05)),
          ImprovementCampaignState.passed,
        );
        // Even pair counts, a loss in the task means.
        expect(outcome(_report(delta: -0.05)), ImprovementCampaignState.failed);
      });

      test('a per-task quality loss or cost regression alone does not fail '
          'it', () {
        expect(
          outcome(_report(regressions: ['quality_loss', 'cost_regression'])),
          ImprovementCampaignState.passed,
        );
      });

      for (final (label, report) in [
        ('a negative observed difference', _failing),
        ('no usable task block', _report(tasks: 0)),
        ('a verdict without an observed difference', _report(omitDelta: true)),
        ('an inferior verdict', _report(verdict: 'inferior')),
        ('a harness error regression', _report(regressions: ['harness_error'])),
        ('incomplete coverage', _report(coverage: false)),
        ('a plan violation', _report(planViolations: ['arm order'])),
        ('no paired verdict', <String, dynamic>{'coverageComplete': true}),
      ]) {
        test('$label fails', () {
          expect(outcome(report), ImprovementCampaignState.failed);
        });
      }

      test('the proposal carries the numbers a person judges it by', () async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.finish(
          SkillEvaluationCampaignStatus.completed,
          _report(
            candidateOnly: 2,
            baselineOnly: 1,
            bothPass: 3,
            regressions: ['quality_loss'],
          ),
        );
        final p = await kit.service.refreshCampaign(kit.proposals.byId['p-1']!);
        expect(p.campaignState, ImprovementCampaignState.passed);
        final evaluation = (await kit.service.evaluationOf(p))!.toWire();
        expect(evaluation, {
          'paired_runs': 8,
          'candidate_solved': 5,
          'baseline_solved': 4,
          'verdict': 'inconclusive',
          'regressions': {
            'quality_loss': 1,
            'cost_regression': 0,
            'harness_error': 0,
          },
          'coverage_complete': true,
          'plan_violations': 0,
        });
      });
    });

    test('a reject while a start is in flight leaves no campaign running and '
        'no stage behind', () async {
      final kit = _Kit();
      final p = skillEdit(kit);
      // The start claims staging, then the reject's claim lands before its
      // own final write.
      kit.evaluation.onLaunch = () =>
          kit.service.reject(kit.proposals.byId['p-1']!, userId: 'user-2');
      await expectLater(
        start(kit, p),
        _refused(ImprovementRefusedException.alreadyDecidedKind),
      );
      final rejected = kit.proposals.byId['p-1']!;
      expect(rejected.status, ImprovementStatus.rejected);
      expect(rejected.campaignState, ImprovementCampaignState.none);
      expect(rejected.candidateRevisionId, isNull);
      expect(kit.evaluation.cancelled, ['camp-1']);
      expect(kit.evaluation.snapshots.discarded, [
        kit.evaluation.launched.single.candidateHash,
      ]);
    });

    test('a reject that reads the row before a start launched still cancels '
        'and drops what the start wrote', () async {
      final kit = _Kit();
      final stale = skillEdit(kit);
      await start(kit, stale);
      await kit.service.reject(stale, userId: 'user-2');
      expect(kit.evaluation.cancelled, ['camp-1']);
      expect(kit.evaluation.snapshots.discarded, [
        kit.evaluation.launched.single.candidateHash,
      ]);
    });

    test('a stage another proposal or campaign refers to is kept', () async {
      final kit = _Kit();
      final p1 = skillEdit(kit);
      final p2 = kit.add(
        id: 'p-2',
        kind: ImprovementKind.skillEdit,
        scopeRefId: 'lint',
        operation: ImprovementOperation.replace,
        targetRef: 'Run the linter.',
        change: 'Run the linter with --fix.',
      );
      final s1 = await start(kit, p1);
      final s2 = await start(kit, p2);
      expect(s1.candidateRevisionId, s2.candidateRevisionId);
      await kit.service.reject(s1, userId: 'user-1');
      expect(kit.evaluation.snapshots.discarded, isEmpty);
      expect(kit.evaluation.snapshots.byHash, contains(s2.candidateRevisionId));
      // A candidate that is another campaign's baseline is kept too.
      final baselineHash = kit.evaluation.launched.first.baselineHash!;
      kit.files.skills['$_ws/lint'] = candidate;
      final p3 = kit.add(
        id: 'p-3',
        kind: ImprovementKind.skillEdit,
        scopeRefId: 'lint',
        operation: ImprovementOperation.replace,
        targetRef: 'Run the linter with --fix.',
        change: 'Run the linter.',
      );
      final s3 = await start(kit, p3);
      expect(s3.candidateRevisionId, baselineHash);
      await kit.service.reject(s3, userId: 'user-1');
      expect(kit.evaluation.snapshots.byHash, contains(baselineHash));
    });

    test('a proposal past its expiry the sweep has not reached starts no '
        'campaign and is not accepted', () async {
      final kit = _Kit();
      final p = skillEdit(kit);
      final fact = kit.add(id: 'p-fact');
      kit.now = p.expiresAt;
      await expectLater(
        start(kit, p),
        _refused(ImprovementRefusedException.alreadyDecidedKind),
      );
      expect(kit.evaluation.launched, isEmpty);
      await expectLater(
        kit.service.accept(fact, userId: 'user-1'),
        _refused(ImprovementRefusedException.alreadyDecidedKind),
      );
    });

    test('no move runs before boot recovery', () async {
      final kit = _Kit(recovered: false);
      final p = skillEdit(kit);
      await kit.proposals.setCampaign(
        _ws,
        id: 'p-1',
        from: const {ImprovementCampaignState.none},
        campaignId: null,
        state: ImprovementCampaignState.staging,
        candidateRevisionId: null,
      );
      var started = false;
      final pending = start(kit, p).then((_) => started = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(started, isFalse);
      expect(kit.evaluation.launched, isEmpty);
      await kit.service.recover(_ws);
      kit.service.markRecovered();
      await pending;
      expect(kit.evaluation.launched, hasLength(1));
    });

    group('recovery at boot', () {
      Future<_Kit> acceptedWithoutMark() async {
        final kit = _Kit();
        await start(kit, skillEdit(kit));
        kit.evaluation.finish(
          SkillEvaluationCampaignStatus.completed,
          _passing,
        );
        await kit.service.refreshCampaign(kit.proposals.byId['p-1']!);
        // The server died after the claim, before the file was written.
        await kit.proposals.decide(
          _ws,
          id: 'p-1',
          from: ImprovementStatus.proposed,
          to: ImprovementStatus.accepted,
          decidedByUserId: 'user-1',
          beforeText: baseline,
          afterText: candidate,
          now: _t0,
        );
        return kit;
      }

      test('re-applies while the skill is still the baseline', () async {
        final kit = await acceptedWithoutMark();
        expect(await kit.service.recover(_ws), isEmpty);
        expect(kit.files.skills['$_ws/lint'], candidate);
        expect(
          kit.proposals.byId['p-1']!.appliedRef,
          startsWith('skill:lint@'),
        );
      });

      test('rolls back and reports one whose skill changed since', () async {
        final kit = await acceptedWithoutMark();
        kit.files.skills['$_ws/lint'] = 'Someone rewrote it.';
        final incomplete = await kit.service.recover(_ws);
        expect(incomplete.single.id, 'p-1');
        expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.rolledBack);
        expect(kit.files.skills['$_ws/lint'], 'Someone rewrote it.');
      });

      test('releases a start a crash left staging', () async {
        final kit = _Kit();
        skillEdit(kit);
        await kit.proposals.setCampaign(
          _ws,
          id: 'p-1',
          from: const {ImprovementCampaignState.none},
          campaignId: null,
          state: ImprovementCampaignState.staging,
          candidateRevisionId: null,
        );
        await kit.service.recover(_ws);
        expect(
          kit.proposals.byId['p-1']!.campaignState,
          ImprovementCampaignState.none,
        );
      });
    });
  });

  test('expiry after 30 days', () async {
    final kit = _Kit();
    kit.add();
    kit.now = _t0.add(const Duration(days: 29));
    expect(await kit.service.sweep(_ws), 0);
    kit.now = _t0.add(const Duration(days: 30));
    expect(await kit.service.sweep(_ws), 1);
    expect(kit.proposals.byId['p-1']!.status, ImprovementStatus.expired);
  });

  group('the improvements ops', () {
    late _Kit kit;
    late List<RepoOp> ops;
    late List<WatchQuery> watches;
    late Set<String> unreadable;

    setUp(() {
      kit = _Kit();
      unreadable = {};
      final pack = buildImprovementOps(
        proposals: kit.proposals,
        adoption: kit.service,
        requireSpace: (ws, user, space) async {
          if (unreadable.contains(space)) {
            throw const ValidationException('space_access_denied');
          }
        },
      );
      ops = pack.ops;
      watches = pack.watches;
    });

    RepoOp op(String name) => ops.singleWhere((o) => o.name == name);

    RepoOpContext ctx(
      Map<String, dynamic> args, {
      String ws = _ws,
      WorkspaceRole role = WorkspaceRole.member,
    }) => RepoOpContext(
      args: args,
      workspaceId: ws,
      deviceId: 'device-1',
      userId: 'user-1',
      role: role,
    );

    test('the pack and its kinds', () {
      expect(ops.map((o) => o.name), [
        'improvements.get',
        'improvements.accept',
        'improvements.reject',
        'improvements.rollback',
        'improvements.startCampaign',
      ]);
      expect(op('improvements.get').kind, RepoOpKind.read);
      expect(watches.single.name, 'improvements.watchForWorkspace');
    });

    test('every op refuses a proposal of another workspace', () async {
      kit.add(id: 'p-x', workspaceId: _other);
      for (final o in ops) {
        await expectLater(
          o.handler(
            ctx({
              'proposal_id': 'p-x',
              'corpus_id': 'c',
              'provider_id': 'p',
              'model_id': 'm',
              'repetitions': 1,
              'budget_micros': 1,
            }),
          ),
          throwsA(isA<WorkspaceMismatchException>()),
          reason: o.name,
        );
      }
      expect(kit.proposals.byId['p-x']!.status, ImprovementStatus.proposed);
    });

    test('a proposal in a space the caller cannot read is refused', () async {
      kit.add(spaceId: 'space-secret');
      unreadable.add('space-secret');
      await expectLater(
        op('improvements.accept').handler(ctx({'proposal_id': 'p-1'})),
        throwsA(isA<ValidationException>()),
      );
      expect(kit.facts.byId, isEmpty);
    });

    test('a workspace policy and a skill need an admin', () async {
      kit
        ..add(id: 'pol', kind: ImprovementKind.policy)
        ..add(
          id: 'repo-pol',
          kind: ImprovementKind.policy,
          scope: ImprovementScope.repository,
          scopeRefId: 'repo-1',
        )
        ..add(
          id: 'skill',
          kind: ImprovementKind.skillNew,
          scopeRefId: 'lint-fix',
          targetRef: null,
        );
      for (final id in ['pol', 'skill']) {
        await expectLater(
          op('improvements.accept').handler(ctx({'proposal_id': id})),
          _refused(ImprovementRefusedException.adminRequiredKind),
        );
      }
      await expectLater(
        op('improvements.startCampaign').handler(ctx({'proposal_id': 'skill'})),
        _refused(ImprovementRefusedException.adminRequiredKind),
      );
      expect(
        ImprovementAdoptionService.needsAdmin(kit.proposals.byId['repo-pol']!),
        isFalse,
      );
      final out =
          await op(
                'improvements.accept',
              ).handler(ctx({'proposal_id': 'pol'}, role: WorkspaceRole.admin))
              as Map;
      expect((out['proposal'] as Map)['status'], 'accepted');
      expect((out['proposal'] as Map)['needs_admin'], isTrue);
    });

    test('the watch shows only readable proposals of the workspace', () async {
      kit
        ..add()
        ..add(id: 'p-secret', spaceId: 'space-secret')
        ..add(id: 'p-x', workspaceId: _other);
      unreadable.add('space-secret');
      final first = await watches.single
          .handler(
            const WatchQueryContext(
              args: {},
              workspaceId: _ws,
              deviceId: 'device-1',
              userId: 'user-1',
            ),
          )
          .first;
      expect(
        [for (final p in first['proposals'] as List) (p as Map)['id']],
        ['p-1'],
      );
    });
  });
}
