import 'package:cc_domain/cc_domain.dart' show ImprovementRefusedException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_turn_text_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/improvement_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/improvement_review_service.dart';
import 'package:cc_infra/src/dispatch/improvement_review_turn_texts.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/messaging/person_goal_command.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart';

const _ws = 'ws-1';
const _other = 'ws-2';

final _t0 = DateTime.utc(2026, 11, 19, 14);

Wake _reviewWake({required String dedupKey}) => Wake(
  id: 'w-waiting',
  workspaceId: _ws,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  reason: WakeReason.improvementReview,
  payload: 'waiting',
  dedupKey: dedupKey,
  notBefore: _t0,
  createdAt: _t0,
);

class _Queue implements WakeQueueService {
  _Queue(this.repo);
  final FakeWakeRepository repo;
  final List<Wake> enqueued = [];

  @override
  Future<bool> enqueue(Wake wake) async {
    if (!await repo.insertIfAbsent(wake)) {
      return false;
    }
    enqueued.add(wake);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Goals implements AgentGoalRunRepository {
  final Map<String, AgentGoalRun> byId = {};

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final g = byId[id];
    return g?.workspaceId == workspaceId ? g : null;
  }

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async => [
    for (final g in byId.values)
      if (g.workspaceId == workspaceId) g,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Agents implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == _ws && id == 'agent-1'
      ? Agent(
          id: 'agent-1',
          name: 'builder',
          title: 'Builder',
          agentMdPath: 'agents/builder.md',
          workspaceId: _ws,
          skills: AgentSkills(const []),
          createdAt: _t0,
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _RunLogs implements AgentRunLogRepository {
  final Map<String, AgentRunLog> byId = {};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final r = byId[id];
    return r?.workspaceId == workspaceId ? r : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Messages implements MessagingRepository {
  final Map<String, Message> byId = {};

  /// Messages stored in another workspace's database.
  final Map<String, Message> elsewhere = {};

  @override
  Future<Message?> getMessageById(String workspaceId, String id) async =>
      workspaceId == _ws ? byId[id] : elsewhere[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => workspaceId == _ws && conversationId == 'conv-1'
      ? Conversation(
          id: 'conv-1',
          workspaceId: _ws,
          spaceId: 'space-1',
          title: 'Main',
          createdAt: _t0,
          updatedAt: _t0,
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Facts implements MemoryFactRepository {
  final Map<String, MemoryFact> byId = {};

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async {
    final f = byId[id];
    return f?.workspaceId == workspaceId ? f : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Policies implements MemoryPolicyRepository {
  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// The proposals, in memory.
class _Proposals implements ImprovementProposalRepository {
  final Map<String, ImprovementProposal> byId = {};

  @override
  Future<void> insert(ImprovementProposal p) async => byId[p.id] = p;

  @override
  Future<List<ImprovementProposal>> listByGoal(
    String ws,
    String goalId,
  ) async => [
    for (final p in byId.values)
      if (p.workspaceId == ws && p.goalId == goalId) p,
  ];

  @override
  Future<ImprovementProposal?> latestForConversation(
    String ws,
    String conversationId,
  ) async => ([
    for (final p in byId.values)
      if (p.workspaceId == ws && p.conversationId == conversationId) p,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt))).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

AgentGoalRun _goal({
  String id = 'goal-1',
  String workspaceId = _ws,
  AgentGoalStatus status = AgentGoalStatus.completed,
  GoalVerdictOutcome verdict = GoalVerdictOutcome.pass,
  String? approvedBy,
}) =>
    AgentGoalRun(
      id: id,
      workspaceId: workspaceId,
      spaceId: 'space-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      userText: 'Make the build green',
      costCapMicros: 5000000,
      requestedByUserId: 'user-1',
      createdAt: _t0,
      updatedAt: _t0,
    ).copyWith(
      status: status,
      verification: GoalVerification(
        round: 1,
        claimSummary: 'done',
        checks: [
          GoalCheckResult(
            run: 'make test',
            where: GoalCheckLocation.worktree,
            exitCode: 0,
          ),
        ],
        verdict: GoalVerdict(verdict: verdict),
        reviewerAgentId: 'checker',
        reviewRunId: 'run-r',
        fingerprint: 'fp',
        at: _t0,
        approvedByUserId: approvedBy,
      ),
    );

GoalSettled _settled(AgentGoalRun goal) => GoalSettled(
  goalId: goal.id,
  workspaceId: goal.workspaceId,
  spaceId: goal.spaceId,
  conversationId: goal.conversationId,
  agentId: goal.agentId,
  status: goal.status,
  hold: null,
  summary: 'done',
  requestedByUserId: goal.requestedByUserId,
  occurredAt: _t0,
);

class _Kit {
  _Kit() {
    service = ImprovementReviewService(
      wakeQueue: () => queue,
      wakes: wakes,
      goals: goals,
      agents: _Agents(),
      runLogs: runLogs,
      proposals: proposals,
      messages: messages,
      conversations: _Conversations(),
      facts: facts,
      policies: _Policies(),
      resolveRepository: (ws, spaceId, reference) async =>
          ws == _ws && reference == 'acme/shop-ui' ? 'repo-1' : null,
      skillExists: (ws, slug) async => slug == 'lint',
      eventBus: bus,
      now: () => now,
      newId: () => 'p-${++_ids}',
    );
    bus.on<ImprovementProposed>().listen(published.add);
  }

  final wakes = FakeWakeRepository();
  late final _Queue queue = _Queue(wakes);
  final goals = _Goals();
  final runLogs = _RunLogs();
  final proposals = _Proposals();
  final messages = _Messages();
  final facts = _Facts();
  final bus = DomainEventBus();
  final List<ImprovementProposed> published = [];
  DateTime now = _t0;
  int _ids = 0;
  late final ImprovementReviewService service;

  /// The review run [runId] that delivered [wake] and answered [output].
  AgentRunSettled settle(
    Wake wake,
    String runId,
    Object? output, {
    RunEndReason end = RunEndReason.completed,
    RunStatus status = RunStatus.completed,
    String workspaceId = _ws,
  }) {
    runLogs.byId[runId] = AgentRunLog(
      id: runId,
      agentId: wake.agentId,
      workspaceId: workspaceId,
      spaceId: wake.spaceId,
      conversationId: wake.conversationId,
      startedAt: now,
      status: status,
      outputJson: output as Map<String, dynamic>?,
      wakeReason: WakeReason.improvementReview,
    );
    return AgentRunSettled(
      agentId: wake.agentId,
      workspaceId: workspaceId,
      spaceId: wake.spaceId,
      conversationId: wake.conversationId,
      runId: runId,
      status: status,
      endReason: end,
      costMicros: 1000,
      limitResetsAt: null,
      wakeIds: [wake.id],
      requestedByUserId: wake.requestedByUserId,
      wakeReason: WakeReason.improvementReview,
      occurredAt: now,
    );
  }
}

Message _message(String id, {String conversationId = 'conv-1'}) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: conversationId,
  senderId: 'user-1',
  senderType: SenderType.user,
  content: 'no, run make gen first',
  messageType: MessageType.text,
  createdAt: _t0,
);

Map<String, Object?> _answer(List<Map<String, Object?>> proposals) => {
  'proposals': proposals,
};

Map<String, Object?> _fact({
  List<String> messageIds = const ['m-1'],
  List<String> checks = const [],
}) => {
  'kind': 'memory_fact',
  'scope': 'workspace',
  'operation': 'add',
  'target': 'build',
  'change': 'Run make gen before make test.',
  'evidence': {'messageIds': messageIds, 'checks': checks},
  'expected': 'The first build passes.',
};

void main() {
  group('when a review starts', () {
    test(
      'a verified goal produces one read-only, fresh, capped review',
      () async {
        final kit = _Kit();
        final goal = _goal();
        kit.goals.byId[goal.id] = goal;
        expect(await kit.service.onGoalSettled(_settled(goal)), isTrue);
        final wake = kit.queue.enqueued.single;
        expect(wake.reason, WakeReason.improvementReview);
        expect(wake.agentId, 'agent-1');
        expect(wake.conversationId, 'conv-1');
        expect(wake.requestedByUserId, 'user-1');
        // The goal rides in a field, never as the wake's goal: the goal
        // supervisor skips a wake of a goal that ended.
        expect(wake.detail.goalId, isNull);
        expect(wake.detail.fields[kImprovementGoalField], 'goal-1');
        final options = wake.runOptions!;
        expect(options.readOnly, isTrue);
        expect(options.freshHistory, isTrue);
        expect(options.costCapMicros, 1000000);
        expect(improvementReviewCapMicros, 1000000);
        expect(options.outputSchema, improvementReviewOutputSchema);

        // The run the queue starts for it is read-only and fresh: the
        // read-only profile then offers only reads and `submit_output`
        // (no message, wake, memory or skill write, no subagent), and a
        // read-only run's turn wakes no one.
        final request = WakeDispatchRequest.forWakes([
          wake,
        ], wakeContext: WakeContext.fromWakes([wake], nonce: 'n0abc1'));
        expect(request.readOnly, isTrue);
        expect(request.freshHistory, isTrue);
        expect(request.costCapMicros, improvementReviewCapMicros);
        expect(request.expectedOutputSchema, improvementReviewOutputSchema);
        for (final changer in [
          'send_message',
          'wake_me',
          'ask_user',
          'task',
          'propose_fact',
          'propose_policy',
          'update_my_notes',
          'remember',
        ]) {
          expect(
            ReadOnlyRunProfile.admits(changer, const {}),
            isFalse,
            reason: changer,
          );
        }
        for (final read in ['submit_output', 'get_messages', 'read']) {
          expect(ReadOnlyRunProfile.admits(read, const {}), isTrue);
        }

        // One review per goal.
        kit.now = kit.now.add(const Duration(hours: 2));
        expect(await kit.service.onGoalSettled(_settled(goal)), isFalse);
        expect(kit.queue.enqueued, hasLength(1));
      },
    );

    test(
      'a goal closed by a person, failed or not passed produces none',
      () async {
        for (final goal in [
          _goal(approvedBy: 'user-1'),
          _goal(status: AgentGoalStatus.failed),
          _goal(status: AgentGoalStatus.paused),
          _goal(verdict: GoalVerdictOutcome.fail),
        ]) {
          final kit = _Kit();
          kit.goals.byId[goal.id] = goal;
          expect(await kit.service.onGoalSettled(_settled(goal)), isFalse);
          expect(kit.queue.enqueued, isEmpty);
        }
      },
    );

    test('never for an agent that is not a workspace agent', () async {
      final kit = _Kit();
      final goal = _goal().copyWith(agentId: 'sub-1');
      kit.goals.byId[goal.id] = goal;
      expect(await kit.service.onGoalSettled(_settled(goal)), isFalse);
      await expectLater(
        kit.service.refine(
          workspaceId: _ws,
          spaceId: 'space-1',
          conversationId: 'conv-1',
          agentId: 'sub-1',
          requestedByUserId: 'user-1',
        ),
        throwsA(
          isA<ImprovementRefusedException>().having(
            (e) => e.code,
            'kind',
            ImprovementRefusedException.agentNotFoundKind,
          ),
        ),
      );
      expect(kit.queue.enqueued, isEmpty);
    });

    test(
      '/refine with a review already waiting (after a restart) says so',
      () async {
        final kit = _Kit();
        final window =
            kit.now.millisecondsSinceEpoch ~/
            improvementReviewCooldown.inMilliseconds;
        await kit.queue.repo.insertIfAbsent(
          _reviewWake(dedupKey: 'improve:refine:conv-1:$window'),
        );
        await expectLater(
          kit.service.refine(
            workspaceId: _ws,
            spaceId: 'space-1',
            conversationId: 'conv-1',
            agentId: 'agent-1',
            requestedByUserId: 'user-2',
          ),
          throwsA(
            isA<ImprovementRefusedException>().having(
              (e) => e.code,
              'kind',
              ImprovementRefusedException.reviewQueuedKind,
            ),
          ),
        );
      },
    );

    test('a goal of another workspace is not read', () async {
      final kit = _Kit();
      final goal = _goal(workspaceId: _other);
      kit.goals.byId[goal.id] = goal;
      expect(
        await kit.service.onGoalSettled(
          GoalSettled(
            goalId: goal.id,
            workspaceId: _ws,
            spaceId: 'space-1',
            conversationId: 'conv-1',
            agentId: 'agent-1',
            status: AgentGoalStatus.completed,
            hold: null,
            summary: null,
            requestedByUserId: null,
            occurredAt: _t0,
          ),
        ),
        isFalse,
      );
    });

    test('/refine follows the latest verified goal, then cools down', () async {
      final kit = _Kit();
      kit.goals.byId['goal-1'] = _goal();
      await kit.service.refine(
        workspaceId: _ws,
        spaceId: 'space-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        requestedByUserId: 'user-2',
      );
      final wake = kit.queue.enqueued.single;
      expect(wake.detail.fields[kImprovementGoalField], 'goal-1');
      expect(wake.requestedByUserId, 'user-2');

      kit.now = kit.now.add(const Duration(minutes: 19));
      await expectLater(
        kit.service.refine(
          workspaceId: _ws,
          spaceId: 'space-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          requestedByUserId: 'user-2',
        ),
        throwsA(
          isA<ImprovementRefusedException>().having(
            (e) => e.code,
            'kind',
            ImprovementRefusedException.cooldownKind,
          ),
        ),
      );
      kit.now = kit.now.add(const Duration(minutes: 2));
      await kit.service.refine(
        workspaceId: _ws,
        spaceId: 'space-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        requestedByUserId: 'user-2',
      );
      expect(kit.queue.enqueued, hasLength(2));
    });
  });

  group('when the review answers', () {
    Future<(_Kit, Wake)> reviewed() async {
      final kit = _Kit();
      kit.goals.byId['goal-1'] = _goal();
      await kit.service.onGoalSettled(_settled(_goal()));
      kit.messages.byId['m-1'] = _message('m-1');
      kit.messages.byId['m-elsewhere'] = _message(
        'm-elsewhere',
        conversationId: 'conv-9',
      );
      return (kit, kit.queue.enqueued.single);
    }

    test('writes resolved proposals and tells the person once', () async {
      final (kit, wake) = await reviewed();
      final written = await kit.service.onRunSettled(
        kit.settle(
          wake,
          'run-1',
          _answer([
            _fact(checks: const ['make test', 'rm -rf /']),
            // Evidence from another conversation does not count.
            _fact(messageIds: const ['m-elsewhere']),
            {..._fact(), 'scope': 'repository', 'repository': 'acme/shop-ui'},
            _fact(),
          ]),
        ),
      );
      expect(written, 2, reason: 'one unresolved, one past the third');
      final rows = kit.proposals.byId.values.toList();
      expect(rows.first.evidence.messageIds, ['m-1']);
      expect(rows.first.evidence.checkResults.map((c) => c.run), ['make test']);
      expect(rows.first.goalId, 'goal-1');
      expect(rows.first.reviewRunId, 'run-1');
      expect(rows.first.spaceId, 'space-1');
      expect(rows.first.status, ImprovementStatus.proposed);
      expect(rows.first.expiresAt, _t0.add(const Duration(days: 30)));
      expect(rows.last.scope, ImprovementScope.repository);
      expect(rows.last.scopeRefId, 'repo-1');
      await Future<void>.delayed(Duration.zero);
      expect(kit.published.single.proposalIds, [for (final r in rows) r.id]);
      expect(kit.published.single.requestedByUserId, 'user-1');
    });

    test('a server stop or a failed run writes nothing', () async {
      final (kit, wake) = await reviewed();
      for (final (end, status) in [
        (RunEndReason.serverStopped, RunStatus.error),
        (RunEndReason.error, RunStatus.error),
      ]) {
        expect(
          await kit.service.onRunSettled(
            kit.settle(
              wake,
              'run-x',
              _answer([_fact()]),
              end: end,
              status: status,
            ),
          ),
          0,
        );
      }
      expect(kit.proposals.byId, isEmpty);
    });

    test("another workspace's run cannot claim the wake", () async {
      final (kit, wake) = await reviewed();
      expect(
        await kit.service.onRunSettled(
          kit.settle(wake, 'run-2', _answer([_fact()]), workspaceId: _other),
        ),
        0,
      );
      expect(kit.proposals.byId, isEmpty);
    });

    test('ids of another workspace or of a space the review cannot read '
        'never count as evidence or target', () async {
      final (kit, wake) = await reviewed();
      // Another space of the workspace: its own conversation.
      kit.messages.byId['m-space-2'] = _message(
        'm-space-2',
        conversationId: 'conv-space-2',
      );
      kit.runLogs.byId['run-space-2'] = AgentRunLog(
        id: 'run-space-2',
        agentId: 'agent-1',
        workspaceId: _ws,
        spaceId: 'space-2',
        conversationId: 'conv-space-2',
        startedAt: _t0,
        status: RunStatus.completed,
      );
      // Another workspace, with this conversation's ids.
      kit.messages.elsewhere['m-ws-2'] = _message('m-ws-2');
      kit.runLogs.byId['run-ws-2'] = AgentRunLog(
        id: 'run-ws-2',
        agentId: 'agent-1',
        workspaceId: 'ws-2',
        spaceId: 'space-1',
        conversationId: 'conv-1',
        startedAt: _t0,
        status: RunStatus.completed,
      );
      kit.facts.byId['f-ws-2'] = MemoryFact(
        id: 'f-ws-2',
        workspaceId: 'ws-2',
        domain: 'lessons',
        topic: 'build',
        content: 'theirs',
        sourceObservationIds: const [],
        createdAt: _t0,
        updatedAt: _t0,
      );
      Map<String, Object?> citing({
        List<String> messageIds = const [],
        List<String> runIds = const [],
      }) => {
        ..._fact(),
        'evidence': {'messageIds': messageIds, 'runIds': runIds},
      };
      expect(
        await kit.service.onRunSettled(
          kit.settle(
            wake,
            'run-5',
            _answer([
              citing(messageIds: ['m-space-2'], runIds: ['run-space-2']),
              citing(messageIds: ['m-ws-2'], runIds: ['run-ws-2']),
              {..._fact(), 'operation': 'replace', 'target': 'f-ws-2'},
            ]),
          ),
        ),
        0,
      );
      expect(kit.proposals.byId, isEmpty);
      expect(kit.published, isEmpty);
    });

    test('a skill proposal must name a skill that exists (or not)', () async {
      final (kit, wake) = await reviewed();
      Map<String, Object?> skill(String kind, String name) => {
        ..._fact(),
        'kind': kind,
        'skill': name,
        'target': null,
      };
      expect(
        await kit.service.onRunSettled(
          kit.settle(
            wake,
            'run-3',
            _answer([
              skill('skill_edit', 'missing'),
              skill('skill_new', 'lint'),
              skill('skill_new', 'fresh-skill'),
            ]),
          ),
        ),
        1,
      );
      expect(kit.proposals.byId.values.single.scopeRefId, 'fresh-skill');
    });

    test('a replace must name a live fact', () async {
      final (kit, wake) = await reviewed();
      kit.facts.byId['f-old'] = MemoryFact(
        id: 'f-old',
        workspaceId: _ws,
        domain: 'lessons',
        topic: 'build',
        content: 'old',
        sourceObservationIds: const [],
        createdAt: _t0,
        updatedAt: _t0,
      );
      expect(
        await kit.service.onRunSettled(
          kit.settle(
            wake,
            'run-4',
            _answer([
              {..._fact(), 'operation': 'replace', 'target': 'f-missing'},
              {..._fact(), 'operation': 'replace', 'target': 'f-old'},
            ]),
          ),
        ),
        1,
      );
      expect(kit.proposals.byId.values.single.targetRef, 'f-old');
    });
  });

  group('the review run text', () {
    final kit = _Kit();
    final turnTexts = ImprovementReviewTurnTexts(
      goals: _GoalTexts(),
      goalRows: kit.goals,
    );
    Wake wake({String conversationId = 'conv-1'}) => Wake(
      id: 'w-1',
      workspaceId: _ws,
      spaceId: 'space-1',
      conversationId: conversationId,
      agentId: 'agent-1',
      reason: WakeReason.improvementReview,
      payload: 'ignored',
      dedupKey: 'k',
      notBefore: _t0,
      createdAt: _t0,
    );

    test('a review run gets the review prompt', () async {
      final text = await turnTexts.forRun(
        workspaceId: _ws,
        agentId: 'agent-1',
        conversationId: 'conv-1',
        wakeContext: WakeContext.fromWakes([wake()], nonce: 'abcde1'),
        hasRepl: true,
      );
      expect(text!.section, startsWith(improvementReviewHeading));
      expect(text.section, contains('No verified goal is attached'));
    });

    test(
      'a review aimed elsewhere gets nothing; other runs the goal text',
      () async {
        expect(
          await turnTexts.forRun(
            workspaceId: _ws,
            agentId: 'agent-2',
            conversationId: 'conv-1',
            wakeContext: WakeContext.fromWakes([wake()], nonce: 'abcde1'),
            hasRepl: true,
          ),
          isNull,
        );
        final other = await turnTexts.forRun(
          workspaceId: _ws,
          agentId: 'agent-1',
          conversationId: 'conv-1',
          wakeContext: const WakeContext.userMessage(),
          hasRepl: true,
        );
        expect(other!.section, 'goal text');
      },
    );
  });

  group('/refine as a person command', () {
    test('is recognised like /goal and routed to its handler', () async {
      expect(isRefineCommand('/refine'), isTrue);
      expect(isRefineCommand('  /refine the tests'), isTrue);
      expect(isRefineCommand('/refined'), isFalse);
      expect(isRefineCommand('please /refine'), isFalse);
      expect(isPersonCommand('/refine'), isTrue);

      final calls = <String>[];
      PersonGoalCommand handler(String name) =>
          ({
            required workspaceId,
            required spaceId,
            required agentId,
            required prompt,
            required requestedByUserId,
            conversationId,
          }) async {
            calls.add(name);
            return null;
          };
      final command = personCommands(
        goals: handler('goal'),
        wakeRules: handler('wakeRules'),
        refine: handler('refine'),
      );
      for (final prompt in ['/refine', '/goal ship it']) {
        await command(
          workspaceId: _ws,
          spaceId: 'space-1',
          agentId: 'agent-1',
          prompt: prompt,
          requestedByUserId: 'user-1',
        );
      }
      expect(calls, ['refine', 'goal']);
    });
  });
}

class _GoalTexts implements GoalTurnTextPort {
  @override
  Future<GoalTurnText?> forRun({
    required String workspaceId,
    required String agentId,
    required String? conversationId,
    required WakeContext wakeContext,
    required bool hasRepl,
  }) async => GoalTurnText(section: 'goal text');
}
