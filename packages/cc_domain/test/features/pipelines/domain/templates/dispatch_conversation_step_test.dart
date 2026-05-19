import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show kPipelineSpaceStateKey;
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart';
import 'package:test/test.dart';

class _FakeMessagingPort implements MessagingPort {
  _FakeMessagingPort({this.existingSpaces = const {}, this.onSpaceExists});

  /// Space ids `spaceExists` reports as live.
  final Set<String> existingSpaces;

  /// Fired inside [spaceExists] — the first port call the body makes after
  /// registering its kill hook — so a test can stop the step mid-resolution.
  final void Function()? onSpaceExists;

  /// Spaces the step asked to stop provisioning.
  final List<String> cancelledProvisioning = [];

  final List<String> createdSpaces = [];
  final List<({String spaceId, String agentId})> addedAgents = [];
  final List<bool> addRenameFlags = [];
  final List<({String spaceId, String content, String? conversationId})>
  userMessages = [];
  final List<({String spaceId, String agentId, String? conversationId})>
  dispatched = [];
  Mode? createdWithMode;

  /// Conversations opened inside an existing space, in order.
  final List<({String spaceId, String title, String? owner})>
  createdConversations = [];

  /// The repo scope each created space was given (empty = all repos).
  final List<List<String>?> createdWithRepoIds = [];

  /// Every workspace id the port was called with, so a test can assert the step
  /// threads ONE workspace through the whole conversation setup rather than
  /// mixing (which, against real databases, would write to two files).
  final Set<String> seenWorkspaceIds = {};

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async {
    seenWorkspaceIds.add(workspaceId);
    onSpaceExists?.call();
    return existingSpaces.contains(spaceId);
  }

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    createdSpaces.add(name);
    createdWithMode = mode;
    createdWithRepoIds.add(repoIds);
    return Space(
      id: 'hidden-${createdSpaces.length}',
      name: name,
      workspaceId: workspaceId,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    addedAgents.add((spaceId: spaceId, agentId: agentId));
    addRenameFlags.add(renameForGroup);
  }

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    userMessages.add((
      spaceId: spaceId,
      content: content,
      conversationId: conversationId,
    ));
  }

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    if (!existingSpaces.contains(spaceId)) {
      return null;
    }
    if (reuseExisting) {
      for (var i = 0; i < createdConversations.length; i++) {
        final c = createdConversations[i];
        if (c.spaceId == spaceId && c.title == title) {
          return 'conv-${i + 1}';
        }
      }
    }
    createdConversations.add((
      spaceId: spaceId,
      title: title,
      owner: createdByPrincipalId,
    ));
    return 'conv-${createdConversations.length}';
  }

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    dispatched.add((
      spaceId: spaceId,
      agentId: agentId,
      conversationId: conversationId,
    ));
    return 'run-${dispatched.length}';
  }

  @override
  Future<void> cancelSpaceProvisioning(
    String workspaceId,
    String spaceId,
  ) async {
    seenWorkspaceIds.add(workspaceId);
    cancelledProvisioning.add(spaceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  /// Agents this port was asked to stop.
  final List<String> stopped = [];

  @override
  Future<void> stopAllForAgent(String agentId) async => stopped.add(agentId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeRunRepository implements PipelineRunRepository {
  _FakeRunRepository({Map<String, PipelineStepRun>? rows})
    : _rows = rows ?? {};

  final List<({String stepRunId, String? spaceId})> linked = [];

  /// Step-run rows by id — what a re-fired body reads back to find the room a
  /// previous attempt already opened.
  final Map<String, PipelineStepRun> _rows;

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    Object? status,
    String? inputJson,
    String? outputJson,
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    linked.add((stepRunId: stepRunId, spaceId: spaceId));
    if (spaceId != null) {
      final current = _rows[stepRunId];
      _rows[stepRunId] = PipelineStepRun(
        id: stepRunId,
        pipelineRunId: current?.pipelineRunId ?? 'run-1',
        stepId: current?.stepId ?? 'step',
        status: PipelineStepStatus.running,
        spaceId: spaceId,
        startedAt: current?.startedAt ?? DateTime(2026),
      );
    }
  }

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async => _rows[stepRunId];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

const _ctx = PipelineContext(
  pipelineRunId: 'run-1',
  templateId: 'orchestration_plan_p1',
  stepId: 'sub_a',
  stepRunId: 'steprun-1',
  workspaceId: 'ws-1',
  state: {},
);

void main() {
  group('dispatchConversationStep — where the work lands', () {
    test(
      'runs in the configured conversation instead of a hidden one',
      () async {
        final messaging = _FakeMessagingPort(existingSpaces: {'chan-plan'});
        final runs = _FakeRunRepository();

        final result = await dispatchConversationStep(
          ctx: _ctx,
          messagingPort: messaging,
          agentDispatchPort: _FakeAgentDispatchPort(),
          stepProcessRegistry: StepProcessRegistry(),
          runRepository: runs,
          agentIds: ['agent-1'],
          prompt: 'Do the work',
          label: 'Step one',
          spaceId: 'chan-plan',
        );

        expect(
          messaging.createdSpaces,
          isEmpty,
          reason:
              'the plan\'s room must be reused, not shadowed by a hidden one',
        );
        expect(messaging.userMessages.single.spaceId, 'chan-plan');
        expect(messaging.dispatched.single.spaceId, 'chan-plan');
        // The agent joins the room's roster (so the space sidebar shows it),
        // without renaming the operator's conversation; the step-run links back.
        expect(messaging.addedAgents.single, (
          spaceId: 'chan-plan',
          agentId: 'agent-1',
        ));
        expect(messaging.addRenameFlags, [false]);
        expect(runs.linked.single.spaceId, 'chan-plan');
        expect(result.suspendUntilTaskIds, ['run-1']);
      },
    );

    test('a re-fired step continues in the room it already opened', () async {
      // A crash-resume and a retry both re-invoke the body on the SAME step-run
      // row. Creating a second hidden room there clones every repo again and
      // leaves the agent working somewhere the operator is not looking.
      final messaging = _FakeMessagingPort(existingSpaces: {'space-hidden-1'});
      final runs = _FakeRunRepository(
        rows: {
          'steprun-1': PipelineStepRun(
            id: 'steprun-1',
            pipelineRunId: 'run-1',
            stepId: 'sub_a',
            status: PipelineStepStatus.running,
            spaceId: 'space-hidden-1',
            startedAt: DateTime(2026),
          ),
        },
      );

      await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: runs,
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        label: 'Step one',
      );

      expect(messaging.createdSpaces, isEmpty);
      expect(messaging.dispatched.single.spaceId, 'space-hidden-1');
    });

    test('a re-fired titled step reuses its stream, not a second one', () async {
      final messaging = _FakeMessagingPort(existingSpaces: {'space-pr-42'});
      final runs = _FakeRunRepository();

      Future<void> attempt() => dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: runs,
        agentIds: ['agent-1'],
        prompt: 'Review it',
        label: 'QA review',
        spaceId: 'space-pr-42',
        conversationTitle: 'QA review',
      );

      await attempt();
      await attempt();

      expect(
        messaging.createdConversations,
        hasLength(1),
        reason:
            'two "QA review" threads in one room leave nobody able to tell '
            'which one the live agent is in',
      );
      expect(
        messaging.dispatched.map((d) => d.conversationId),
        ['conv-1', 'conv-1'],
      );
    });

    test('resolves a {{key}} space reference from pipeline state', () async {
      // The PR-review template's reviewers name the room its first step
      // ensured. Without rendering, the step would look for a space literally
      // called `{{review_space_id}}`, find none, and mint a hidden room — which
      // is what made three reviewers clone the whole workspace three times.
      final messaging = _FakeMessagingPort(existingSpaces: {'space-pr-42'});

      await dispatchConversationStep(
        ctx: const PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'pr_review',
          stepId: 'qa_review',
          stepRunId: 'steprun-1',
          workspaceId: 'ws-1',
          state: {'review_space_id': 'space-pr-42'},
        ),
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Review it',
        label: 'QA review',
        spaceId: '{{review_space_id}}',
      );

      expect(messaging.createdSpaces, isEmpty);
      expect(messaging.dispatched.single.spaceId, 'space-pr-42');
    });

    test('a titled step opens its own stream in the shared space', () async {
      final messaging = _FakeMessagingPort(existingSpaces: {'space-pr-42'});

      await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Review it',
        label: 'QA review',
        spaceId: 'space-pr-42',
        conversationTitle: 'QA review',
      );

      expect(messaging.createdConversations.single, (
        spaceId: 'space-pr-42',
        title: 'QA review',
        // A one-agent step owns its stream, so a later human reply in it wakes
        // that agent rather than the space roster's first entry.
        owner: 'agent-1',
      ));
      // Both the seed message and the run must land in THAT stream — a seed
      // in the standing conversation and a run in the new one would split
      // the thread the reader is watching.
      expect(messaging.userMessages.single.conversationId, 'conv-1');
      expect(messaging.dispatched.single.conversationId, 'conv-1');
      expect(
        messaging.createdSpaces,
        isEmpty,
        reason: 'a named stream shares the space, it does not mint one',
      );
    });

    test(
      'an untitled step keeps writing to the standing conversation',
      () async {
        final messaging = _FakeMessagingPort(existingSpaces: {'chan-plan'});

        await dispatchConversationStep(
          ctx: _ctx,
          messagingPort: messaging,
          agentDispatchPort: _FakeAgentDispatchPort(),
          stepProcessRegistry: StepProcessRegistry(),
          runRepository: _FakeRunRepository(),
          agentIds: ['agent-1'],
          prompt: 'Do the work',
          label: 'Step one',
          spaceId: 'chan-plan',
        );

        expect(messaging.createdConversations, isEmpty);
        expect(messaging.userMessages.single.conversationId, isNull);
        expect(messaging.dispatched.single.conversationId, isNull);
      },
    );

    test('fails when no conversation resolves', () async {
      // A room is a repo checkout. Opening one here would make the checkout a
      // side effect of dispatching an agent, and parallel steps all reach this
      // point before any of them has a room — so a fan-out would provision the
      // workspace once per branch. The template names the room, once, in a node
      // the author can see.
      final messaging = _FakeMessagingPort();

      final result = await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        label: 'Step one',
      );

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('no conversation to work in'));
      expect(result.errorMessage, contains('messaging.createSpace'));
      expect(messaging.createdSpaces, isEmpty);
      expect(messaging.dispatched, isEmpty);
    });

    test('fails when the configured room is gone', () async {
      // The operator deleted the room after the plan was authored. Silently
      // opening a replacement hands the agent a different checkout than the one
      // the template meant; saying so is the honest outcome.
      final messaging = _FakeMessagingPort();

      final result = await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        spaceId: 'chan-deleted',
      );

      expect(result.isFailed, isTrue);
      expect(messaging.createdSpaces, isEmpty);
      expect(messaging.dispatched, isEmpty);
    });
  });

  group('dispatchConversationStep — one room per run', () {
    // A room is a checkout. Every agent step of a run joins the SAME room —
    // opened once by a `messaging.createSpace` node — so a five-agent template
    // provisions one copy of the repos rather than five.
    test('a later step joins that room instead of opening another', () async {
      final messaging = _FakeMessagingPort(existingSpaces: {'space-run-1'});

      final result = await dispatchConversationStep(
        ctx: const PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'ad_hoc',
          stepId: 'reviewer_b',
          stepRunId: 'steprun-2',
          workspaceId: 'ws-1',
          state: {kPipelineSpaceStateKey: 'space-run-1'},
        ),
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-2'],
        prompt: 'Review it',
        label: 'Reviewer B',
      );

      expect(
        messaging.createdSpaces,
        isEmpty,
        reason: 'the run already has a room; a second one is a second checkout',
      );
      expect(messaging.dispatched.single.spaceId, 'space-run-1');
      // Sharing the room must not merge every agent's turns into one thread:
      // a step that did not declare a title gets one named after itself.
      expect(messaging.createdConversations.single.title, 'Reviewer B');
      // Only the step that opens the room publishes it.
      expect(result.mutatedState?[kPipelineSpaceStateKey], isNull);
    });

    test('a node that names its own room still wins', () async {
      final messaging = _FakeMessagingPort(
        existingSpaces: {'chan-plan', 'space-run-1'},
      );

      await dispatchConversationStep(
        ctx: const PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'orchestration_plan_p1',
          stepId: 'sub_a',
          stepRunId: 'steprun-1',
          workspaceId: 'ws-1',
          state: {kPipelineSpaceStateKey: 'space-run-1'},
        ),
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: StepProcessRegistry(),
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        spaceId: 'chan-plan',
      );

      expect(messaging.dispatched.single.spaceId, 'chan-plan');
    });
  });

  group('dispatchConversationStep — stopping it', () {
    test('a stop before dispatch starts nobody', () async {
      // The kill hook is registered before any work, so a stop landing while
      // the step is still resolving its room stops the agents it was about to
      // dispatch rather than letting them start inside a cancelled run.
      final registry = StepProcessRegistry();
      final dispatchPort = _FakeAgentDispatchPort();
      late final _FakeMessagingPort messaging;
      messaging = _FakeMessagingPort(
        existingSpaces: {'chan-plan'},
        onSpaceExists: () => registry.kill(_ctx.stepRunId),
      );

      final result = await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: dispatchPort,
        stepProcessRegistry: registry,
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        spaceId: 'chan-plan',
      );

      expect(result.isFailed, isTrue);
      expect(
        messaging.dispatched,
        isEmpty,
        reason: 'a stopped step must not go on to dispatch its agent',
      );
    });

    test('a stop leaves a REUSED room\'s own preparation alone', () async {
      // The room belongs to the operator: its worktree is what they work in,
      // and this step ending is no reason to interrupt that.
      final registry = StepProcessRegistry();
      final messaging = _FakeMessagingPort(existingSpaces: {'chan-plan'});

      await dispatchConversationStep(
        ctx: _ctx,
        messagingPort: messaging,
        agentDispatchPort: _FakeAgentDispatchPort(),
        stepProcessRegistry: registry,
        runRepository: _FakeRunRepository(),
        agentIds: ['agent-1'],
        prompt: 'Do the work',
        spaceId: 'chan-plan',
      );
      await registry.kill(_ctx.stepRunId);

      expect(messaging.cancelledProvisioning, isEmpty);
    });
  });
}
