import 'package:cc_domain/cc_domain.dart' show GoalAlreadyActiveException;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// Exercises [DaoAgentGoalRunRepository] end-to-end against an in-memory
/// database. Covers every repository method (getById, listByWorkspace,
/// listActive, getActiveForAgent, listHeld, upsert) through the domain
/// [AgentGoalRun]
/// entity and the goal-run mapper, including the persisted wire names for
/// every [AgentGoalStatus] and the workspace-isolation rules.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoAgentGoalRunRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoAgentGoalRunRepository(dbs);
    for (final ws in ['w-1', 'w-2']) {
      final db = dbs.of(ws);
      await seedParents(
        db,
        agents: ['agent-1', 'agent-2'],
        spaces: ['ch-1', 'w-1', 'w-2'],
      );
      await seedConversation(db, 'conv-1', spaceId: 'ch-1');
      await seedRunLog(db, 'run-9', agentId: 'agent-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  AgentGoalRun goal({
    String id = 'goal-1',
    String workspaceId = 'w-1',
    String spaceId = 'ch-1',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
    String userText = 'Ship the feature',
    AgentGoalStatus status = AgentGoalStatus.active,
    DateTime? deadlineAt,
    int costCapMicros = 5000,
    int costMicros = 0,
    int maxRuns = 100,
    bool uncapped = false,
    int runCount = 0,
    String? activeRunId,
    int consecutiveFailures = 0,
    String? requestedByUserId,
    String? summary,
    GoalContract? contract,
    GoalHold? hold,
    DateTime? holdUntil,
    String? holdDetail,
    int noProgressStreak = 0,
    int verificationRounds = 0,
    String? lastFingerprint,
    String? lastActivityDigest,
    int parkCount = 0,
    bool fresh = false,
    GoalUnattendedPolicy unattended = GoalUnattendedPolicy.wait,
    String? checkerAgentId,
    GoalVerification? verification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AgentGoalRun(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: agentId,
    userText: userText,
    status: status,
    deadlineAt: uncapped ? null : (deadlineAt ?? DateTime(2026, 8, 1)),
    costCapMicros: costCapMicros,
    costMicros: costMicros,
    maxRuns: uncapped ? null : maxRuns,
    runCount: runCount,
    activeRunId: activeRunId,
    consecutiveFailures: consecutiveFailures,
    requestedByUserId: requestedByUserId,
    summary: summary,
    contract: contract,
    hold: hold,
    holdUntil: holdUntil,
    holdDetail: holdDetail,
    noProgressStreak: noProgressStreak,
    verificationRounds: verificationRounds,
    lastFingerprint: lastFingerprint,
    lastActivityDigest: lastActivityDigest,
    parkCount: parkCount,
    fresh: fresh,
    unattended: unattended,
    checkerAgentId: checkerAgentId,
    verification: verification,
    createdAt: createdAt ?? DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026),
  );

  group('upsert + read round-trip', () {
    test('getById returns null when absent', () async {
      expect(await repo.getById('w-1', 'missing'), isNull);
    });

    test('upsert then getById round-trips every field', () async {
      await repo.upsert(
        goal(
          costMicros: 1250,
          runCount: 7,
          activeRunId: 'run-9',
          consecutiveFailures: 2,
          requestedByUserId: 'user-1',
          summary: 'halfway there',
        ),
      );
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'goal-1');
      expect(loaded.workspaceId, 'w-1');
      expect(loaded.spaceId, 'ch-1');
      expect(loaded.conversationId, 'conv-1');
      expect(loaded.agentId, 'agent-1');
      expect(loaded.userText, 'Ship the feature');
      expect(loaded.status, AgentGoalStatus.active);
      expect(loaded.deadlineAt, DateTime(2026, 8, 1).toUtc());
      expect(loaded.costCapMicros, 5000);
      expect(loaded.costMicros, 1250);
      expect(loaded.maxRuns, 100);
      expect(loaded.runCount, 7);
      expect(loaded.activeRunId, 'run-9');
      expect(loaded.consecutiveFailures, 2);
      expect(loaded.requestedByUserId, 'user-1');
      expect(loaded.summary, 'halfway there');
      expect(loaded.createdAt, DateTime(2026).toUtc());
      expect(loaded.updatedAt, DateTime(2026).toUtc());
    });

    test('an uncapped goal round-trips null walls', () async {
      await repo.upsert(goal(uncapped: true));
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded, isNotNull);
      expect(loaded!.deadlineAt, isNull);
      expect(loaded.maxRuns, isNull);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await repo.upsert(goal(userText: 'first'));
      await repo.upsert(
        goal(userText: 'second', status: AgentGoalStatus.paused, runCount: 3),
      );
      final loaded = await repo.getById('w-1', 'goal-1');
      expect(loaded?.userText, 'second');
      expect(loaded?.status, AgentGoalStatus.paused);
      expect(loaded?.runCount, 3);
      expect(await repo.listByWorkspace('w-1'), hasLength(1));
    });
  });

  group('wire-name mapping', () {
    test('every status round-trips through its wire name', () async {
      for (final status in AgentGoalStatus.values) {
        final id = 'goal-${status.wire}';
        await repo.upsert(goal(id: id, status: status));
        expect((await repo.getById('w-1', id))?.status, status);
      }
    });

    test('budget_exhausted persists as the snake-case wire name', () async {
      await repo.upsert(
        goal(id: 'goal-be', status: AgentGoalStatus.budgetExhausted),
      );
      final raw = await dbs
          .of('w-1')
          .customSelect(
            "SELECT status FROM agent_goal_runs WHERE id = 'goal-be'",
          )
          .getSingle();
      expect(raw.read<String>('status'), 'budget_exhausted');
      expect(
        (await repo.getById('w-1', 'goal-be'))?.status,
        AgentGoalStatus.budgetExhausted,
      );
    });

    test('every hold and unattended policy round-trips', () async {
      var i = 0;
      for (final hold in GoalHold.values) {
        final id = 'goal-h${i++}';
        await repo.upsert(
          goal(id: id, status: AgentGoalStatus.paused, hold: hold),
        );
        expect((await repo.getById('w-1', id))?.hold, hold);
      }
      for (final policy in GoalUnattendedPolicy.values) {
        final id = 'goal-u${policy.wire}';
        await repo.upsert(
          goal(id: id, status: AgentGoalStatus.paused, unattended: policy),
        );
        expect((await repo.getById('w-1', id))?.unattended, policy);
      }
    });

    test('the stored-value check refuses an unknown hold', () async {
      await repo.upsert(goal());
      await expectLater(
        dbs
            .of('w-1')
            .customStatement(
              "UPDATE agent_goal_runs SET hold = 'napping' WHERE id = 'goal-1'",
            ),
        throwsA(anything),
      );
    });
  });

  group('workspace isolation', () {
    test('getById does not find a foreign-workspace id', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      expect(await repo.getById('w-2', 'goal-1'), isNull);
    });

    test(
      'watchByWorkspace emits only the workspace rows, newest first',
      () async {
        await repo.upsert(goal(id: 'goal-1'));
        await repo.upsert(
          goal(
            id: 'goal-2',
            agentId: 'agent-2',
            createdAt: DateTime.utc(2026, 2),
          ),
        );
        await repo.upsert(goal(id: 'goal-3', workspaceId: 'w-2'));
        final rows = await repo.watchByWorkspace('w-1').first;
        expect(rows.map((g) => g.id), ['goal-2', 'goal-1']);
      },
    );

    test(
      'listByWorkspace returns only the workspace rows, newest first',
      () async {
        await repo.upsert(goal(id: 'goal-1', createdAt: DateTime(2026)));
        await repo.upsert(
          goal(id: 'goal-2', agentId: 'agent-2', createdAt: DateTime(2026, 2)),
        );
        await repo.upsert(goal(id: 'goal-3', workspaceId: 'w-2'));
        final rows = await repo.listByWorkspace('w-1');
        expect(rows.map((g) => g.id), ['goal-2', 'goal-1']);
      },
    );

    test('getActiveForAgent does not leak across workspaces', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      expect(await repo.getActiveForAgent('w-2', 'agent-1'), isNull);
    });
  });

  group('listActive (documented cross-workspace exception)', () {
    test('returns active goals across ALL workspaces', () async {
      await repo.upsert(goal(id: 'goal-1', workspaceId: 'w-1'));
      await repo.upsert(
        goal(id: 'goal-2', workspaceId: 'w-2', agentId: 'agent-2'),
      );
      final active = await repo.listActive();
      expect(active.map((g) => g.id), containsAll(['goal-1', 'goal-2']));
    });

    test('excludes every terminal and paused status', () async {
      var i = 0;
      for (final status in AgentGoalStatus.values) {
        await repo.upsert(goal(id: 'goal-${i++}', status: status));
      }
      final active = await repo.listActive();
      expect(active, hasLength(1));
      expect(active.single.status, AgentGoalStatus.active);
    });
  });

  group('verification state', () {
    final contract = GoalContract(
      criteria: const ['the tests pass', 'the docs mention it'],
      checks: [GoalCheck(run: 'make test')],
      boundaries: 'do not touch the API',
      stopWhen: 'the cost passes half the cap',
    );
    final verification = GoalVerification(
      round: 2,
      claimSummary: 'done',
      claimEvidence: [
        GoalClaimEvidence(criterion: 'the tests pass', evidence: 'ran them'),
      ],
      checks: [
        GoalCheckResult(
          run: 'make test',
          where: GoalCheckLocation.worktree,
          exitCode: 0,
          outputTail: 'ok',
        ),
      ],
      verdict: GoalVerdict(
        verdict: GoalVerdictOutcome.pass,
        items: [
          GoalVerdictItem(
            criterion: 'the tests pass',
            state: GoalCriterionState.met,
            evidence: 'exit 0',
          ),
        ],
      ),
      reviewerAgentId: 'agent-2',
      reviewRunId: 'run-9',
      fingerprint: 'abc',
      lastFailedFingerprint: 'fp-failed',
      approvedByUserId: 'user-7',
      at: DateTime.utc(2026, 3),
    );

    test('every new field round-trips', () async {
      await repo.upsert(
        goal(
          status: AgentGoalStatus.paused,
          contract: contract,
          hold: GoalHold.needsReview,
          holdUntil: DateTime(2026, 4),
          holdDetail: 'three failed rounds',
          noProgressStreak: 2,
          verificationRounds: 3,
          lastFingerprint: 'fp-1',
          lastActivityDigest: 'digest-1',
          parkCount: 4,
          fresh: true,
          unattended: GoalUnattendedPolicy.assume,
          checkerAgentId: 'agent-2',
          verification: verification,
        ),
      );
      final loaded = (await repo.getById('w-1', 'goal-1'))!;
      expect(loaded.contract, contract);
      expect(loaded.hold, GoalHold.needsReview);
      expect(loaded.holdUntil, DateTime(2026, 4).toUtc());
      expect(loaded.holdDetail, 'three failed rounds');
      expect(loaded.noProgressStreak, 2);
      expect(loaded.verificationRounds, 3);
      expect(loaded.lastFingerprint, 'fp-1');
      expect(loaded.lastActivityDigest, 'digest-1');
      expect(loaded.parkCount, 4);
      expect(loaded.fresh, isTrue);
      expect(loaded.unattended, GoalUnattendedPolicy.assume);
      expect(loaded.checkerAgentId, 'agent-2');
      expect(loaded.verification, verification);
    });

    test('a fresh goal reads the defaults', () async {
      await repo.upsert(goal());
      final loaded = (await repo.getById('w-1', 'goal-1'))!;
      expect(loaded.contract, isNull);
      expect(loaded.hold, isNull);
      expect(loaded.noProgressStreak, 0);
      expect(loaded.verificationRounds, 0);
      expect(loaded.parkCount, 0);
      expect(loaded.fresh, isFalse);
      expect(loaded.unattended, GoalUnattendedPolicy.wait);
      expect(loaded.verification, isNull);
    });

    test('a malformed contract or verification reads as absent', () async {
      await repo.upsert(goal());
      await dbs
          .of('w-1')
          .customStatement(
            'UPDATE agent_goal_runs SET contract = \'{"criteria": 3}\', '
            'verification = \'{"round": 0}\' WHERE id = \'goal-1\'',
          );
      final loaded = (await repo.getById('w-1', 'goal-1'))!;
      expect(loaded.contract, isNull);
      expect(loaded.verification, isNull);
    });

    test('the start commits round-trip; a malformed stored value reads as '
        'absent', () async {
      final refs = GoalStartRefs({
        'app': 'a' * 40,
        'docs': GoalStartRefs.noCommit,
      });
      await repo.upsert(goal().copyWith(startRefs: refs));
      expect((await repo.getById('w-1', 'goal-1'))!.startRefs, refs);
      await dbs
          .of('w-1')
          .customStatement(
            'UPDATE agent_goal_runs SET start_ref = \'{"app": "HEAD"}\' '
            "WHERE id = 'goal-1'",
          );
      expect((await repo.getById('w-1', 'goal-1'))!.startRefs, isNull);
      await expectLater(
        dbs
            .of('w-1')
            .customStatement(
              "UPDATE agent_goal_runs SET start_ref = '[1]' "
              "WHERE id = 'goal-1'",
            ),
        throwsA(anything),
      );
    });

    test('the pipeline step round-trips and lists by run, in its workspace '
        'only; half a link reads as none', () async {
      final link = GoalPipelineLink(pipelineRunId: 'prun-1', stepId: 'pursue');
      expect(await repo.getById('w-1', 'goal-1'), isNull);
      await repo.upsert(goal().copyWith(pipeline: link));
      await repo.upsert(
        goal(id: 'goal-2', workspaceId: 'w-2').copyWith(pipeline: link),
      );
      await repo.upsert(
        goal(id: 'goal-3', agentId: 'agent-2', status: AgentGoalStatus.paused),
      );
      expect((await repo.getById('w-1', 'goal-1'))!.pipeline, link);
      expect((await repo.getById('w-1', 'goal-3'))!.pipeline, isNull);
      expect(
        (await repo.listForPipelineRun('w-1', 'prun-1')).map((g) => g.id),
        ['goal-1'],
      );
      expect(
        (await repo.listForPipelineRun('w-2', 'prun-1')).map((g) => g.id),
        ['goal-2'],
      );
      expect(await repo.listForPipelineRun('w-1', 'prun-9'), isEmpty);
      await dbs
          .of('w-1')
          .customStatement(
            'UPDATE agent_goal_runs SET pipeline_step_id = NULL '
            "WHERE id = 'goal-1'",
          );
      expect((await repo.getById('w-1', 'goal-1'))!.pipeline, isNull);
    });

    test('an activity digest the entity would refuse reads as absent', () async {
      await repo.upsert(goal(lastActivityDigest: 'd'));
      await dbs
          .of('w-1')
          .customStatement(
            "UPDATE agent_goal_runs SET last_activity_digest = '${'x' * 129}' "
            "WHERE id = 'goal-1'",
          );
      final loaded = (await repo.getById('w-1', 'goal-1'))!;
      expect(loaded.lastActivityDigest, isNull);
    });

    test('the column check refuses a contract that is not an object', () async {
      await repo.upsert(goal());
      await expectLater(
        dbs
            .of('w-1')
            .customStatement(
              "UPDATE agent_goal_runs SET contract = '[1]' WHERE id = 'goal-1'",
            ),
        throwsA(anything),
      );
    });
  });

  group('one active goal per agent', () {
    test('a second active goal for the agent is refused', () async {
      await repo.upsert(goal(id: 'goal-1'));
      await expectLater(
        repo.upsert(goal(id: 'goal-2')),
        throwsA(
          isA<GoalAlreadyActiveException>()
              .having((e) => e.agentId, 'agentId', 'agent-1')
              .having((e) => e.workspaceId, 'workspaceId', 'w-1')
              .having((e) => e.code, 'code', 'goal_already_active'),
        ),
      );
      expect(await repo.getById('w-1', 'goal-2'), isNull);
    });

    test('re-saving the active goal itself is not refused', () async {
      await repo.upsert(goal(id: 'goal-1'));
      await repo.upsert(goal(id: 'goal-1', runCount: 2));
      expect((await repo.getById('w-1', 'goal-1'))?.runCount, 2);
    });

    test('paused and ended goals do not count', () async {
      await repo.upsert(goal(id: 'goal-p', status: AgentGoalStatus.paused));
      await repo.upsert(goal(id: 'goal-c', status: AgentGoalStatus.completed));
      await repo.upsert(goal(id: 'goal-1'));
      // A paused goal of the agent may be saved while another is active.
      await repo.upsert(
        goal(id: 'goal-p', status: AgentGoalStatus.paused, runCount: 1),
      );
      expect((await repo.getActiveForAgent('w-1', 'agent-1'))?.id, 'goal-1');
    });

    test('resuming a paused goal while another is active is refused', () async {
      await repo.upsert(goal(id: 'goal-p', status: AgentGoalStatus.paused));
      await repo.upsert(goal(id: 'goal-1'));
      await expectLater(
        repo.upsert(goal(id: 'goal-p')),
        throwsA(isA<GoalAlreadyActiveException>()),
      );
      expect(
        (await repo.getById('w-1', 'goal-p'))?.status,
        AgentGoalStatus.paused,
      );
    });

    test(
      'another agent, or the same agent elsewhere, is not refused',
      () async {
        await repo.upsert(goal(id: 'goal-1'));
        await repo.upsert(goal(id: 'goal-2', agentId: 'agent-2'));
        await repo.upsert(goal(id: 'goal-3', workspaceId: 'w-2'));
        expect(await repo.listActive(), hasLength(3));
      },
    );
  });

  group('listHeld', () {
    test(
      'lists active and paused goals holding something, oldest first',
      () async {
        await repo.upsert(
          goal(
            id: 'goal-new',
            status: AgentGoalStatus.paused,
            hold: GoalHold.needsReview,
            createdAt: DateTime.utc(2026, 3),
          ),
        );
        await repo.upsert(
          goal(
            id: 'goal-old',
            hold: GoalHold.limit,
            createdAt: DateTime.utc(2026, 1),
          ),
        );
        await repo.upsert(goal(id: 'goal-free', agentId: 'agent-2'));
        await repo.upsert(
          goal(
            id: 'goal-ended',
            agentId: 'agent-2',
            status: AgentGoalStatus.cancelled,
            hold: GoalHold.needsReview,
          ),
        );
        expect((await repo.listHeld('w-1')).map((g) => g.id), [
          'goal-old',
          'goal-new',
        ]);
        expect(
          (await repo.listHeld(
            'w-1',
            hold: GoalHold.needsReview,
          )).map((g) => g.id),
          ['goal-new'],
        );
        expect(await repo.listHeld('w-2'), isEmpty);
      },
    );
  });

  group('getActiveForAgent', () {
    test('returns only the active goal for the agent', () async {
      await repo.upsert(
        goal(id: 'goal-done', status: AgentGoalStatus.completed),
      );
      await repo.upsert(
        goal(id: 'goal-failed', status: AgentGoalStatus.failed),
      );
      await repo.upsert(goal(id: 'goal-live'));
      await repo.upsert(goal(id: 'goal-other', agentId: 'agent-2'));
      final loaded = await repo.getActiveForAgent('w-1', 'agent-1');
      expect(loaded?.id, 'goal-live');
    });

    test('returns null when the agent has no active goal', () async {
      await repo.upsert(
        goal(id: 'goal-done', status: AgentGoalStatus.completed),
      );
      expect(await repo.getActiveForAgent('w-1', 'agent-1'), isNull);
    });
  });

  group('conditional writes', () {
    test('getByActiveRunId finds the goal whose segment the run is, in its '
        'workspace only', () async {
      await repo.upsert(goal(activeRunId: 'run-9'));
      expect((await repo.getByActiveRunId('w-1', 'run-9'))?.id, 'goal-1');
      expect(await repo.getByActiveRunId('w-2', 'run-9'), isNull);
      expect(await repo.getByActiveRunId('w-1', 'run-other'), isNull);
    });

    test('replaceIf writes only over the exact row the caller read, every '
        'field included', () async {
      await repo.upsert(goal(costMicros: 700, runCount: 2));
      final read = (await repo.getById('w-1', 'goal-1'))!;
      final paused = read.copyWith(
        status: AgentGoalStatus.paused,
        hold: GoalHold.byPerson,
      );

      expect(await repo.replaceIf(paused, expected: read), isTrue);
      // The same move again finds the row already changed.
      expect(await repo.replaceIf(paused, expected: read), isFalse);
      final stored = (await repo.getById('w-1', 'goal-1'))!;
      expect(stored, paused);
      expect(stored.costMicros, 700);
      expect(stored.runCount, 2);
    });

    test('replaceIf never undoes a change made after the read', () async {
      await repo.upsert(goal(activeRunId: 'run-9', costMicros: 100));
      final read = (await repo.getById('w-1', 'goal-1'))!;
      // The segment's end lands between the read and the write.
      expect(
        await repo.recordSegmentEnd(
          'w-1',
          'goal-1',
          runId: 'run-9',
          costMicros: 50,
          at: DateTime(2026, 7, 2),
        ),
        isTrue,
      );

      expect(
        await repo.replaceIf(
          read.copyWith(status: AgentGoalStatus.cancelled),
          expected: read,
        ),
        isFalse,
      );
      final stored = (await repo.getById('w-1', 'goal-1'))!;
      expect(stored.status, AgentGoalStatus.active);
      expect(stored.costMicros, 150);
    });

    test('replaceIf refuses a different goal or workspace', () async {
      await repo.upsert(goal());
      final read = (await repo.getById('w-1', 'goal-1'))!;
      expect(
        () => repo.replaceIf(
          goal(id: 'goal-2', status: AgentGoalStatus.paused),
          expected: read,
        ),
        throwsArgumentError,
      );
    });

    test('replaceIf keeps one active goal per agent', () async {
      await repo.upsert(goal(id: 'goal-live'));
      await repo.upsert(goal(id: 'goal-2', status: AgentGoalStatus.paused));
      final paused = (await repo.getById('w-1', 'goal-2'))!;

      await expectLater(
        repo.replaceIf(
          paused.copyWith(status: AgentGoalStatus.active),
          expected: paused,
        ),
        throwsA(isA<GoalAlreadyActiveException>()),
      );
    });

    test('recordSegmentEnd counts a segment once and frees the goal',
        () async {
      await repo.upsert(goal(activeRunId: 'run-9', costMicros: 100));
      final at = DateTime(2026, 7, 2);

      expect(
        await repo.recordSegmentEnd(
          'w-1',
          'goal-1',
          runId: 'run-9',
          costMicros: 250,
          at: at,
        ),
        isTrue,
      );
      expect(
        await repo.recordSegmentEnd(
          'w-1',
          'goal-1',
          runId: 'run-9',
          costMicros: 250,
          at: at,
        ),
        isFalse,
      );
      final stored = (await repo.getById('w-1', 'goal-1'))!;
      expect(stored.costMicros, 350);
      expect(stored.runCount, 1);
      expect(stored.activeRunId, isNull);
    });

    test('recordSegmentEnd does not reach another workspace', () async {
      await repo.upsert(goal(activeRunId: 'run-9'));

      expect(
        await repo.recordSegmentEnd(
          'w-2',
          'goal-1',
          runId: 'run-9',
          costMicros: 250,
          at: DateTime(2026, 7, 2),
        ),
        isFalse,
      );
      expect((await repo.getById('w-1', 'goal-1'))!.costMicros, 0);
    });
  });
}
