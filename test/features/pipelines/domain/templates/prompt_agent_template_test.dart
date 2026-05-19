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
import 'package:cc_domain/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a bare-minimum Agent for tests.
Agent _testAgent({
  String id = 'agent-1',
  String name = 'test-agent',
  String workspaceId = 'ws-1',
}) {
  return Agent(
    id: id,
    name: name,
    title: 'Test Agent',
    agentMdPath: '/fake/agent.md',
    workspaceId: workspaceId,
    skills: AgentSkills(const []),
    createdAt: DateTime(2024, 1, 1),
  );
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeTemplateRepo implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> _templates = {};

  void seed(PipelineDefinition def) {
    _templates['${def.workspaceId}/${def.templateId}'] = def;
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => _templates['$workspaceId/$templateId'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAgentRepo implements AgentRepository {
  final Map<String, Agent> _agents = {};

  void seed(Agent agent) {
    _agents[agent.id] = agent;
  }

  @override
  Future<Agent?> getById(String workspaceId, String id) async => _agents[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal [MessagingPort] fake: creates spaces and returns a run-id per
/// dispatch. The promptAgent body dispatches into the run's conversation.
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

class _FakeAgentDispatchPort implements AgentDispatchPort {
  final List<String> stopAllForAgentCalls = [];

  @override
  Future<void> stopAllForAgent(String agentId) async {
    stopAllForAgentCalls.add(agentId);
  }

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

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Creates a PipelineDefinition with one step having [config].
PipelineDefinition _definitionWithConfig({
  String templateId = 'tpl',
  String workspaceId = 'ws-1',
  String stepId = 'step-1',
  required PipelineNodeConfig config,
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: workspaceId,
    name: 'Test Pipeline',
    steps: [
      PipelineStepDefinition(
        id: stepId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.promptAgent,
        config: config,
      ),
    ],
  );
}

/// Creates a PipelineContext with sensible defaults for tests.
PipelineContext _testContext({
  String pipelineRunId = 'run-1',
  String templateId = 'tpl',
  String stepId = 'step-1',
  String stepRunId = 'steprun-1',
  String workspaceId = 'ws-1',
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? triggerPayload,
  bool dryRun = false,
}) {
  return PipelineContext(
    pipelineRunId: pipelineRunId,
    templateId: templateId,
    stepId: stepId,
    stepRunId: stepRunId,
    workspaceId: workspaceId,
    // A run always has a room before it dispatches an agent: a
    // `messaging.createSpace` node opens it and publishes the id under this
    // key. Agent steps join that room and never open one.
    state: {kPipelineSpaceStateKey: 'space-run-1', ...state},
    triggerPayload: triggerPayload,
    dryRun: dryRun,
  );
}

/// Registers the promptAgent body with the conversation-dispatch dependencies
/// and returns the body closure.
Future<StepResult> Function(PipelineContext) _registerAndGetBody({
  required _FakeTemplateRepo templateRepo,
  required _FakeAgentRepo agentRepo,
  required _FakeMessagingPort messagingPort,
  required StepProcessRegistry stepProcessRegistry,
  required _FakeAgentDispatchPort agentDispatchPort,
  required _FakeRunRepository runRepository,
}) {
  final registry = PipelineBodyRegistry();
  registerPromptAgentBody(
    registry,
    templateRepository: templateRepo,
    agentRepository: agentRepo,
    messagingPort: messagingPort,
    stepProcessRegistry: stepProcessRegistry,
    agentDispatchPort: agentDispatchPort,
    runRepository: runRepository,
  );
  return registry.body(BuiltInBodyKeys.promptAgent);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('promptAgent body', () {
    late _FakeTemplateRepo templateRepo;
    late _FakeAgentRepo agentRepo;
    late _FakeMessagingPort messagingPort;
    late StepProcessRegistry stepProcessRegistry;
    late _FakeAgentDispatchPort agentDispatchPort;
    late _FakeRunRepository runRepository;

    setUp(() {
      templateRepo = _FakeTemplateRepo();
      agentRepo = _FakeAgentRepo();
      messagingPort = _FakeMessagingPort();
      stepProcessRegistry = StepProcessRegistry();
      agentDispatchPort = _FakeAgentDispatchPort();
      runRepository = _FakeRunRepository();
    });

    Future<StepResult> Function(PipelineContext) getBody() =>
        _registerAndGetBody(
          templateRepo: templateRepo,
          agentRepo: agentRepo,
          messagingPort: messagingPort,
          stepProcessRegistry: stepProcessRegistry,
          agentDispatchPort: agentDispatchPort,
          runRepository: runRepository,
        );

    // ── Validation ───────────────────────────────────────────────────────────

    test('fails when step config is missing', () async {
      templateRepo.seed(
        PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws-1',
          name: 'Empty Template',
          steps: [],
        ),
      );

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when template is not found', () async {
      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when prompt is null', () async {
      const config = PipelineNodeConfig(prompt: null, agentId: 'agent-1');
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt template'));
    });

    test('fails when prompt is empty', () async {
      const config = PipelineNodeConfig(prompt: '', agentId: 'agent-1');
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt template'));
    });

    test('fails when agentId is null', () async {
      const config = PipelineNodeConfig(prompt: 'Do something', agentId: null);
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agentId'));
    });

    test('fails when agentId is empty', () async {
      const config = PipelineNodeConfig(prompt: 'Do something', agentId: '');
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agentId'));
    });

    test('fails when agent does not exist', () async {
      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'nonexistent',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('not found'));
    });

    test(
      'unresolved placeholders fail the step (no truncated prompt sent)',
      () async {
        final agent = _testAgent();
        agentRepo.seed(agent);

        const config = PipelineNodeConfig(
          prompt: 'Hello {{missing}} world',
          agentId: 'agent-1',
        );
        templateRepo.seed(_definitionWithConfig(config: config));

        final body = getBody();
        final result = await body(_testContext());

        // An unresolved placeholder would silently truncate the agent's prompt,
        // so the step fails loudly instead of dispatching.
        expect(result.isFailed, isTrue);
        expect(result.errorMessage, contains('unresolved'));
        expect(result.errorMessage, contains('missing'));
      },
    );

    // ── Conversation dispatch ─────────────────────────────────────────────────
    //
    // The body dispatches the agent into the run's conversation — opened by a
    // `messaging.createSpace` node, never by this step — and suspends until the
    // run completes.

    test(
      'renders prompt and suspends, dispatching into the run\'s conversation',
      () async {
        final agent = _testAgent();
        agentRepo.seed(agent);

        const config = PipelineNodeConfig(
          prompt: 'Review {{repo_name}} for {{issue}}',
          agentId: 'agent-1',
          outputKey: 'review_result',
          label: 'Code Review',
        );
        templateRepo.seed(_definitionWithConfig(config: config));

        final body = getBody();
        final ctx = _testContext(
          state: {'repo_name': 'my-repo', 'issue': 'security'},
        );

        final result = await body(ctx);

        expect(result.isFailed, isFalse);
        expect(result.isSuspended, isTrue);
        expect(result.suspendUntilTaskIds, hasLength(1));
      },
    );

    test('registers kill hook with stepProcessRegistry', () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(stepRunId: 'sr-1'));

      expect(stepProcessRegistry.isLive('sr-1'), isTrue);
    });

    test('whitespace prompt proceeds and suspends', () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(prompt: '   ', agentId: 'agent-1');
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      // Whitespace is not empty, so it proceeds to dispatch.
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isTrue);
    });

    test('triggerPayload handled when null', () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Just do it',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext(triggerPayload: null));

      expect(result.isSuspended, isTrue);
    });

    // ── Dry run ──────────────────────────────────────────────────────────────

    test('dry run does not suspend', () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Review {{project}}',
        agentId: 'agent-1',
        outputKey: 'review',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(
        _testContext(state: {'project': 'my-app'}, dryRun: true),
      );

      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
    });
  });
}
