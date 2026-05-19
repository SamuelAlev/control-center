import 'package:cc_domain/features/fleet/domain/entities/job.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Coverage for the feature-domain enums, value objects and small entities
/// that had no dedicated test: parse/storage round-trips, ordering predicates,
/// equality/hashCode and copyWith field preservation.
void main() {
  group('ApprovalKind', () {
    test('fromStorage matches storage or name; defaults to custom', () {
      expect(ApprovalKind.fromStorage('plan_exit'), ApprovalKind.planExit);
      expect(ApprovalKind.fromStorage('merge'), ApprovalKind.merge);
      expect(ApprovalKind.fromStorage('custom'), ApprovalKind.custom);
      // name also accepted
      expect(ApprovalKind.fromStorage('release'), ApprovalKind.release);
      expect(ApprovalKind.fromStorage(null), ApprovalKind.custom);
      expect(ApprovalKind.fromStorage('bogus'), ApprovalKind.custom);
    });
  });

  group('ApprovalStatus', () {
    test('storage round-trip + defaults', () {
      for (final s in ApprovalStatus.values) {
        expect(ApprovalStatus.fromStorage(s.storage), s);
      }
      expect(ApprovalStatus.fromStorage(null), ApprovalStatus.pending);
      expect(ApprovalStatus.fromStorage('bogus'), ApprovalStatus.pending);
      // camelCase for revisionRequested
      expect(
        ApprovalStatus.fromStorage('revisionRequested'),
        ApprovalStatus.revisionRequested,
      );
    });

    test('predicates', () {
      expect(ApprovalStatus.approved.isTerminal, isTrue);
      expect(ApprovalStatus.rejected.isTerminal, isTrue);
      expect(ApprovalStatus.pending.isTerminal, isFalse);
      expect(ApprovalStatus.approved.isApproved, isTrue);
      expect(ApprovalStatus.pending.isApproved, isFalse);
    });

    test('ApprovalDecision resultingStatus + isValidFrom + tryParse', () {
      expect(ApprovalDecision.approve.resultingStatus, ApprovalStatus.approved);
      expect(ApprovalDecision.reject.resultingStatus, ApprovalStatus.rejected);
      expect(
        ApprovalDecision.requestRevision.resultingStatus,
        ApprovalStatus.revisionRequested,
      );
      expect(ApprovalDecision.resubmit.resultingStatus, ApprovalStatus.pending);

      expect(
        ApprovalDecision.approve.isValidFrom(ApprovalStatus.pending),
        isTrue,
      );
      expect(
        ApprovalDecision.approve.isValidFrom(ApprovalStatus.approved),
        isFalse,
      );
      expect(
        ApprovalDecision.resubmit.isValidFrom(ApprovalStatus.revisionRequested),
        isTrue,
      );
      expect(
        ApprovalDecision.resubmit.isValidFrom(ApprovalStatus.pending),
        isFalse,
      );

      expect(ApprovalDecision.tryParse('Approve'), ApprovalDecision.approve);
      expect(ApprovalDecision.tryParse(null), isNull);
      expect(ApprovalDecision.tryParse('bogus'), isNull);
    });
  });

  group('ApprovalRoutingPolicy', () {
    test('ApprovalRoutingMode fromWire + wireName', () {
      for (final m in ApprovalRoutingMode.values) {
        expect(ApprovalRoutingMode.fromWire(m.wireName), m);
      }
      expect(ApprovalRoutingMode.fromWire(null), isNull);
      expect(ApprovalRoutingMode.fromWire('bogus'), isNull);
    });

    test('fromJson / toJson round-trip + defaults', () {
      const p = ApprovalRoutingPolicy(
        mode: ApprovalRoutingMode.owner,
        escalationTimeout: Duration(minutes: 30),
      );
      final rebuilt = ApprovalRoutingPolicy.fromJson(p.toJson());
      expect(rebuilt, p);
      expect(
        ApprovalRoutingPolicy.defaults.mode,
        ApprovalRoutingMode.requestingUser,
      );
      expect(
        ApprovalRoutingPolicy.defaults.escalationTimeout,
        const Duration(hours: 1),
      );
    });

    test('fromJson falls back on malformed', () {
      final p = ApprovalRoutingPolicy.fromJson({});
      expect(p.mode, ApprovalRoutingMode.requestingUser);
      expect(p.escalationTimeout, const Duration(minutes: 60));
    });

    test('equality + hashCode', () {
      const a = ApprovalRoutingPolicy();
      const b = ApprovalRoutingPolicy();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == const ApprovalRoutingPolicy(mode: ApprovalRoutingMode.owner),
        isFalse,
      );
    });
  });

  group('ActionClass / ActionDecision / ActionScopeType', () {
    test('ActionClass.fromWire', () {
      expect(ActionClass.fromWire('gitCommit'), ActionClass.gitCommit);
      expect(ActionClass.fromWire('bogus'), isNull);
    });

    test(
      'ActionDecision.fromWire defaults to prompt; ordering + mostRestrictive',
      () {
        expect(ActionDecision.fromWire('allow'), ActionDecision.allow);
        expect(ActionDecision.fromWire('deny'), ActionDecision.deny);
        expect(ActionDecision.fromWire('bogus'), ActionDecision.prompt);
        expect(
          ActionDecision.deny.isMoreRestrictiveThan(ActionDecision.allow),
          isTrue,
        );
        expect(
          ActionDecision.allow.isMoreRestrictiveThan(ActionDecision.deny),
          isFalse,
        );
        expect(
          ActionDecision.mostRestrictive(
            ActionDecision.allow,
            ActionDecision.deny,
          ),
          ActionDecision.deny,
        );
        expect(
          ActionDecision.mostRestrictive(
            ActionDecision.prompt,
            ActionDecision.allow,
          ),
          ActionDecision.prompt,
        );
      },
    );

    test('ActionScopeType.fromWire defaults to workspace', () {
      expect(ActionScopeType.fromWire('agent'), ActionScopeType.agent);
      expect(ActionScopeType.fromWire('channel'), ActionScopeType.channel);
      expect(ActionScopeType.fromWire('bogus'), ActionScopeType.workspace);
    });

    test('ActionPolicyRule provenanceLabel + equality', () {
      final remembered = ActionPolicyRule(
        id: 'r',
        workspaceId: 'w',
        scopeType: ActionScopeType.agent,
        scopeId: 'a',
        decision: ActionDecision.allow,
        commandPrefix: 'git',
        provenance: 'remembered',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(remembered.provenanceLabel, 'remembered');
      final userRule = ActionPolicyRule(
        id: 'r2',
        workspaceId: 'w',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        decision: ActionDecision.prompt,
        actionClass: ActionClass.gitCommit,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(userRule.provenanceLabel, 'workspace rule');
      // equality is id-based
      expect(
        remembered ==
            ActionPolicyRule(
              id: 'r',
              workspaceId: 'w',
              scopeType: ActionScopeType.workspace,
              scopeId: '',
              decision: ActionDecision.deny,
              actionClass: ActionClass.gitCommit,
              createdAt: DateTime(2020, 1, 1),
              updatedAt: DateTime(2020, 1, 1),
            ),
        isTrue,
      );
      expect(remembered.hashCode, 'r'.hashCode);
    });
  });

  group('JobStatus', () {
    test('fromWire + predicates', () {
      expect(JobStatus.fromWire('running'), JobStatus.running);
      expect(JobStatus.fromWire('bogus'), JobStatus.queued);
      expect(JobStatus.done.isTerminal, isTrue);
      expect(JobStatus.cancelled.isTerminal, isTrue);
      expect(JobStatus.queued.isTerminal, isFalse);
      expect(JobStatus.running.isActive, isTrue);
      expect(JobStatus.leased.isActive, isTrue);
      expect(JobStatus.done.isActive, isFalse);
    });
  });

  group('WorkerStatus', () {
    test('fromWire defaults to offline; isSchedulable', () {
      expect(WorkerStatus.fromWire('online'), WorkerStatus.online);
      expect(WorkerStatus.fromWire('bogus'), WorkerStatus.offline);
      expect(WorkerStatus.online.isSchedulable, isTrue);
      expect(WorkerStatus.draining.isSchedulable, isFalse);
    });
  });

  group('PlacementCode / PlacementDecision', () {
    test('fromWire + isPlacement', () {
      expect(PlacementCode.fromWire('pinned'), PlacementCode.pinned);
      expect(
        PlacementCode.fromWire('no_capable_worker'),
        PlacementCode.noCapableWorker,
      );
      expect(PlacementCode.fromWire('bogus'), PlacementCode.queued);
      expect(PlacementCode.preferred.isPlacement, isTrue);
      expect(PlacementCode.queued.isPlacement, isFalse);
    });

    test('PlacementDecision.queued ctor + placed getter', () {
      const q = PlacementDecision.queued('no workers');
      expect(q.code, PlacementCode.queued);
      expect(q.workerId, isNull);
      expect(q.placed, isFalse);
      const p = PlacementDecision(
        code: PlacementCode.spill,
        reason: 'r',
        workerId: 'w1',
      );
      expect(p.placed, isTrue);
    });

    test('equality + hashCode + toString', () {
      const a = PlacementDecision(
        code: PlacementCode.pinned,
        reason: 'r',
        workerId: 'w',
      );
      const b = PlacementDecision(
        code: PlacementCode.pinned,
        reason: 'r',
        workerId: 'w',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('pinned'));
      expect(a.toString(), contains('w'));
    });
  });

  group('Job', () {
    final base = Job(
      id: 'j1',
      workspaceId: 'w',
      kind: JobKind.agentRun,
      spec: const AgentRunJobSpec(agentId: 'a'),
      status: JobStatus.queued,
      pinnedWorkerId: 'pw',
      workerId: 'w1',
      leaseExpiresAt: DateTime(2025, 1, 2),
      attempts: 1,
      maxAttempts: 3,
      costCents: 5,
      lastAckedSeq: 9,
      createdAt: DateTime(2025, 1, 1),
    );

    test('predicates: isPinned, leaseExpired, canRetry', () {
      expect(base.isPinned, isTrue);
      expect(base.leaseExpired(DateTime(2025, 1, 1)), isFalse);
      expect(base.leaseExpired(DateTime(2025, 1, 3)), isTrue);
      // no lease -> never expired
      final noLease = Job(
        id: 'j',
        workspaceId: 'w',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a'),
        status: JobStatus.queued,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(noLease.leaseExpired(DateTime(2030, 1, 1)), isFalse);
      expect(noLease.isPinned, isFalse);
      expect(base.canRetry, isTrue);
      final exhausted = Job(
        id: 'j',
        workspaceId: 'w',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a'),
        status: JobStatus.queued,
        attempts: 3,
        maxAttempts: 3,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(exhausted.canRetry, isFalse);
    });

    test('equality is based on the mutable subset', () {
      final same = Job(
        id: 'j1',
        workspaceId: 'diff', // not part of equality
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'other'),
        status: JobStatus.queued,
        workerId: 'w1',
        leaseExpiresAt: DateTime(2025, 1, 2),
        attempts: 1,
        costCents: 5,
        lastAckedSeq: 9,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      final diff = Job(
        id: 'j1',
        workspaceId: 'w',
        kind: JobKind.agentRun,
        spec: const AgentRunJobSpec(agentId: 'a'),
        status: JobStatus.running,
        attempts: 1,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(base == diff, isFalse);
    });
  });

  group('OrchestrationStatus', () {
    test('fromStorage + toStorageString + isTerminal', () {
      expect(
        OrchestrationStatus.fromStorage(null),
        OrchestrationStatus.proposed,
      );
      for (final s in OrchestrationStatus.values) {
        expect(OrchestrationStatus.fromStorage(s.toStorageString()), s);
      }
      expect(OrchestrationStatus.completed.isTerminal, isTrue);
      expect(OrchestrationStatus.failed.isTerminal, isTrue);
      expect(OrchestrationStatus.cancelled.isTerminal, isTrue);
      expect(OrchestrationStatus.proposed.isTerminal, isFalse);
      expect(
        () => OrchestrationStatus.fromStorage('bogus'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PipelineRunStatus', () {
    test('fromString + toStorageString + isTerminal', () {
      expect(
        PipelineRunStatus.fromString('running'),
        PipelineRunStatus.running,
      );
      expect(PipelineRunStatus.fromString('bogus'), PipelineRunStatus.pending);
      for (final s in PipelineRunStatus.values) {
        expect(PipelineRunStatus.fromString(s.toStorageString()), s);
      }
      expect(PipelineRunStatus.completed.isTerminal, isTrue);
      expect(PipelineRunStatus.suspended.isTerminal, isFalse);
    });
  });

  group('StepTrigger', () {
    test('fromJson + toJson round-trip', () {
      const t = StepTrigger(sourceStepIds: ['a', 'b'], routeKey: 'k');
      expect(StepTrigger.fromJson(t.toJson()), t);
      final out = t.toJson();
      expect(out['route_key'], 'k');
      const noRoute = StepTrigger(sourceStepIds: ['a']);
      expect(noRoute.toJson().containsKey('route_key'), isFalse);
    });

    test('fromJson tolerates malformed', () {
      final t = StepTrigger.fromJson({});
      expect(t.sourceStepIds, isEmpty);
      expect(t.routeKey, isNull);
      final t2 = StepTrigger.fromJson({
        'source_step_ids': [1, 'x'],
      });
      expect(t2.sourceStepIds, ['x']);
    });

    test('equality + hashCode', () {
      const a = StepTrigger(sourceStepIds: ['a'], routeKey: 'k');
      const b = StepTrigger(sourceStepIds: ['a'], routeKey: 'k');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const StepTrigger(sourceStepIds: ['a', 'b']), isFalse);
    });
  });

  group('PipelineRun', () {
    final start = DateTime(2025, 1, 1, 10);
    final resumed = DateTime(2025, 1, 1, 11);
    final now = DateTime(2025, 1, 1, 11, 30);

    test('state is unmodifiable', () {
      final run = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.pending,
        startedAt: start,
        state: {'k': 1},
      );
      expect(run.state, {'k': 1});
      expect(() => run.state['x'] = 1, throwsUnsupportedError);
    });

    test('activeDurationAt folds the live segment when running', () {
      final running = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: start,
        activeMs: 1000,
        lastResumedAt: resumed,
      );
      final d = running.activeDurationAt(now);
      expect(d.inMilliseconds, 1000 + now.difference(resumed).inMilliseconds);
      // non-running -> just activeMs
      final suspended = running.copyWith(status: PipelineRunStatus.suspended);
      expect(suspended.activeDurationAt(now).inMilliseconds, 1000);
    });

    test('activeDurationAt ignores negative live', () {
      final running = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: start,
        activeMs: 500,
        lastResumedAt: now.add(const Duration(hours: 1)),
      );
      expect(running.activeDurationAt(now).inMilliseconds, 500);
    });

    test('copyWith: lastResumedAt nullable-aware (keep / clear / set)', () {
      final running = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: start,
        lastResumedAt: resumed,
      );
      // keep
      expect(
        running.copyWith(status: PipelineRunStatus.suspended).lastResumedAt,
        resumed,
      );
      // clear (explicit null)
      expect(running.copyWith(lastResumedAt: null).lastResumedAt, isNull);
      // set
      final newTs = DateTime(2025, 2, 1);
      expect(running.copyWith(lastResumedAt: newTs).lastResumedAt, newTs);
    });

    test('copyWith preserves untouched fields', () {
      final run = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: start,
        totalCostCents: 5,
        totalTokens: 7,
        triggerEventType: 'evt',
        triggerPayload: {'p': 1},
        dedupKey: 'dk',
        errorMessage: 'em',
        errorStackTrace: 'est',
        parentPipelineRunId: 'ppr',
        parentStepId: 'psi',
        templateVersion: 3,
        dryRun: true,
      );
      final next = run.copyWith(status: PipelineRunStatus.completed);
      expect(next.totalCostCents, 5);
      expect(next.totalTokens, 7);
      expect(next.triggerEventType, 'evt');
      expect(next.dedupKey, 'dk');
      expect(next.templateVersion, 3);
      expect(next.dryRun, isTrue);
    });

    test('equality + hashCode', () {
      final a = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.pending,
        startedAt: start,
        activeMs: 1,
        errorMessage: 'e',
      );
      final b = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.pending,
        startedAt: DateTime(2030),
        activeMs: 1,
        errorMessage: 'e',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a ==
            PipelineRun(
              id: 'r',
              templateId: 't',
              workspaceId: 'w',
              status: PipelineRunStatus.running,
              startedAt: start,
            ),
        isFalse,
      );
    });

    test('isTerminal getter', () {
      final run = PipelineRun(
        id: 'r',
        templateId: 't',
        workspaceId: 'w',
        status: PipelineRunStatus.completed,
        startedAt: start,
      );
      expect(run.isTerminal, isTrue);
    });
  });

  group('Team', () {
    final t = Team(
      id: 't1',
      workspaceId: 'w',
      name: 'N',
      description: 'd',
      leaderId: 'l',
      instructions: 'in',
      createdAt: DateTime(2025, 1, 1),
    );

    test('hasLeader', () {
      expect(t.hasLeader, isTrue);
      expect(
        Team(
          id: 't',
          workspaceId: 'w',
          name: 'N',
          createdAt: DateTime(2025, 1, 1),
        ).hasLeader,
        isFalse,
      );
      expect(
        Team(
          id: 't',
          workspaceId: 'w',
          name: 'N',
          leaderId: '',
          createdAt: DateTime(2025, 1, 1),
        ).hasLeader,
        isFalse,
      );
    });

    test('copyWith overrides + clear flags', () {
      final renamed = t.copyWith(name: 'N2');
      expect(renamed.name, 'N2');
      expect(renamed.description, 'd');
      final cleared = t.copyWith(
        clearDescription: true,
        clearLeader: true,
        clearInstructions: true,
      );
      expect(cleared.description, isNull);
      expect(cleared.leaderId, isNull);
      expect(cleared.instructions, isNull);
      expect(cleared.name, 'N');
    });
  });
}
