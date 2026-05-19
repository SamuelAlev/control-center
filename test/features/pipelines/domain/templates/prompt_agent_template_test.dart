import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
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
  ) async =>
      _templates['$workspaceId/$templateId'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAgentRepo implements AgentRepository {
  final Map<String, Agent> _agents = {};

  void seed(Agent agent) {
    _agents[agent.id] = agent;
  }

  @override
  Future<Agent?> getById(String id) async => _agents[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal [MessagingPort] fake: creates channels and returns a run-id per
/// dispatch. The promptAgent body dispatches into a hidden conversation.
class _FakeMessagingPort implements MessagingPort {
  int _n = 0;

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  }) async {
    _n++;
    return Channel(
      id: 'ch-$_n',
      name: name,
      isDm: false,
      workspaceId: workspaceId ?? 'ws-1',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  @override
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    WakeContext? wakeContext,
    String? parentMessageId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    _n++;
    return 'run-$_n';
  }

  @override
  Future<void> sendUserMessage(String channelId, String content) async {}
  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {}
  @override
 Future<bool> channelExists(String channelId) async => true;
  @override
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) async {}
  @override
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  }) async {}
  @override
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) async {}
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
  }) async =>
      null;
  @override
  Future<void> deleteRun(String workspaceId, String runId) async {}
  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async {}
  @override
  Future<void> updateStepRun(
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {}
  @override
  Future<void> deleteStepRun(String stepRunId) async {}
  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(String pipelineRunId) =>
      Future.value(const []);
  @override
  Future<PipelineStepRun?> getStepRunById(String stepRunId) async => null;
  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(String pipelineRunId) =>
      Stream.value(const []);
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
    state: state,
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
      templateRepo.seed(PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws-1',
        name: 'Empty Template',
        steps: [],
      ));

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
      const config = PipelineNodeConfig(
        prompt: null,
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt template'));
    });

    test('fails when prompt is empty', () async {
      const config = PipelineNodeConfig(
        prompt: '',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt template'));
    });

    test('fails when agentId is null', () async {
      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: null,
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agentId'));
    });

    test('fails when agentId is empty', () async {
      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: '',
      );
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

    test('unresolved placeholders fail the step (no truncated prompt sent)',
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
    });

    // ── Conversation dispatch ─────────────────────────────────────────────────
    //
    // The body now dispatches the agent into a hidden conversation (instead of
    // creating a ticket) and suspends until the run completes.

    test('renders prompt and suspends (dispatches into hidden conversation)',
        () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Review {{repoName}} for {{issue}}',
        agentId: 'agent-1',
        outputKey: 'review_result',
        label: 'Code Review',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final ctx = _testContext(state: {
        'repoName': 'my-repo',
        'issue': 'security',
      });

      final result = await body(ctx);

      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(1));
    });

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

      const config = PipelineNodeConfig(
        prompt: '   ',
        agentId: 'agent-1',
      );
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
      final result = await body(_testContext(
        state: {'project': 'my-app'},
        dryRun: true,
      ));

      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
    });
  });
}
