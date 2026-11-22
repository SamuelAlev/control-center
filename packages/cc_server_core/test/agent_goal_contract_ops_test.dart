import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_authority.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checker_choice.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/agent_goal_contract_ops.dart';
import 'package:cc_server_core/src/demo/demo_profile.dart';
import 'package:test/test.dart';

const _contractJson = {
  'criteria': ['Tests pass', 'No API removed'],
  'checks': [
    {'run': 'make test', 'in': 'worktree', 'timeoutSeconds': 600},
  ],
  'boundaries': 'Only lib/.',
};

void main() {
  late _Goals goals;
  late _Agents agents;
  late _Guided guided;
  late List<(String, String, String)> spaceChecks;
  late Set<String> unreadableSpaces;
  late List<String> exposedAsked;
  late List<RepoOp> ops;

  RepoOp op(String name) => ops.firstWhere((o) => o.name == name);

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> args, {
    String workspaceId = 'ws-1',
    String userId = 'user-1',
    WorkspaceRole? role,
  }) async => Map<String, dynamic>.from(
    await op(name).handler(
          RepoOpContext(
            args: args,
            workspaceId: workspaceId,
            deviceId: 'device-1',
            userId: userId,
            role: role,
          ),
        )
        as Map,
  );

  Matcher refused(String kind) =>
      throwsA(isA<ValidationException>().having((e) => e.code, 'code', kind));

  setUp(() {
    goals = _Goals();
    agents = _Agents([
      _agent('agent-1', 'Ada'),
      _agent('agent-2', 'Mira'),
      _agent('agent-x', 'Foreign', workspaceId: 'ws-2'),
    ]);
    guided = _Guided();
    spaceChecks = [];
    unreadableSpaces = {};
    exposedAsked = [];
    ops = buildAgentGoalContractOps(
      goals: goals,
      agents: agents,
      requireSpace: (workspaceId, userId, spaceId) async {
        spaceChecks.add((workspaceId, userId, spaceId));
        if (unreadableSpaces.contains(spaceId)) {
          throw const AuthException('no access', code: 'space_forbidden');
        }
      },
      reposExposedBy: (workspaceId, spaceId) async {
        exposedAsked.add('$workspaceId/$spaceId');
        return ['repo-a', 'repo-b'];
      },
      guidedGoals: guided,
    );
    goals.put(_goal('g-1'));
    goals.put(_goal('g-active', status: AgentGoalStatus.active));
    goals.put(_goal('g-foreign', workspaceId: 'ws-2'));
  });

  test(
    'kinds: get is a read, the two writes are mutations the demo denies',
    () {
      expect(op('agentGoalRuns.get').kind, RepoOpKind.read);
      expect(op('agentGoalRuns.setContract').kind, RepoOpKind.mutate);
      expect(op('agentGoalRuns.setChecker').kind, RepoOpKind.mutate);
      expect(op('dispatch.guidedGoalStep').kind, RepoOpKind.read);
      expect(
        DemoProfile.defaultDeniedMutations,
        containsAll(['agentGoalRuns.setContract', 'agentGoalRuns.setChecker']),
      );
    },
  );

  group('agentGoalRuns.get', () {
    test('returns the goal after checking its space', () async {
      goals.put(_goal('g-nobody', requester: null));
      final result = await call('agentGoalRuns.get', {'goal_id': 'g-nobody'});
      expect((result['goal'] as Map)['id'], 'g-nobody');
      // Nobody requested it and the caller has no admin role here.
      expect((result['goal'] as Map)['can_resume'], isFalse);
      expect(spaceChecks.single, ('ws-1', 'user-1', 'space-1'));
    });

    test('refuses a space the caller may not read', () async {
      unreadableSpaces.add('space-1');
      expect(
        () => call('agentGoalRuns.get', {'goal_id': 'g-1'}),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('the space gate and the write grant (isolation)', () {
    test('setContract and setChecker refuse a member without the goal\'s '
        'space and write nothing', () async {
      unreadableSpaces.add('space-1');
      await expectLater(
        () => call('agentGoalRuns.setContract', {
          'goal_id': 'g-1',
          'contract': _contractJson,
        }),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-1',
          'checker_agent_id': 'agent-2',
        }),
        throwsA(isA<AuthException>()),
      );
      expect(goals.replaceIfCalls, isEmpty);
    });

    test('setContract and setChecker need the write grant on every '
        'repository the goal\'s space exposes; get needs none', () async {
      for (final name in [
        'agentGoalRuns.setContract',
        'agentGoalRuns.setChecker',
      ]) {
        expect(op(name).repoAccess, RepoGrantLevel.write, reason: name);
        final repos = await op(name).repoAccessVia!(
          const RepoOpContext(
            args: {'goal_id': 'g-1'},
            workspaceId: 'ws-1',
            deviceId: 'device-1',
            userId: 'user-1',
          ),
        );
        expect(repos, ['repo-a', 'repo-b'], reason: name);
      }
      expect(exposedAsked, ['ws-1/space-1', 'ws-1/space-1']);
      expect(op('agentGoalRuns.get').repoAccess, isNull);
    });

    test('the resolver refuses a member without the space before any grant '
        'is looked at', () async {
      unreadableSpaces.add('space-1');
      await expectLater(
        op('agentGoalRuns.setContract').repoAccessVia!(
          const RepoOpContext(
            args: {'goal_id': 'g-1'},
            workspaceId: 'ws-1',
            deviceId: 'device-1',
            userId: 'user-1',
          ),
        ),
        throwsA(isA<AuthException>()),
      );
      expect(exposedAsked, isEmpty);
    });
  });

  group('only the person the goal acts for changes what done means (G1)', () {
    Matcher notYours() => throwsA(
      isA<AuthException>().having((e) => e.code, 'code', goalNotYoursKind),
    );

    test('another write-grant member is refused on both ops and nothing '
        'changes', () async {
      final before = goals.byId['g-1'];
      for (final role in [WorkspaceRole.member, WorkspaceRole.admin]) {
        await expectLater(
          () => call(
            'agentGoalRuns.setContract',
            {'goal_id': 'g-1', 'contract': _contractJson},
            userId: 'user-2',
            role: role,
          ),
          notYours(),
        );
        await expectLater(
          () => call(
            'agentGoalRuns.setChecker',
            {'goal_id': 'g-1', 'checker_agent_id': 'agent-2'},
            userId: 'user-2',
            role: role,
          ),
          notYours(),
        );
      }
      expect(goals.replaceIfCalls, isEmpty);
      expect(goals.byId['g-1'], same(before));
    });

    test('the requester succeeds on both', () async {
      await call('agentGoalRuns.setContract', {
        'goal_id': 'g-1',
        'contract': _contractJson,
      });
      await call('agentGoalRuns.setChecker', {
        'goal_id': 'g-1',
        'checker_agent_id': 'agent-2',
      });
      expect(goals.byId['g-1']!.contract!.criteria, hasLength(2));
      expect(goals.byId['g-1']!.checkerAgentId, 'agent-2');
    });

    test('an admin succeeds only for a goal nobody requested', () async {
      goals.put(_goal('g-nobody', requester: null));
      await expectLater(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-nobody',
          'checker_agent_id': 'agent-2',
        }, userId: 'user-2'),
        notYours(),
      );
      await call(
        'agentGoalRuns.setChecker',
        {'goal_id': 'g-nobody', 'checker_agent_id': 'agent-2'},
        userId: 'user-2',
        role: WorkspaceRole.admin,
      );
      await call(
        'agentGoalRuns.setContract',
        {'goal_id': 'g-nobody', 'contract': _contractJson},
        userId: 'user-2',
        role: WorkspaceRole.admin,
      );
      expect(goals.byId['g-nobody']!.checkerAgentId, 'agent-2');
      expect(goals.byId['g-nobody']!.contract, isNotNull);
    });
  });

  group('agentGoalRuns.setContract', () {
    test('writes a paused goal conditionally and returns it', () async {
      final result = await call('agentGoalRuns.setContract', {
        'goal_id': 'g-1',
        'contract': _contractJson,
      });
      expect((result['goal'] as Map)['contract'], _contractJson);
      final stored = goals.byId['g-1']!;
      expect(stored.contract, GoalContract.fromJson(_contractJson));
      // A compare-and-set against the exact row that was read.
      expect(goals.replaceIfCalls.single.id, 'g-1');
      expect(goals.replaceIfCalls.single.status, AgentGoalStatus.paused);
    });

    test('null clears it; an absent contract is refused', () async {
      goals.put(
        _goal('g-1').copyWith(contract: GoalContract.fromJson(_contractJson)),
      );
      await call('agentGoalRuns.setContract', {
        'goal_id': 'g-1',
        'contract': null,
      });
      expect(goals.byId['g-1']!.contract, isNull);
      expect(
        () => call('agentGoalRuns.setContract', {'goal_id': 'g-1'}),
        refused(goalContractInvalidKind),
      );
    });

    test('only while paused', () async {
      expect(
        () => call('agentGoalRuns.setContract', {
          'goal_id': 'g-active',
          'contract': _contractJson,
        }),
        refused(goalNotPausedKind),
      );
      expect(goals.byId['g-active']!.contract, isNull);
    });

    test('a goal that moved on while saving is refused', () async {
      goals.loseNextRace = true;
      expect(
        () => call('agentGoalRuns.setContract', {
          'goal_id': 'g-1',
          'contract': _contractJson,
        }),
        refused(goalNotPausedKind),
      );
    });

    test('an invalid contract is refused with the reason, never cut', () async {
      expect(
        () => call('agentGoalRuns.setContract', {
          'goal_id': 'g-1',
          'contract': {
            'criteria': [for (var i = 0; i < 13; i++) 'c$i'],
          },
        }),
        refused(goalContractInvalidKind),
      );
      expect(
        () => call('agentGoalRuns.setContract', {
          'goal_id': 'g-1',
          'contract': 'tests pass',
        }),
        refused(goalContractInvalidKind),
      );
      expect(goals.byId['g-1']!.contract, isNull);
    });
  });

  group('agentGoalRuns.setChecker', () {
    test('sets and clears an agent of the workspace', () async {
      final result = await call('agentGoalRuns.setChecker', {
        'goal_id': 'g-1',
        'checker_agent_id': 'agent-2',
      });
      expect((result['goal'] as Map)['checker_agent_id'], 'agent-2');
      expect(goals.byId['g-1']!.checkerAgentId, 'agent-2');
      await call('agentGoalRuns.setChecker', {
        'goal_id': 'g-1',
        'checker_agent_id': null,
      });
      expect(goals.byId['g-1']!.checkerAgentId, isNull);
    });

    test("refuses an unknown agent, another workspace's agent, the goal's own "
        'agent, an active goal and an absent arg', () async {
      expect(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-1',
          'checker_agent_id': 'agent-9',
        }),
        refused(goalCheckerUnknownKind),
      );
      expect(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-1',
          'checker_agent_id': 'agent-x',
        }),
        refused(goalCheckerUnknownKind),
      );
      expect(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-1',
          'checker_agent_id': 'agent-1',
        }),
        refused(goalCheckerIsGoalAgentKind),
      );
      expect(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-active',
          'checker_agent_id': 'agent-2',
        }),
        refused(goalNotPausedKind),
      );
      expect(
        () => call('agentGoalRuns.setChecker', {'goal_id': 'g-1'}),
        refused(goalCheckerUnknownKind),
      );
      expect(goals.byId['g-1']!.checkerAgentId, isNull);
    });

    test('the refusal for an unknown agent lists the candidates', () async {
      await expectLater(
        () => call('agentGoalRuns.setChecker', {
          'goal_id': 'g-1',
          'checker_agent_id': 'agent-9',
        }),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Mira'),
          ),
        ),
      );
    });
  });

  group('foreign workspace ids', () {
    for (final (name, args) in [
      ('agentGoalRuns.get', <String, dynamic>{'goal_id': 'g-foreign'}),
      (
        'agentGoalRuns.setContract',
        <String, dynamic>{'goal_id': 'g-foreign', 'contract': _contractJson},
      ),
      (
        'agentGoalRuns.setChecker',
        <String, dynamic>{'goal_id': 'g-foreign', 'checker_agent_id': null},
      ),
    ]) {
      test('$name does not find a goal of another workspace', () async {
        await expectLater(
          () => call(name, args),
          throwsA(isA<NotFoundException>()),
        );
        final foreign = goals.byId['g-foreign']!;
        expect(foreign.contract, isNull);
        expect(foreign.workspaceId, 'ws-2');
        expect(goals.replaceIfCalls, isEmpty);
      });
    }
  });

  group('dispatch.guidedGoalStep', () {
    test('a question passes through; nothing is added', () async {
      guided.next = const GuidedGoalStepResult(
        question: 'What does done mean?',
        missing: ['success'],
      );
      final result = await call('dispatch.guidedGoalStep', {
        'rough': 'fix the tests',
        'transcript': ['a', 'b'],
      });
      expect(result['question'], 'What does done mean?');
      expect(result['missing'], ['success']);
      expect(result.containsKey('objective'), isFalse);
      expect(guided.calls.single, ('ws-1', 'user-1', 'fix the tests', 2));
    });

    test('a ready objective carries the checks and the checker into the '
        '/goal text and the contract', () async {
      guided.next = const GuidedGoalStepResult(
        objective:
            '## Objective\nFix it.\n\n## Success criteria\n- Tests pass\n\n'
            '## Verification\nRun them.',
      );
      final result = await call('dispatch.guidedGoalStep', {
        'rough': 'fix it',
        'checks': [
          {'run': 'make test', 'in': 'worktree', 'timeoutSeconds': 600},
          {'run': 'smoke', 'in': 'environment'},
        ],
        'checker_agent_id': 'agent-2',
        'agent_id': 'agent-1',
      });
      expect(
        result['objective'],
        '## Objective\nFix it.\n\n## Success criteria\n- Tests pass\n\n'
        '## Verification\nRun them.\n\n'
        '## Checks\n- `make test` (600 s)\n- environment task `smoke` (300 s)'
        '\n\n--checker agent-2',
      );
      expect(result['contract'], {
        'criteria': ['Tests pass'],
        'checks': [
          {'run': 'make test', 'in': 'worktree', 'timeoutSeconds': 600},
          {'run': 'smoke', 'in': 'environment', 'timeoutSeconds': 300},
        ],
      });
      expect(result['checker_agent_id'], 'agent-2');
    });

    test('a goal with no checks still gets an objective', () async {
      guided.next = const GuidedGoalStepResult(
        objective: '## Objective\nFix it.',
      );
      final result = await call('dispatch.guidedGoalStep', {'rough': 'x'});
      expect(result['objective'], '## Objective\nFix it.');
      expect(result.containsKey('contract'), isFalse);
    });

    test('checks and checker are validated before the model call', () async {
      expect(
        () => call('dispatch.guidedGoalStep', {
          'rough': 'x',
          'checks': [
            for (var i = 0; i < 6; i++) {'run': 'c$i', 'in': 'worktree'},
          ],
        }),
        refused(goalContractInvalidKind),
      );
      expect(
        () => call('dispatch.guidedGoalStep', {
          'rough': 'x',
          'checks': [
            {'run': 'c', 'in': 'moon'},
          ],
        }),
        refused(goalContractInvalidKind),
      );
      expect(
        () => call('dispatch.guidedGoalStep', {
          'rough': 'x',
          'checker_agent_id': 'agent-x',
        }),
        refused(goalCheckerUnknownKind),
      );
      expect(
        () => call('dispatch.guidedGoalStep', {
          'rough': 'x',
          'checker_agent_id': 'agent-1',
          'agent_id': 'agent-1',
        }),
        refused(goalCheckerIsGoalAgentKind),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guided.calls, isEmpty);
    });
  });
}

Agent _agent(String id, String name, {String workspaceId = 'ws-1'}) => Agent(
  id: id,
  name: name,
  title: name,
  agentMdPath: '/agents/$id.md',
  workspaceId: workspaceId,
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2026),
);

AgentGoalRun _goal(
  String id, {
  String workspaceId = 'ws-1',
  AgentGoalStatus status = AgentGoalStatus.paused,
  String? requester = 'user-1',
}) => AgentGoalRun(
  id: id,
  workspaceId: workspaceId,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Fix it',
  costCapMicros: 50000000,
  status: status,
  requestedByUserId: requester,
  activeRunId: 'run-1',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _Goals implements AgentGoalRunRepository {
  final Map<String, AgentGoalRun> byId = {};
  final List<AgentGoalRun> replaceIfCalls = [];
  bool loseNextRace = false;

  void put(AgentGoalRun goal) => byId[goal.id] = goal;

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final goal = byId[id];
    return goal != null && goal.workspaceId == workspaceId ? goal : null;
  }

  @override
  Future<bool> replaceIf(
    AgentGoalRun next, {
    required AgentGoalRun expected,
  }) async {
    replaceIfCalls.add(expected);
    if (loseNextRace) {
      loseNextRace = false;
      return false;
    }
    final stored = byId[next.id];
    if (stored == null || stored != expected) {
      return false;
    }
    byId[next.id] = next;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  _Agents(this.all);

  final List<Agent> all;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([
    for (final a in all)
      if (a.workspaceId == workspaceId) a,
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Guided implements MessagingPort {
  GuidedGoalStepResult next = const GuidedGoalStepResult();
  final List<(String, String?, String, int)> calls = [];

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
    String? requestedByUserId,
  }) async {
    calls.add((workspaceId, requestedByUserId, rough, transcript.length));
    return next;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
