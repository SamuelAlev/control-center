import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/domain/templates/foreach_template.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [PipelineTemplateRepository] that returns a single template.
class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(
          String workspaceId, String templateId) async =>
      _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A fake [AgentRepository] that returns a fixed agent by id.
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo(this._agent);
  final Agent? _agent;

  @override
  Future<Agent?> getById(String id) async => _agent;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A fake [TicketWorkflowPort] that records created tickets.
class _FakeTicketWorkflow implements TicketWorkflowPort {
  final List<_CreatedTicket> created = [];

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
    created.add(_CreatedTicket(
      title: title,
      description: description,
      assignedAgentId: assignedAgentId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      mode: mode,
      expectedOutputSchema: expectedOutputSchema,
    ));
    return Ticket(
      id: id ?? 'ticket-${created.length}',
      workspaceId: workspaceId,
      title: title,
      description: description,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _CreatedTicket {
  _CreatedTicket({
    required this.title,
    this.description,
    this.assignedAgentId,
    this.pipelineRunId,
    this.pipelineStepId,
    required this.mode,
    this.expectedOutputSchema,
  });
  final String title;
  final String? description;
  final String? assignedAgentId;
  final String? pipelineRunId;
  final String? pipelineStepId;
  final ConversationMode mode;
  final Map<String, dynamic>? expectedOutputSchema;
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
}) =>
    PipelineContext(
      pipelineRunId: 'run-1',
      templateId: 'test-template',
      stepId: stepId,
      stepRunId: 'steprun-1',
      workspaceId: 'ws',
      state: state,
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
  late _FakeTicketWorkflow ticketWorkflow;

  setUp(() {
    registry = PipelineBodyRegistry();
    ticketWorkflow = _FakeTicketWorkflow();
  });

  // Helper: registers forEach with the given template/agent.
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
      ticketWorkflow: ticketWorkflow,
    );
  }

  /// Runs the registered forEach body and returns the StepResult.
  Future<StepResult> run({
    Map<String, dynamic>? state,
    Map<String, dynamic>? triggerPayload,
    bool dryRun = false,
  }) async {
    final body = registry.body(BuiltInBodyKeys.forEach);
    return body(_ctx(
      stepId: 'step-1',
      state: state ?? {},
      triggerPayload: triggerPayload,
      dryRun: dryRun,
    ));
  }

  group('validation', () {
    test('fails when step config is missing', () async {
      templateRepo = _FakeTemplateRepo(_def('step-1', PipelineNodeConfig.empty));
      agentRepo = _FakeAgentRepo(_agent('agent-1'));
      registerForEachBody(
        registry,
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        ticketWorkflow: ticketWorkflow,
      );
      final body = registry.body(BuiltInBodyKeys.forEach);
      final result = await body(_ctx(
        stepId: 'nonexistent',
        state: {},
      ));
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
      final result = await run(state: {'items': [1, 2]});
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
      final result = await run(state: {'items': [1, 2]});
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
      final result = await run(state: {'items': [1, 2]});
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
      final result = await run(state: {'items': [1, 2]});
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
      final result = await run(state: {'items': [1, 2]});
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
      final result = await run(state: {'items': [1, 2]});
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing extras.iterableKey'));
    });

    test('fails when agent is not found', () async {
      templateRepo = _FakeTemplateRepo(_def('step-1', const PipelineNodeConfig(
        agentId: 'agent-1',
        prompt: 'Hello {{item}}',
        extras: {'iterableKey': 'items'},
      )));
      agentRepo = _FakeAgentRepo(null);
      registerForEachBody(
        registry,
        templateRepository: templateRepo,
        agentRepository: agentRepo,
        ticketWorkflow: ticketWorkflow,
      );
      final result = await run(state: {'items': [1, 2]});
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('agent "agent-1" not found'));
    });
  });

  group('empty items', () {
    test('completes with empty list in outputKey when items list is empty', () async {
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
    });

    test('completes immediately without outputKey when items list is empty', () async {
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
    });

    test('completes immediately when iterableKey is absent from state and trigger', () async {
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
    });
  });

  group('item iteration', () {
    test('creates one ticket per state list item', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Process {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(state: {'items': ['a', 'b', 'c']});
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(3));
      expect(ticketWorkflow.created, hasLength(3));
    });

    test('renders prompt with itemKey per item', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['x', 'y']});
      expect(ticketWorkflow.created, hasLength(2));
      expect(ticketWorkflow.created[0].description, contains('Do x'));
      expect(ticketWorkflow.created[1].description, contains('Do y'));
    });

    test('renders prompt with custom itemKey', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Review {{pr}}',
          extras: {'iterableKey': 'prs', 'itemKey': 'pr'},
        ),
      );
      await run(state: {'prs': [42, 99]});
      expect(ticketWorkflow.created, hasLength(2));
      expect(ticketWorkflow.created[0].description, contains('Review 42'));
      expect(ticketWorkflow.created[1].description, contains('Review 99'));
    });

    test('uses default "item" key when itemKey is absent', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Handle {{item}}',
          extras: {'iterableKey': 'tasks'},
        ),
      );
      await run(state: {'tasks': ['task-a']});
      expect(ticketWorkflow.created.single.description, contains('Handle task-a'));
    });

    test('includes ticketId in description for coordination', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['one']});
      final desc = ticketWorkflow.created.single.description!;
      expect(desc, contains('complete_ticket'));
      expect(desc, contains('ticket_id='));
    });

    test('uses label in ticket title when provided', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
          label: 'My Step',
        ),
      );
      await run(state: {'items': ['a']});
      expect(ticketWorkflow.created.single.title, 'My Step [0]');
    });

    test('falls back to stepId in ticket title when label absent', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['a']});
      expect(ticketWorkflow.created.single.title, 'step-1 [0]');
    });

    test('creates tickets in review mode', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['a']});
      expect(ticketWorkflow.created.single.mode, ConversationMode.review);
    });

    test('forwards outputSchema to tickets', () async {
      final schema = {'type': 'object', 'properties': {'x': {'type': 'string'}}};
      await registerFor(
        config: PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
          outputSchema: schema,
        ),
      );
      await run(state: {'items': ['a']});
      expect(ticketWorkflow.created.single.expectedOutputSchema, schema);
    });

    test('passes pipelineRunId and stepId to tickets', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['a']});
      expect(ticketWorkflow.created.single.pipelineRunId, 'run-1');
      expect(ticketWorkflow.created.single.pipelineStepId, 'step-1');
    });

    test('suspends with all ticket IDs', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(state: {'items': ['a', 'b', 'c']});
      expect(result.suspendUntilTaskIds, hasLength(3));
      final ids = result.suspendUntilTaskIds!;
      expect(ids.toSet(), hasLength(3));
    });
  });

  group('trigger payload', () {
    test('reads items from trigger payload when absent from state', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(triggerPayload: {'items': ['from-trigger']});
      expect(ticketWorkflow.created, hasLength(1));
      expect(ticketWorkflow.created.single.description, contains('Do from-trigger'));
    });

    test('state takes precedence over trigger payload', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(
        state: {'items': ['from-state']},
        triggerPayload: {'items': ['from-trigger']},
      );
      expect(ticketWorkflow.created, hasLength(1));
      expect(ticketWorkflow.created.single.description, contains('Do from-state'));
    });
  });

  group('non-list iterable', () {
    test('wraps a single non-list value in a list', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(state: {'items': 'single-value'});
      expect(ticketWorkflow.created, hasLength(1));
      expect(ticketWorkflow.created.single.description, contains('Do single-value'));
      expect(result.suspendUntilTaskIds, hasLength(1));
    });

    test('wraps a map value in a single-element list', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Do {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      final result = await run(state: {'items': {'key': 'val'}});
      expect(ticketWorkflow.created, hasLength(1));
      expect(result.suspendUntilTaskIds, hasLength(1));
    });
  });

  group('state preservation', () {
    test('includes existing state in per-item rendering', () async {
      await registerFor(
        config: const PipelineNodeConfig(
          agentId: 'agent-1',
          prompt: 'Repo: {{repo}}, Item: {{item}}',
          extras: {'iterableKey': 'items'},
        ),
      );
      await run(state: {'items': ['x'], 'repo': 'my-repo'});
      expect(
        ticketWorkflow.created.single.description,
        contains('Repo: my-repo, Item: x'),
      );
    });
  });
}
