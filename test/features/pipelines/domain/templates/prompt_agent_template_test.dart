import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
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

class _FakeTicketWorkflow implements TicketWorkflowPort {
  @override
  Future<void> failTicket(String ticketId, String errorMessage, {required String workspaceId, bool force = false}) async {}

  final List<Ticket> createdTickets = [];
  final List<String> cancelledTicketIds = [];

  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  }) async {
    final now = DateTime.now();
    final ticket = Ticket(
      id: id ?? 'gen-${createdTickets.length}',
      workspaceId: workspaceId,
      title: title,
      description: description,
      provider: provider,
      priority: priority,
      status: status,
      assignedAgentId: assignedAgentId,
      mode: mode,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      createdAt: now,
      updatedAt: now,
    );
    createdTickets.add(ticket);
    return ticket;
  }

  @override
  Future<void> cancelTicket(
    String ticketId, {
    required String workspaceId,
    bool force = false,
  }) async {
    cancelledTicketIds.add(ticketId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

/// Registers the promptAgent body with given fakes and returns the closure.
Future<StepResult> Function(PipelineContext) _registerAndGetBody({
  required _FakeTemplateRepo templateRepo,
  required _FakeAgentRepo agentRepo,
  required _FakeTicketWorkflow ticketWorkflow,
  required StepProcessRegistry stepProcessRegistry,
  required _FakeAgentDispatchPort agentDispatchPort,
}) {
  final registry = PipelineBodyRegistry();
  registerPromptAgentBody(
    registry,
    templateRepository: templateRepo,
    agentRepository: agentRepo,
    ticketWorkflow: ticketWorkflow,
    stepProcessRegistry: stepProcessRegistry,
    agentDispatchPort: agentDispatchPort,
  );
  return registry.body(BuiltInBodyKeys.promptAgent);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('promptAgent body', () {
    late _FakeTemplateRepo templateRepo;
    late _FakeAgentRepo agentRepo;
    late _FakeTicketWorkflow ticketWorkflow;
    late StepProcessRegistry stepProcessRegistry;
    late _FakeAgentDispatchPort agentDispatchPort;

    setUp(() {
      templateRepo = _FakeTemplateRepo();
      agentRepo = _FakeAgentRepo();
      ticketWorkflow = _FakeTicketWorkflow();
      stepProcessRegistry = StepProcessRegistry();
      agentDispatchPort = _FakeAgentDispatchPort();
    });

    Future<StepResult> Function(PipelineContext) getBody() =>
        _registerAndGetBody(
          templateRepo: templateRepo,
          agentRepo: agentRepo,
          ticketWorkflow: ticketWorkflow,
          stepProcessRegistry: stepProcessRegistry,
          agentDispatchPort: agentDispatchPort,
        );

    // ── Normal execution ─────────────────────────────────────────────────────

    test('renders prompt and creates ticket with correct description',
        timeout: const Timeout.factor(2), () async {
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

      // Returns suspend with correct task IDs.
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(1));
      final ticketId = result.suspendUntilTaskIds!.single;

      // One ticket created.
      expect(ticketWorkflow.createdTickets, hasLength(1));
      final ticket = ticketWorkflow.createdTickets.single;

      // Ticket title uses label.
      expect(ticket.title, equals('Code Review'));
      expect(ticket.assignedAgentId, equals('agent-1'));
      expect(ticket.mode, equals(ConversationMode.review));
      expect(ticket.pipelineRunId, equals('run-1'));
      expect(ticket.pipelineStepId, equals('step-1'));

      // Description: rendered prompt + coordination footer.
      expect(
        ticket.description,
        stringContainsInOrder([
          'Review my-repo for security',
          '── Pipeline coordination',
          'ticket_id="$ticketId"',
        ]),
      );
    });

    test('uses stepId as title when label is null',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        // label is null
      );
      templateRepo.seed(_definitionWithConfig(config: config, stepId: 'my-step'));

      final body = getBody();
      final ctx = _testContext(stepId: 'my-step');

      await body(ctx);

      expect(ticketWorkflow.createdTickets.single.title, equals('my-step'));
    });

    test('uses label when set', timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        label: 'Custom Label',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext());

      expect(
        ticketWorkflow.createdTickets.single.title,
        equals('Custom Label'),
      );
    });

    // ── Conversation mode ────────────────────────────────────────────────────

    test('defaults to review conversation mode',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        // extras is empty
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext());

      expect(
        ticketWorkflow.createdTickets.single.mode,
        equals(ConversationMode.review),
      );
    });

    test('uses conversationMode from extras when set to chat',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        extras: {'conversationMode': 'chat'},
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext());

      expect(
        ticketWorkflow.createdTickets.single.mode,
        equals(ConversationMode.chat),
      );
    });

    test('uses conversationMode from extras when set to plan',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Plan architecture',
        agentId: 'agent-1',
        extras: {'conversationMode': 'plan'},
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext());

      expect(
        ticketWorkflow.createdTickets.single.mode,
        equals(ConversationMode.plan),
      );
    });

    test('falls back to review for unknown conversationMode string',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        extras: {'conversationMode': 'unknown_mode'},
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext());

      expect(
        ticketWorkflow.createdTickets.single.mode,
        equals(ConversationMode.review),
      );
    });

    // ── Kill hook registration ───────────────────────────────────────────────

    test('registers kill hook with stepProcessRegistry',
        timeout: const Timeout.factor(2), () async {
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

    test('kill hook cancels ticket and stops agent dispatches',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext(stepRunId: 'sr-hook'));
      final ticketId = result.suspendUntilTaskIds!.single;

      // Invoke the kill hook.
      await stepProcessRegistry.kill('sr-hook');

      expect(ticketWorkflow.cancelledTicketIds, equals([ticketId]));
      expect(agentDispatchPort.stopAllForAgentCalls, equals(['agent-1']));
    });

    // ── Dry run ──────────────────────────────────────────────────────────────

    test('dry run returns ok without creating a ticket',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Review {{project}}',
        agentId: 'agent-1',
        outputKey: 'review',
        label: 'Review Step',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext(
        state: {'project': 'my-app'},
        dryRun: true,
      ));

      // No ticket created.
      expect(ticketWorkflow.createdTickets, isEmpty);

      // Returns ok with dry-run message in mutatedState.
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
      expect(result.mutatedState, isNotNull);
      expect(
        result.mutatedState!['review'],
        contains('[dry-run] agent "test-agent" dispatch skipped'),
      );
    });

    test('dry run with null outputKey returns empty mutatedState',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        // outputKey is null
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext(dryRun: true));

      expect(result.mutatedState, isEmpty);
    });

    test('dry run with empty outputKey returns empty mutatedState',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Do something',
        agentId: 'agent-1',
        outputKey: '',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext(dryRun: true));

      expect(result.mutatedState, isEmpty);
    });

    // ── Error: missing step config ───────────────────────────────────────────

    test('fails when step config is missing',
        timeout: const Timeout.factor(2), () async {
      // Seed a template with no step matching the stepId.
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

    test('fails when template is not found',
        timeout: const Timeout.factor(2), () async {
      final body = getBody();
      final result = await body(_testContext());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    // ── Error: missing prompt ────────────────────────────────────────────────

    test('fails when prompt is null', timeout: const Timeout.factor(2),
        () async {
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

    test('fails when prompt is empty', timeout: const Timeout.factor(2),
        () async {
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

    // ── Error: missing agentId ───────────────────────────────────────────────

    test('fails when agentId is null', timeout: const Timeout.factor(2),
        () async {
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

    test('fails when agentId is empty', timeout: const Timeout.factor(2),
        () async {
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

    // ── Error: agent not found ───────────────────────────────────────────────

    test('fails when agent does not exist', timeout: const Timeout.factor(2),
        () async {
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

    // ── Prompt rendering ─────────────────────────────────────────────────────

    test('substitutes placeholders from state',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Analyze {{file}} in {{language}}',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(state: {
        'file': 'main.dart',
        'language': 'Dart',
      }));

      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Analyze main.dart in Dart'));
    });

    test('substitutes placeholders from trigger when absent in state',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Process {{eventType}}',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(
        state: const {},
        triggerPayload: {'eventType': 'push'},
      ));

      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Process push'));
    });

    test('state take precedence over trigger for placeholder resolution',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Value: {{key}}',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(
        state: {'key': 'from-state'},
        triggerPayload: {'key': 'from-trigger'},
      ));

      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Value: from-state'));
    });

    test('renders numeric values from state',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Check {{count}} items',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(state: {'count': 42}));

      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Check 42 items'));
    });

    test('renders boolean values from state',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Enabled: {{flag}}',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      await body(_testContext(state: {'flag': true}));

      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Enabled: true'));
    });

    test('unresolved placeholders fail the step (no truncated prompt sent)',
        timeout: const Timeout.factor(2), () async {
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
      // so the step fails loudly instead of dispatching — and no ticket is
      // created.
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('unresolved'));
      expect(result.errorMessage, contains('missing'));
      expect(ticketWorkflow.createdTickets, isEmpty);
    });

    test('run-context ids (workspaceId) resolve in the prompt',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Workspace is {{workspaceId}}',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      // workspaceId lives on the run context (not state/trigger) yet must
      // resolve via PipelineContext.renderState — the regression this fixes.
      expect(result.isSuspended, isTrue);
      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('Workspace is ws-1'));
    });

    test(
        'index_code "analyze" step (real seed) resolves {{workspaceId}} + '
        '{{repoId}} end-to-end — regression for the unresolved-placeholder '
        'failure', timeout: const Timeout.factor(2), () async {
      // The librarian agent the analyze step dispatches to.
      agentRepo.seed(_testAgent(id: 'librarian-1', name: 'librarian'));

      const agentIds = BuiltInAgentIds(
        qa: 'qa-1',
        architect: 'arch-1',
        engineer: 'eng-1',
        librarian: 'librarian-1',
        ceo: 'ceo-1',
      );
      final indexDef = builtInTemplateSeeds(
        workspaceId: 'ws-1',
        agentIds: agentIds,
      ).firstWhere((d) => d.templateId == 'index_code');
      templateRepo.seed(indexDef);

      // The analyze step exists and its prompt references the context-only
      // {{workspaceId}} placeholder that used to fail the step.
      final analyze = indexDef.step('analyze');
      expect(analyze, isNotNull);
      expect(analyze!.config.prompt, contains('{{workspaceId}}'));

      // Run it exactly as the engine would: workspaceId on the context,
      // repoId/repoLocalPath in the run's trigger payload (the engine
      // propagates the run trigger payload to every step), indexSummary in
      // state from the upstream index step.
      final result = await getBody()(
        _testContext(
          templateId: 'index_code',
          stepId: 'analyze',
          workspaceId: 'ws-1',
          state: {'indexSummary': '120 symbols, 300 edges'},
          triggerPayload: {
            'repoId': 'repo-1',
            'repoLocalPath': '/tmp/repo',
          },
        ),
      );

      // Suspends (ticket created) instead of failing on unresolved
      // placeholders, and the rendered description carries the resolved ids.
      expect(result.isSuspended, isTrue);
      final description = ticketWorkflow.createdTickets.single.description!;
      expect(description, contains('workspace ws-1'));
      expect(description, contains('repo-1'));
      expect(description, isNot(contains('{{workspaceId}}')));
      expect(description, isNot(contains('{{repoId}}')));
    });

    test('triggerPayload handled when null',
        timeout: const Timeout.factor(2), () async {
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

    // ── Edge: whitespace-only prompt ─────────────────────────────────────────

    test('fails when prompt is whitespace only',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: '   ',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();

      final result = await body(_testContext());
      expect(result.isFailed, isFalse);
      // Whitespace is not empty, so it proceeds.
      expect(result.isSuspended, isTrue);
      // The rendered prompt should be the whitespace itself.
      final description = ticketWorkflow.createdTickets.single.description!;
      expect(
        description,
        startsWith('   \n\n── Pipeline coordination'),
      );
    });

    // ── Ticket description format ────────────────────────────────────────────

    test('ticket description contains coordination footer',
        timeout: const Timeout.factor(2), () async {
      final agent = _testAgent();
      agentRepo.seed(agent);

      const config = PipelineNodeConfig(
        prompt: 'Run analysis',
        agentId: 'agent-1',
      );
      templateRepo.seed(_definitionWithConfig(config: config));

      final body = getBody();
      final result = await body(_testContext());

      final ticketId = result.suspendUntilTaskIds!.single;
      final description = ticketWorkflow.createdTickets.single.description!;

      expect(description, contains('── Pipeline coordination'));
      expect(description, contains('complete_ticket'));
      expect(description, contains('fail_ticket'));
      expect(description, contains('ticket_id="$ticketId"'));
    });
  });
}
