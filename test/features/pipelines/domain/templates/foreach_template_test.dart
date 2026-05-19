import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/foreach_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [PipelineTemplateRepository] that returns a single template.
class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A fake [AgentRepository] that returns a fixed agent by id.
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo(this._agent);
  final Agent? _agent;

  @override
  Future<Agent?> getById(String workspaceId, String id) async => _agent;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Minimal [MessagingPort] fake: creates spaces and returns a run-id per
/// dispatch. The forEach body dispatches into the run's conversation instead of
/// creating tickets.
class _FakeMessagingPort implements MessagingPort {

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}

  @override
  Future<List<String>?> getSpaceRepos(
    String workspaceId,
    String spaceId,
  ) async => null;

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {}

  /// Spaces this fake was asked to stop provisioning.
  final List<String> cancelledProvisioning = [];

  @override
  Future<void> cancelSpaceProvisioning(
    String workspaceId,
    String spaceId,
  ) async => cancelledProvisioning.add(spaceId);

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async => null;

  int _n = 0;

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async {
    _n++;
    return Space(
      id: 'ch-$_n',
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
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
    _n++;
    return 'run-$_n';
  }

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {}
  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}
  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}
  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}
  @override
  Future<void> stopRun(String workspaceId, String runLogId) async {}
  @override
  Future<bool> pauseRun(String runLogId) async => false;
  @override
  Future<bool> resumeRun(String runLogId) async => false;
  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async => false;
  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;
  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {}
  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String spaceId,
    required String feedback,
  }) async {}
  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
  }) async {}

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) async => const ConversationCompactionResult(
    status: ConversationCompactionStatus.unavailable,
  );

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

/// Minimal [AgentDispatchPort] fake — the kill hook calls stopAllForAgent.
class _FakeAgentDispatchPort implements AgentDispatchPort {
  @override
  Future<void> stopAllForAgent(String agentId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No-op [PipelineRunRepository] so the dispatch path never throws.
class _FakeRunRepository implements PipelineRunRepository {
  @override
  Future<void> insertRun(PipelineRun run) async {}
  @override
  Future<void> updateRun(PipelineRun run) async {}
  @override
  Future<PipelineRun?> getRun(String id) async => null;
  @override
  Stream<PipelineRun?> watchRun(String id) => Stream.value(null);
  @override
  Future<void> updateRunState(String runId, Map<String, dynamic> state) async {}
  @override
  Future<void> incrementCost(String runId, int cents, int tokens) async {}
  @override
  Future<List<PipelineRun>> nonTerminalRuns() async => const [];
  @override
  Stream<List<PipelineRun>> watchAll() => Stream.value(const []);
  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) =>
      Stream.value(const []);
  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async => null;
  @override
  Future<int> activeRunCountForTemplate({
    required String workspaceId,
    required String templateId,
    Set<String> excludeTriggerEventTypes = const {},
  }) async => 0;
  @override
  Future<PipelineRun?> nextQueuedRunForTemplate({
    required String workspaceId,
    required String templateId,
  }) async => null;
  @override
  Future<void> deleteRun(String workspaceId, String runId) async {}
  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async {}
  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {}
  @override
  Future<void> restartStepRun(
    String workspaceId,
    String stepRunId, {
    required DateTime startedAt,
  }) async {}
  @override
  Future<void> deleteStepRun(String workspaceId, String stepRunId) async {}
  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(String pipelineRunId) =>
      Future.value(const []);
  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async => null;
  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(
    String pipelineRunId,
  ) => Stream.value(const []);
}

/// Helper: build a step definition with the given config.
PipelineStepDefinition _step(String id, PipelineNodeConfig config) =>
    PipelineStepDefinition(
      id: id,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.forEach,
      config: config,
    );

/// Helper: build a pipeline definition containing one step.
PipelineDefinition _def(String stepId, PipelineNodeConfig config) =>
    PipelineDefinition(
      templateId: 'test-template',
      workspaceId: 'ws',
      name: 'Test Template',
      steps: [_step(stepId, config)],
    );

/// Helper: create a PipelineContext for a forEach step.
PipelineContext _ctx({
  required String stepId,
  required Map<String, dynamic> state,
  Map<String, dynamic>? triggerPayload,
  bool dryRun = false,
}) => PipelineContext(
  pipelineRunId: 'run-1',
  templateId: 'test-template',
  stepId: stepId,
  stepRunId: 'steprun-1',
  workspaceId: 'ws',
  // A run always has a room before it dispatches an agent: a
  // `messaging.createSpace` node opens it and publishes the id under this
  // key. Agent steps join that room and never open one.
  state: {kPipelineSpaceStateKey: 'space-run-1', ...state},
  triggerPayload: triggerPayload,
  dryRun: dryRun,
);

/// Helper: create an Agent for testing.
Agent _agent(String id) => Agent(
  id: id,
  name: 'Test Agent',
  title: 'Test Agent Title',
  agentMdPath: '/tmp/agents/test.md',
  workspaceId: 'ws',
  skills: AgentSkills([]),
  createdAt: DateTime.now(),
);

void main() {
  late PipelineBodyRegistry registry;
  late _FakeTemplateRepo templateRepo;
  late _FakeAgentRepo agentRepo;
  late _FakeMessagingPort messagingPort;
  late _FakeAgentDispatchPort dispatchPort;
  late _FakeRunRepository runRepo;
  late StepProcessRegistry stepProcessRegistry;

  setUp(() {
    registry = PipelineBodyRegistry();
    messagingPort = _FakeMessagingPort();
    dispatchPort = _FakeAgentDispatchPort();
    runRepo = _FakeRunRepository();
    stepProcessRegistry = StepProcessRegistry();
  });

  /// Registers the forEach body with the given template/agent and the new
  /// conversation-dispatch dependencies.
  Future<void> registerFor({
    required PipelineNodeConfig config,
    Agent? agent,
  }) async {
    agentRepo = _FakeAgentRepo(agent ?? _agent('agent-1'));
    templateRepo = _FakeTemplateRepo(_def('step-1', config));
    registerForEachBody(
      registry,
      templateRepository: templateRepo,
      agentRepository: agentRepo,
      messagingPort: messagingPort,
      agentDispatchPort: dispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepo,
    );
  }

  /// Runs the registered forEach body and returns the StepResult.
  Future<StepResult> run({
    String stepId = 'step-1',
    Map<String, dynamic>? state,
    Map<String, dynamic>? triggerPayload,
    bool dryRun = false,
  }) async {
    final body = registry.body(BuiltInBodyKeys.forEach);
    return body(
      _ctx(
        stepId: stepId,
        state: state ?? {},
        triggerPayload: triggerPayload,
        dryRun: dryRun,
      ),
    );
  }

  group('validation', () {
    test('fails when step config is missing', () async {
      await registerFor(config: PipelineNodeConfig.empty);
      final result = await run(stepId: 'nonexistent', state: {});
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when agentId is missing', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          prompt: 'Hello {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agentId'));
    });

    test('fails when agentId is empty string', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: '',
          prompt: 'Hello {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agentId'));
    });

    test('fails when prompt is missing', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when prompt is empty string', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: '',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when iterableKey is missing', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Hello {{item}}',
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing extras.iterableKey'));
    });

    test('fails when iterableKey is empty string', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Hello {{item}}',
          extras: {'iterableKey': ''},
        ),
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing extras.iterableKey'));
    });

    test('fails when agent is not found', () async {
      agentRepo = _FakeAgentRepo(null);
      templateRepo = _FakeTemplateRepo(
        _def(
          'step-1',
          const PipelineNodeConfig(
            agentId: 'agent-1',
            prompt: 'Hello {{item}}',
            extras: {'iterableKey': 'items'},
          ),
        ),
      );
      registerForEachBody(
        registry,
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        messagingPort: messagingPort,
        agentDispatchPort: dispatchPort,
        stepProcessRegistry: stepProcessRegistry,
        runRepository: runRepo,
      );
      final result = await run(
        state: {
          'items': [1, 2],
        },
      );
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('agent "agent-1" not found'));
    });
  });

  group('empty items', () {
    test(
      'completes with empty list in outputKey when items list is empty',
      () async {
        await registerFor(
          config: const PipelineNodeConfig(
            agentId: 'agent-1',
            prompt: 'Hello {{item}}',
            extras: {'iterableKey': 'items'},
            outputKey: 'results',
          ),
        );
        final result = await run(state: {'items': <int>[]});
        expect(result.isFailed, isFalse);
        expect(result.isSuspended, isFalse);
        expect(result.mutatedState, containsPair('results', <dynamic>[]));
      },
    );

    test(
      'completes immediately without outputKey when items list is empty',
      () async {
        await registerFor(
          config: const PipelineNodeConfig(
            agentId: 'agent-1',
            prompt: 'Hello {{item}}',
            extras: {'iterableKey': 'items'},
          ),
        );
        final result = await run(state: {'items': <int>[]});
        expect(result.isFailed, isFalse);
        expect(result.isSuspended, isFalse);
        expect(result.mutatedState, isEmpty);
      },
    );

    test(
      'completes immediately when iterableKey is absent from state and trigger',
      () async {
        await registerFor(
          config: const PipelineNodeConfig(
            agentId: 'agent-1',
            prompt: 'Hello {{item}}',
            extras: {'iterableKey': 'items'},
            outputKey: 'results',
          ),
        );
        final result = await run();
        expect(result.isFailed, isFalse);
        expect(result.isSuspended, isFalse);
        expect(result.mutatedState, containsPair('results', <dynamic>[]));
      },
    );
  });

  // The forEach body now dispatches one agent per item into a hidden
  // conversation (instead of creating tickets) and suspends until each
  // dispatched run completes.
  group('item dispatch', () {
    test('suspends when iterating items', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Process {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        state: {
          'items': ['a', 'b', 'c'],
        },
      );
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, isNotEmpty);
    });

    test('reads items from trigger payload when absent from state', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(
        triggerPayload: {
          'items': ['from-trigger'],
        },
      );
      expect(result.isSuspended, isTrue);
    });

    test('wraps a single non-list value in a list and suspends', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(state: {'items': 'single-value'});
      expect(result.isSuspended, isTrue);
    });
  });
}
