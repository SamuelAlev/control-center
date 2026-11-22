import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, GoalRefusedException, NotFoundException;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_authority.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/src/rpc/protocol.dart' show RepoOpKind, UndoClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// List-backed goal repository.
class _FakeAgentGoalRunRepository implements AgentGoalRunRepository {
  final List<AgentGoalRun> goals = [];

  @override
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId) =>
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
  Future<List<AgentGoalRun>> listHeld(
    String workspaceId, {
    GoalHold? hold,
  }) async => goals
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.hold != null &&
            (hold == null || g.hold == hold),
      )
      .toList();

  @override
  Future<void> upsert(AgentGoalRun goal) async {
    goals.removeWhere((g) => g.id == goal.id);
    goals.add(goal);
  }

  @override
  Future<AgentGoalRun?> getByActiveRunId(
    String workspaceId,
    String runId,
  ) async => goals
      .where((g) => g.workspaceId == workspaceId && g.activeRunId == runId)
      .firstOrNull;

  @override
  Future<List<AgentGoalRun>> listForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => goals
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.pipeline?.pipelineRunId == pipelineRunId,
      )
      .toList();

  @override
  Future<bool> replaceIf(
    AgentGoalRun next, {
    required AgentGoalRun expected,
  }) async {
    final stored = await getById(next.workspaceId, next.id);
    if (stored == null || stored != expected) {
      return false;
    }
    await upsert(next);
    return true;
  }

  @override
  Future<bool> recordSegmentEnd(
    String workspaceId,
    String goalId, {
    required String runId,
    required int costMicros,
    required DateTime at,
  }) async {
    final stored = await getById(workspaceId, goalId);
    if (stored == null || stored.activeRunId != runId) {
      return false;
    }
    await upsert(
      stored.copyWith(
        costMicros: stored.costMicros + costMicros,
        runCount: stored.runCount + 1,
        removeActiveRunId: true,
        updatedAt: at,
      ),
    );
    return true;
  }
}

/// Records the `(workspaceId, goalId)` pairs a `GoalControl` closure receives,
/// standing in for the server-side `GoalSupervisor` the runtime wires in.
class _RecordingGoalControl {
  final List<({String workspaceId, String goalId, int? raise})> calls = [];

  Future<void> call(
    String workspaceId,
    String goalId, {
    int? raiseCostCapMicros,
  }) async {
    calls.add((
      workspaceId: workspaceId,
      goalId: goalId,
      raise: raiseCostCapMicros,
    ));
  }
}

RepoOpContext _ctx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
  String deviceId = 'device-1',
  String userId = 'user-1',
  WorkspaceRole role = WorkspaceRole.member,
}) => RepoOpContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: deviceId,
  userId: userId,
  role: role,
);

/// Workspace roles for the watches: `admin-1` is an admin, everyone else a
/// member.
Future<WorkspaceRole?> _roleOf(String workspaceId, String userId) async =>
    userId == 'admin-1' ? WorkspaceRole.admin : WorkspaceRole.member;

List<WatchQuery> _watches(AgentGoalRunRepository repository) =>
    agentGoalRunWatchQueries(
      agentGoalRunRepository: repository,
      requireSpace: _requireSpace,
      roleOf: _roleOf,
    );

WatchQuery _conversationWatch(AgentGoalRunRepository repository) => _watches(
  repository,
).firstWhere((q) => q.name == 'agentGoalRuns.watchForConversation');

WatchQuery _workspaceWatch(AgentGoalRunRepository repository) => _watches(
  repository,
).firstWhere((q) => q.name == 'agentGoalRuns.watchForWorkspace');

WatchQueryContext _watchCtx(
  Map<String, dynamic> args, {
  String? workspaceId = 'ws-1',
  String userId = 'user-1',
}) => WatchQueryContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: 'device-1',
  userId: userId,
);

/// The space a member without access asks about, and that member.
const _secretSpace = 'ch-secret';
const _outsider = 'outsider';

/// The space gate: refuses [_outsider] for [_secretSpace], records each ask.
final List<(String, String, String)> _spaceChecks = [];
Future<void> _requireSpace(
  String workspaceId,
  String userId,
  String spaceId,
) async {
  _spaceChecks.add((workspaceId, userId, spaceId));
  if (userId == _outsider && spaceId == _secretSpace) {
    throw const AuthException('You may not read this space.');
  }
}

AgentGoalRun _goal({
  String id = 'g-1',
  String workspaceId = 'ws-1',
  String spaceId = 'ch-1',
  String conversationId = 'c-1',
  String userText = 'keep polishing until done',
  String? summary,
  AgentGoalStatus status = AgentGoalStatus.paused,
  String? requester = 'user-1',
}) => AgentGoalRun(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  conversationId: conversationId,
  agentId: 'a-1',
  userText: userText,
  status: status,
  deadlineAt: DateTime(2026, 8, 1, 12),
  costCapMicros: 50000000,
  costMicros: 1250000,
  maxRuns: 100,
  runCount: 3,
  consecutiveFailures: 1,
  activeRunId: 'run-9',
  requestedByUserId: requester,
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
    _spaceChecks.clear();
    repository.goals.addAll([
      for (final id in ['g-1', 'g-3', 'g-7', 'g-9']) _goal(id: id),
      _goal(id: 'g-secret', spaceId: _secretSpace),
    ]);
    ops = agentGoalRunOps(
      goals: repository,
      requireSpace: _requireSpace,
      pauseGoal: pauseGoal.call,
      resumeGoal: resumeGoal.call,
      cancelGoal: cancelGoal.call,
    );
  });

  group('agentGoalRuns.watchForConversation', () {
    test('filters the workspace goals to the conversation_id arg', () async {
      repository.goals
        ..clear()
        ..add(_goal(id: 'g-1', conversationId: 'c-1'))
        ..add(_goal(id: 'g-2', conversationId: 'c-2'))
        ..add(_goal(id: 'g-3', conversationId: 'c-1'))
        ..add(_goal(id: 'g-other', workspaceId: 'ws-2'));

      final query = _conversationWatch(repository);
      final snapshot = await query
          .handler(_watchCtx({'conversation_id': 'c-1'}))
          .first;

      final goals = (snapshot['goals'] as List).cast<Map<String, dynamic>>();
      expect(goals.map((g) => g['id']), ['g-1', 'g-3']);
      expect(goals.first['conversation_id'], 'c-1');
      expect(goals.first['workspace_id'], 'ws-1');
    });

    test('emits an empty goals list when nothing matches', () async {
      repository.goals
        ..clear()
        ..add(_goal(conversationId: 'c-2'));

      final query = _conversationWatch(repository);
      final snapshot = await query
          .handler(_watchCtx({'conversation_id': 'c-1'}))
          .first;

      expect(snapshot['goals'], isEmpty);
    });

    test('a member who may not read the goal\'s space sees none of its goals; '
        'a member who may sees them', () async {
      repository.goals
        ..clear()
        ..add(_goal(id: 'g-s', spaceId: _secretSpace, conversationId: 'c-s'));
      final query = _conversationWatch(repository);
      final hidden = await query
          .handler(_watchCtx({'conversation_id': 'c-s'}, userId: _outsider))
          .first;
      expect(hidden['goals'], isEmpty);
      final shown = await query
          .handler(_watchCtx({'conversation_id': 'c-s'}))
          .first;
      expect(((shown['goals'] as List).single as Map)['id'], 'g-s');
      expect(_spaceChecks, contains(('ws-1', _outsider, _secretSpace)));
    });

    test('is workspace-scoped like the other per-conversation watches', () {
      final query = _conversationWatch(repository);
      expect(query.workspaceScoped, isTrue);
    });
  });

  group('agentGoalRuns.watchForWorkspace', () {
    test(
      'G6: each emission passes the space gate, as agentGoalRuns.get: a '
      'member who fails it for a review space sees none of its goals',
      () async {
        final hidden = _goal(
          id: 'hidden',
          spaceId: _secretSpace,
          userText: 'hidden objective',
          summary: 'hidden completion',
        );
        final open = _goal(
          id: 'open',
          spaceId: 'open-space',
          userText: 'open objective',
          summary: 'open completion',
        );
        final foreign = _goal(
          id: 'foreign',
          workspaceId: 'ws-2',
          spaceId: 'open-space',
        );
        repository.goals
          ..clear()
          ..addAll([hidden, open, foreign]);
        _spaceChecks.clear();
        final query = _workspaceWatch(repository);
        expect(query.workspaceScoped, isTrue);
        Future<List<Map<String, dynamic>>> goalsFor(String userId) async =>
            ((await query
                        .handler(_watchCtx(const {}, userId: userId))
                        .first)['goals']
                    as List)
                .cast<Map<String, dynamic>>();

        final outsider = await goalsFor(_outsider);
        expect(outsider.map((g) => g['id']), ['open']);
        expect(outsider.single['user_text'], 'open objective');
        expect(
          _spaceChecks.where((c) => c.$2 == _outsider).map((c) => c.$3),
          containsAll([_secretSpace, 'open-space']),
        );
        final member = await goalsFor('user-1');
        expect(member.map((g) => g['id']), ['hidden', 'open']);
        expect(member.first['summary'], 'hidden completion');
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
      ).handler(_ctx({'goal_id': 'g-7', 'raise_cost_cap_micros': 100000000}));

      expect(result, {'ok': true});
      expect(resumeGoal.calls, [
        (workspaceId: 'ws-1', goalId: 'g-7', raise: 100000000),
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

  group("whose goal it is (resume and budget are the requester's)", () {
    final notYours = throwsA(
      isA<AuthException>().having((e) => e.code, 'code', goalNotYoursKind),
    );

    test('another member, even an admin or the owner, may not resume or '
        "raise a person's goal, but may pause and cancel it", () async {
      for (final role in [
        WorkspaceRole.member,
        WorkspaceRole.admin,
        WorkspaceRole.owner,
      ]) {
        await expectLater(
          op('agentGoalRuns.resume').handler(
            _ctx(
              {'goal_id': 'g-1', 'raise_cost_cap_micros': 1000000},
              userId: 'user-2',
              role: role,
            ),
          ),
          notYours,
          reason: role.name,
        );
      }
      expect(resumeGoal.calls, isEmpty);
      await op(
        'agentGoalRuns.pause',
      ).handler(_ctx({'goal_id': 'g-1'}, userId: 'user-2'));
      await op(
        'agentGoalRuns.cancel',
      ).handler(_ctx({'goal_id': 'g-3'}, userId: 'user-2'));
      expect(pauseGoal.calls.single.goalId, 'g-1');
      expect(cancelGoal.calls.single.goalId, 'g-3');
      // The requester may.
      await op('agentGoalRuns.resume').handler(_ctx({'goal_id': 'g-1'}));
      expect(resumeGoal.calls.single.goalId, 'g-1');
    });

    test("a goal nobody requested is a workspace admin's to resume", () async {
      repository.goals.add(_goal(id: 'g-bot', requester: null));
      await expectLater(
        op('agentGoalRuns.resume').handler(_ctx({'goal_id': 'g-bot'})),
        notYours,
      );
      await op('agentGoalRuns.resume').handler(
        _ctx(
          {'goal_id': 'g-bot'},
          userId: 'admin-1',
          role: WorkspaceRole.admin,
        ),
      );
      expect(resumeGoal.calls.single.goalId, 'g-bot');
    });

    test(
      'every goal on the wire says whether this viewer may resume it',
      () async {
        repository.goals
          ..clear()
          ..add(_goal(id: 'g-ada', conversationId: 'c-1'))
          ..add(_goal(id: 'g-bot', conversationId: 'c-1', requester: null));
        Future<Map<String, Object?>> canResume(String userId) async {
          final snapshot = await _conversationWatch(repository)
              .handler(_watchCtx({'conversation_id': 'c-1'}, userId: userId))
              .first;
          return {
            for (final g in (snapshot['goals'] as List).cast<Map>())
              g['id'] as String: g['can_resume'],
          };
        }

        expect(await canResume('user-1'), {'g-ada': true, 'g-bot': false});
        expect(await canResume('user-2'), {'g-ada': false, 'g-bot': false});
        expect(await canResume('admin-1'), {'g-ada': false, 'g-bot': true});
        final workspace = await _workspaceWatch(
          repository,
        ).handler(_watchCtx(const {}, userId: 'admin-1')).first;
        expect(
          {
            for (final g in (workspace['goals'] as List).cast<Map>())
              g['id']: g['can_resume'],
          },
          {'g-ada': false, 'g-bot': true},
        );
      },
    );
  });

  group('the space gate (isolation)', () {
    test('pause, resume and cancel refuse a member without the goal\'s space '
        'and reach no supervisor', () async {
      for (final name in [
        'agentGoalRuns.pause',
        'agentGoalRuns.resume',
        'agentGoalRuns.cancel',
      ]) {
        await expectLater(
          op(name).handler(_ctx({'goal_id': 'g-secret'}, userId: _outsider)),
          throwsA(isA<AuthException>()),
          reason: name,
        );
      }
      expect(pauseGoal.calls, isEmpty);
      expect(resumeGoal.calls, isEmpty);
      expect(cancelGoal.calls, isEmpty);
      // The same member may act on a goal of a space they can read.
      await op(
        'agentGoalRuns.pause',
      ).handler(_ctx({'goal_id': 'g-1'}, userId: _outsider));
      expect(pauseGoal.calls.single.goalId, 'g-1');
    });

    test('a goal id of another workspace is not found', () async {
      repository.goals.add(_goal(id: 'g-foreign', workspaceId: 'ws-2'));
      for (final name in [
        'agentGoalRuns.pause',
        'agentGoalRuns.resume',
        'agentGoalRuns.cancel',
      ]) {
        await expectLater(
          op(name).handler(_ctx({'goal_id': 'g-foreign'})),
          throwsA(isA<NotFoundException>()),
          reason: name,
        );
      }
      expect(pauseGoal.calls, isEmpty);
    });

    test('approveCompletion refuses a member without the goal\'s space and '
        'a foreign goal', () async {
      repository.goals.add(_goal(id: 'g-foreign', workspaceId: 'ws-2'));
      final calls = <String>[];
      final approve = buildAgentGoalReviewOps(
        goalSpace: goalSpaceGate(
          goals: repository,
          requireSpace: _requireSpace,
        ),
        approveCompletion: (workspaceId, goalId, {required userId}) async {
          calls.add(goalId);
          return _goal(id: goalId, status: AgentGoalStatus.completed);
        },
      ).single;
      await expectLater(
        approve.handler(_ctx({'goal_id': 'g-secret'}, userId: _outsider)),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        approve.handler(_ctx({'goal_id': 'g-foreign'})),
        throwsA(isA<NotFoundException>()),
      );
      expect(calls, isEmpty);
    });
  });

  group('agentGoalRuns.approveCompletion', () {
    test('closes the goal on the session person\'s word in the session '
        'workspace and answers the goal', () async {
      final calls = <(String, String, String)>[];
      final approve = buildAgentGoalReviewOps(
        goalSpace: goalSpaceGate(
          goals: repository,
          requireSpace: _requireSpace,
        ),
        approveCompletion: (workspaceId, goalId, {required userId}) async {
          calls.add((workspaceId, goalId, userId));
          return _goal(id: goalId, status: AgentGoalStatus.completed);
        },
      ).single;
      expect(approve.name, 'agentGoalRuns.approveCompletion');
      expect(approve.requiredArgs, ['goal_id']);
      expect(approve.kind, RepoOpKind.mutate);
      final result = await approve.handler(
        _ctx({'goal_id': 'g-3', 'workspace_id': 'ws-other'}, userId: 'user-7'),
      );
      expect(calls, [('ws-1', 'g-3', 'user-7')]);
      final goal = result['goal'] as Map;
      expect(goal['id'], 'g-3');
      expect(goal['status'], 'completed');
    });

    group('G2: closing a pipeline-linked goal as done is its requester\'s', () {
      late List<(String, String, String)> calls;
      late RepoOp approve;

      setUp(() {
        calls = [];
        approve = buildAgentGoalReviewOps(
          goalSpace: goalSpaceGate(
            goals: repository,
            requireSpace: _requireSpace,
          ),
          approveCompletion: (workspaceId, goalId, {required userId}) async {
            calls.add((workspaceId, goalId, userId));
            return (await repository.getById(
              workspaceId,
              goalId,
            ))!.copyWith(status: AgentGoalStatus.completed);
          },
        ).single;
        AgentGoalRun inReview(String id, {String? requester = 'user-1'}) =>
            _goal(
              id: id,
              requester: requester,
            ).copyWith(hold: GoalHold.needsReview);
        repository.goals
          ..clear()
          ..add(
            inReview('g-linked').copyWith(
              pipeline: GoalPipelineLink(pipelineRunId: 'pr-1', stepId: 's-1'),
            ),
          )
          ..add(inReview('g-plain'));
      });

      test('another member is refused and nothing settles; the requester '
          'closes it', () async {
        for (final role in [WorkspaceRole.member, WorkspaceRole.admin]) {
          await expectLater(
            () => approve.handler(
              _ctx({'goal_id': 'g-linked'}, userId: 'user-2', role: role),
            ),
            throwsA(
              isA<AuthException>().having(
                (e) => e.code,
                'kind',
                goalNotYoursKind,
              ),
            ),
          );
        }
        expect(calls, isEmpty);
        final result = await approve.handler(_ctx({'goal_id': 'g-linked'}));
        expect(calls, [('ws-1', 'g-linked', 'user-1')]);
        expect((result['goal'] as Map)['status'], 'completed');
      });

      test('an unlinked goal is closed by any member of the space, as '
          'before', () async {
        await approve.handler(_ctx({'goal_id': 'g-plain'}, userId: 'user-2'));
        expect(calls, [('ws-1', 'g-plain', 'user-2')]);
      });

      test('every goal on the wire says whether this viewer may close it as '
          'done', () async {
        Future<Map<Object?, Object?>> canApprove(String userId) async {
          final snapshot = await _workspaceWatch(
            repository,
          ).handler(_watchCtx(const {}, userId: userId)).first;
          return {
            for (final g in (snapshot['goals'] as List).cast<Map>())
              g['id']: g['can_approve'],
          };
        }

        expect(await canApprove('user-1'), {'g-linked': true, 'g-plain': true});
        expect(await canApprove('user-2'), {
          'g-linked': false,
          'g-plain': true,
        });
        final get = await approve.handler(_ctx({'goal_id': 'g-plain'}));
        expect((get['goal'] as Map)['can_approve'], isTrue);
      });
    });

    test('a goal not waiting for a review is refused with its kind', () {
      final approve = buildAgentGoalReviewOps(
        goalSpace: goalSpaceGate(
          goals: repository,
          requireSpace: _requireSpace,
        ),
        approveCompletion: (workspaceId, goalId, {required userId}) async =>
            throw const GoalRefusedException(
              'Only a goal paused for a review can be closed as done.',
              kind: GoalRefusedException.notInReviewKind,
            ),
      ).single;
      expect(
        approve.handler(_ctx({'goal_id': 'g-3'})),
        throwsA(
          isA<GoalRefusedException>().having(
            (e) => e.code,
            'kind',
            'goal_not_in_review',
          ),
        ),
      );
    });
  });
}
