import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/src/rpc/protocol.dart' show RepoOpKind, UndoClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// List-backed goal repository with optional controlled emissions for watches.
class _FakeAgentGoalRunRepository implements AgentGoalRunRepository {
  final List<AgentGoalRun> goals = [];
  StreamController<List<AgentGoalRun>>? emissions;

  @override
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId) =>
      emissions?.stream ??
      Stream.value(goals.where((g) => g.workspaceId == workspaceId).toList());

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async => goals
      .where((g) => g.workspaceId == workspaceId && g.id == id)
      .firstOrNull;

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async =>
      goals.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Future<List<AgentGoalRun>> listActive() async =>
      goals.where((g) => g.status == AgentGoalStatus.active).toList();

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async => goals
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.agentId == agentId &&
            g.status == AgentGoalStatus.active,
      )
      .firstOrNull;

  @override
  Future<void> upsert(AgentGoalRun goal) async {
    goals.removeWhere((g) => g.id == goal.id);
    goals.add(goal);
  }
}

/// Records the `(workspaceId, goalId)` pairs a `GoalControl` closure receives,
/// standing in for the server-side `GoalSupervisor` the runtime wires in.
class _RecordingGoalControl {
  final List<({String workspaceId, String goalId, int? raise})> calls = [];

  Future<void> call(
    String workspaceId,
    String goalId, {
    int? raiseCostCapCents,
  }) async {
    calls.add((
      workspaceId: workspaceId,
      goalId: goalId,
      raise: raiseCostCapCents,
    ));
  }
}

RepoOpContext _ctx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
  String deviceId = 'device-1',
  String userId = 'user-1',
}) => RepoOpContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: deviceId,
  userId: userId,
);

WatchQueryContext _watchCtx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
}) => WatchQueryContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: 'device-1',
  userId: 'user-1',
);

AgentGoalRun _goal({
  String id = 'g-1',
  String workspaceId = 'ws-1',
  String spaceId = 'ch-1',
  String conversationId = 'c-1',
  String userText = 'keep polishing until done',
  String? summary,
  AgentGoalKind kind = AgentGoalKind.loop,
  AgentGoalStatus status = AgentGoalStatus.paused,
}) => AgentGoalRun(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  conversationId: conversationId,
  agentId: 'a-1',
  userText: userText,
  kind: kind,
  status: status,
  deadlineAt: DateTime(2026, 8, 1, 12),
  costCapCents: 5000,
  costCents: 125,
  maxRuns: 100,
  runCount: 3,
  consecutiveFailures: 1,
  activeRunId: 'run-9',
  requestedByUserId: 'user-1',
  summary: summary,
  createdAt: DateTime(2026, 7, 1, 9),
  updatedAt: DateTime(2026, 7, 1, 10),
);

void main() {
  late _FakeAgentGoalRunRepository repository;
  late _RecordingGoalControl pauseGoal;
  late _RecordingGoalControl resumeGoal;
  late _RecordingGoalControl cancelGoal;
  late List<RepoOp> ops;

  RepoOp op(String name) => ops.firstWhere((o) => o.name == name);

  setUp(() {
    repository = _FakeAgentGoalRunRepository();
    pauseGoal = _RecordingGoalControl();
    resumeGoal = _RecordingGoalControl();
    cancelGoal = _RecordingGoalControl();
    ops = agentGoalRunOps(
      pauseGoal: pauseGoal.call,
      resumeGoal: resumeGoal.call,
      cancelGoal: cancelGoal.call,
    );
  });

  group('agentGoalRuns.watchForConversation', () {
    test('filters the workspace goals to the conversation_id arg', () async {
      repository.goals
        ..add(_goal(id: 'g-1', conversationId: 'c-1'))
        ..add(_goal(id: 'g-2', conversationId: 'c-2'))
        ..add(_goal(id: 'g-3', conversationId: 'c-1'))
        ..add(_goal(id: 'g-other', workspaceId: 'ws-2'));

      final query = agentGoalRunsWatchQuery(agentGoalRunRepository: repository);
      final snapshot = await query
          .handler(_watchCtx({'conversation_id': 'c-1'}))
          .first;

      final goals = (snapshot['goals'] as List).cast<Map<String, dynamic>>();
      expect(goals.map((g) => g['id']), ['g-1', 'g-3']);
      expect(goals.first['conversation_id'], 'c-1');
      expect(goals.first['workspace_id'], 'ws-1');
    });

    test('emits an empty goals list when nothing matches', () async {
      repository.goals.add(_goal(conversationId: 'c-2'));

      final query = agentGoalRunsWatchQuery(agentGoalRunRepository: repository);
      final snapshot = await query
          .handler(_watchCtx({'conversation_id': 'c-1'}))
          .first;

      expect(snapshot['goals'], isEmpty);
    });

    test('is workspace-scoped like the other per-conversation watches', () {
      final query = agentGoalRunsWatchQuery(agentGoalRunRepository: repository);
      expect(query.workspaceScoped, isTrue);
    });
  });

  group('agentGoalRuns.watchForWorkspace', () {
    test(
      'filters each emission by the subscriber’s current space grants',
      () async {
        final restricted = _goal(
          id: 'restricted',
          spaceId: 'repo-space',
          userText: 'restricted objective',
          summary: 'restricted completion',
        );
        final allowed = _goal(
          id: 'allowed',
          spaceId: 'open-space',
          userText: 'open objective',
          summary: 'open completion',
        );
        final foreign = _goal(
          id: 'foreign',
          workspaceId: 'ws-2',
          spaceId: 'open-space',
        );
        final emissions = StreamController<List<AgentGoalRun>>();
        repository.emissions = emissions;
        final deniedSpaces = {'repo-space'};
        final checks =
            <({String workspaceId, String spaceId, String userId})>[];
        final query = agentGoalRunsWorkspaceWatchQuery(
          agentGoalRunRepository: repository,
          viewerTraceRestricted: (workspaceId, spaceId, userId) async {
            checks.add((
              workspaceId: workspaceId,
              spaceId: spaceId,
              userId: userId,
            ));
            return deniedSpaces.contains(spaceId);
          },
        );
        final snapshots = StreamIterator(query.handler(_watchCtx(const {})));
        addTearDown(() async {
          await snapshots.cancel();
          await emissions.close();
        });

        Future<List<Map<String, dynamic>>> nextGoals(
          List<AgentGoalRun> rows,
        ) async {
          final next = snapshots.moveNext();
          emissions.add(rows);
          expect(await next, isTrue);
          return (snapshots.current['goals'] as List)
              .cast<Map<String, dynamic>>();
        }

        expect(query.workspaceScoped, isTrue);
        final first = await nextGoals([restricted, allowed]);
        expect(first.map((goal) => goal['id']), ['allowed']);
        expect(first.single['user_text'], 'open objective');
        expect(first.single['summary'], 'open completion');

        deniedSpaces.clear();
        final granted = await nextGoals([restricted, allowed]);
        expect(granted.map((goal) => goal['id']), ['restricted', 'allowed']);
        expect(granted.first['user_text'], 'restricted objective');
        expect(granted.first['summary'], 'restricted completion');

        deniedSpaces.add('repo-space');
        final revoked = await nextGoals([restricted, allowed, foreign]);
        expect(revoked.map((goal) => goal['id']), ['allowed']);
        expect(revoked.single['user_text'], 'open objective');
        expect(revoked.single['summary'], 'open completion');
        expect(checks, hasLength(6));
        expect(checks.map((check) => check.workspaceId), everyElement('ws-1'));
        expect(checks.map((check) => check.userId), everyElement('user-1'));
        expect(checks.map((check) => check.spaceId).toSet(), {
          'repo-space',
          'open-space',
        });
      },
    );
  });

  group('agentGoalRuns mutations', () {
    test('every op requires goal_id and mutates', () {
      for (final name in [
        'agentGoalRuns.pause',
        'agentGoalRuns.resume',
        'agentGoalRuns.cancel',
      ]) {
        expect(op(name).requiredArgs, ['goal_id']);
        expect(op(name).kind, RepoOpKind.mutate);
      }
    });

    test(
      'pause delegates to the supervisor with the session workspace',
      () async {
        final result = await op('agentGoalRuns.pause').handler(
          // A client-supplied workspace must never override the session binding.
          _ctx({'goal_id': 'g-1', 'workspace_id': 'ws-other'}),
        );

        expect(result, {'ok': true});
        expect(pauseGoal.calls, [
          (workspaceId: 'ws-1', goalId: 'g-1', raise: null),
        ]);
        expect(resumeGoal.calls, isEmpty);
        expect(cancelGoal.calls, isEmpty);
      },
    );

    test('resume delegates to the supervisor', () async {
      final result = await op(
        'agentGoalRuns.resume',
      ).handler(_ctx({'goal_id': 'g-7'}));

      expect(result, {'ok': true});
      expect(resumeGoal.calls, [
        (workspaceId: 'ws-1', goalId: 'g-7', raise: null),
      ]);
    });

    test('resume forwards a cost-cap raise to the supervisor', () async {
      final result = await op(
        'agentGoalRuns.resume',
      ).handler(_ctx({'goal_id': 'g-7', 'raise_cost_cap_cents': 10000}));

      expect(result, {'ok': true});
      expect(resumeGoal.calls, [
        (workspaceId: 'ws-1', goalId: 'g-7', raise: 10000),
      ]);
    });

    test('cancel delegates to the supervisor and is irreversible', () async {
      final result = await op(
        'agentGoalRuns.cancel',
      ).handler(_ctx({'goal_id': 'g-9'}));

      expect(result, {'ok': true});
      expect(cancelGoal.calls, [
        (workspaceId: 'ws-1', goalId: 'g-9', raise: null),
      ]);
      // Cancel is destructive with no inverse op: like the `*.delete` ops it
      // declares no undoClass, so the fail-safe default applies.
      expect(
        op('agentGoalRuns.cancel').effectiveUndoClass,
        UndoClass.irreversible,
      );
    });
  });
}
