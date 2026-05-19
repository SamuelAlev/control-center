import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
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
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight fakes for the repositories/ports the team-dispatch body uses.

class _FakePipelineTemplateRepository implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> _defs = {};

  void add(PipelineDefinition def) {
    _defs[def.templateId] = def;
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    final def = _defs[templateId];
    if (def == null || def.workspaceId != workspaceId) {
      return null;
    }
    return def;
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    return _defs.values.where((d) => d.workspaceId == workspaceId).toList();
  }

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    _defs[definition.templateId] = definition;
  }

  @override
  Future<int> deleteById(String workspaceId, String templateId) async {
    throw UnimplementedError();
  }
}

class _FakeAgentRepository implements AgentRepository {
  final Map<String, Agent> _agents = {};

  void add(Agent agent) {
    _agents[agent.id] = agent;
  }

  @override
  Future<Agent?> getById(String workspaceId, String agentId) async {
    return _agents[agentId];
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) =>
      throw UnimplementedError();

  @override
  Stream<List<Agent>> watchAll() => throw UnimplementedError();

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<void> upsert(Agent agent) => throw UnimplementedError();

  @override
  Future<void> delete(String workspaceId, String id) =>
      throw UnimplementedError();
}

class _FakeTeamRepository implements TeamRepository {
  final Map<String, List<TeamMember>> _members = {};

  void setMembers(String teamId, List<TeamMember> members) {
    _members[teamId] = members;
  }

  @override
  Future<List<TeamMember>> membersOf(String workspaceId, String teamId) async {
    return _members[teamId] ?? [];
  }

  @override
  Future<void> insertTeam(Team team) => throw UnimplementedError();

  @override
  Future<void> updateTeam(Team team) => throw UnimplementedError();

  @override
  Future<void> deleteTeam(String workspaceId, String id) =>
      throw UnimplementedError();

  @override
  Future<Team?> getTeam(String workspaceId, String id) =>
      throw UnimplementedError();

  @override
  Future<List<Team>> teamsForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Stream<List<Team>> watchTeamsForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<void> addMember(String workspaceId, TeamMember member) =>
      throw UnimplementedError();

  @override
  Future<void> removeMember(
    String workspaceId,
    String teamId,
    String agentId,
  ) => throw UnimplementedError();

  @override
  Stream<List<TeamMember>> watchMembersOf(String workspaceId, String teamId) =>
      throw UnimplementedError();
}

/// Minimal [MessagingPort] fake: creates spaces and returns a run-id per
/// dispatch. The team-dispatch body dispatches into the run's conversation.
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

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

const _workspaceId = 'ws-1';
const _templateId = 'tpl-team-test';
const _stepId = 'dispatch-step';

Agent _testAgent(String id, String name) => Agent(
  id: id,
  name: name,
  title: 'Engineer',
  agentMdPath: '/agents/$id.md',
  workspaceId: _workspaceId,
  skills: AgentSkills([]),
  capabilities: const AgentCapabilities(),
  createdAt: DateTime(2024),
);

PipelineDefinition _defWithConfig(PipelineNodeConfig config) {
  return PipelineDefinition(
    templateId: _templateId,
    workspaceId: _workspaceId,
    name: 'Test Team Pipeline',
    steps: [
      PipelineStepDefinition(
        id: _stepId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.teamDispatch,
        config: config,
      ),
    ],
  );
}

PipelineContext _ctx({
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? triggerPayload,
}) {
  return PipelineContext(
    pipelineRunId: 'run-1',
    templateId: _templateId,
    stepId: _stepId,
    stepRunId: 'sr-1',
    workspaceId: _workspaceId,
    // A run always has a room before it dispatches an agent: a
    // `messaging.createSpace` node opens it and publishes the id under this
    // key. Agent steps join that room and never open one.
    state: {kPipelineSpaceStateKey: 'space-run-1', ...state},
    triggerPayload: triggerPayload,
  );
}

/// Registers the team-dispatch body with the conversation-dispatch
/// dependencies and returns the registry.
PipelineBodyRegistry _setupRegistry({
  required _FakePipelineTemplateRepository templateRepository,
  required _FakeAgentRepository agentRepository,
  required _FakeTeamRepository teamRepository,
  required _FakeMessagingPort messagingPort,
  required _FakeAgentDispatchPort agentDispatchPort,
  required StepProcessRegistry stepProcessRegistry,
  required _FakeRunRepository runRepository,
}) {
  final registry = PipelineBodyRegistry();
  registerTeamDispatchBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    teamRepository: teamRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcessRegistry,
    runRepository: runRepository,
  );
  return registry;
}

void main() {
  const teamId = 'team-1';
  const agent1Id = 'agent-1';
  const agent2Id = 'agent-2';
  const leaderAgentId = 'leader-agent';

  late _FakePipelineTemplateRepository templateRepo;
  late _FakeAgentRepository agentRepo;
  late _FakeTeamRepository teamRepo;
  late _FakeMessagingPort messagingPort;
  late _FakeAgentDispatchPort dispatchPort;
  late StepProcessRegistry stepProcessRegistry;
  late _FakeRunRepository runRepo;
  late PipelineBodyRegistry registry;

  setUp(() {
    templateRepo = _FakePipelineTemplateRepository();
    agentRepo = _FakeAgentRepository();
    teamRepo = _FakeTeamRepository();
    messagingPort = _FakeMessagingPort();
    dispatchPort = _FakeAgentDispatchPort();
    stepProcessRegistry = StepProcessRegistry();
    runRepo = _FakeRunRepository();
    registry = _setupRegistry(
      templateRepository: templateRepo,
      agentRepository: agentRepo,
      teamRepository: teamRepo,
      messagingPort: messagingPort,
      agentDispatchPort: dispatchPort,
      stepProcessRegistry: stepProcessRegistry,
      runRepository: runRepo,
    );
  });

  group('team.dispatch — validation / error cases', () {
    test('fails when step is missing config (def not found)', () async {
      // No template definition added for the templateId.
      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('fails when teamId is null', () async {
      templateRepo.add(
        _defWithConfig(const PipelineNodeConfig(prompt: 'Task')),
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing teamId'));
    });

    test('fails when teamId is empty', () async {
      templateRepo.add(
        _defWithConfig(const PipelineNodeConfig(teamId: '', prompt: 'Task')),
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing teamId'));
    });

    test('fails when prompt is null', () async {
      templateRepo.add(
        _defWithConfig(const PipelineNodeConfig(teamId: teamId)),
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when prompt is empty', () async {
      templateRepo.add(
        _defWithConfig(const PipelineNodeConfig(teamId: teamId, prompt: '')),
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing prompt'));
    });

    test('fails when team has no members', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(teamId: teamId, prompt: 'Task'),
        ),
      );
      teamRepo.setMembers(teamId, []);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('has no members'));
    });

    test(
      'template not found for templateId returns missing config error',
      () async {
        templateRepo.add(
          _defWithConfig(
            const PipelineNodeConfig(teamId: teamId, prompt: 'Task'),
          ),
        );
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'unknown-template',
          stepId: _stepId,
          stepRunId: 'sr-1',
          workspaceId: _workspaceId,
          state: {},
        );

        final body = registry.body(BuiltInBodyKeys.teamDispatch);
        final result = await body(ctx);

        expect(result.isFailed, isTrue);
        expect(result.errorMessage, contains('missing config'));
      },
    );

    test('step not found in template returns missing config error', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(teamId: teamId, prompt: 'Task'),
        ),
      );
      const ctx = PipelineContext(
        pipelineRunId: 'run-1',
        templateId: _templateId,
        stepId: 'nonexistent-step',
        stepRunId: 'sr-1',
        workspaceId: _workspaceId,
        state: {},
      );

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(ctx);

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing config'));
    });

    test('missing agent fails with descriptive message', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(teamId: teamId, prompt: 'Do the thing'),
        ),
      );
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      // agent-2 is NOT added.
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('missing agents'));
      expect(result.errorMessage, contains(agent2Id));
    });

    test('all agents missing fails before any dispatch', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(teamId: teamId, prompt: 'Do the thing'),
        ),
      );
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(
        result.errorMessage,
        contains('2 team member(s) reference missing agents'),
      );
    });
  });

  // The team-dispatch body dispatches each member (or the leader) into the
  // run's conversation and suspends until the dispatched run(s) complete. The
  // whole team shares that room, and therefore one checkout.
  group('team.dispatch — allParallel dispatch', () {
    test('suspends one run per member', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(
            teamId: teamId,
            prompt: 'Review this PR: {{pr_url}}',
            label: 'Team Review',
          ),
        ),
      );
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      agentRepo.add(_testAgent(agent2Id, 'Bob'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
        TeamMember(teamId: teamId, agentId: agent2Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(
        _ctx(state: {'pr_url': 'https://github.com/foo/bar/pull/42'}),
      );

      expect(result.errorMessage, isNull);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(2));
    });

    test('single-member team suspends one run', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(teamId: teamId, prompt: 'Do the thing'),
        ),
      );
      agentRepo.add(_testAgent(agent1Id, 'Alice'));
      teamRepo.setMembers(teamId, [
        TeamMember(teamId: teamId, agentId: agent1Id),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(1));
    });
  });

  group('team.dispatch — manager mode', () {
    test('suspends a single run for the leader', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(
            teamId: teamId,
            prompt: 'Plan the architecture',
            dispatchMode: 'manager',
            label: 'Architecture Plan',
          ),
        ),
      );
      agentRepo.add(_testAgent(leaderAgentId, 'Lead'));
      teamRepo.setMembers(teamId, [
        TeamMember(
          teamId: teamId,
          agentId: leaderAgentId,
          role: TeamMemberRole.leader,
        ),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.errorMessage, isNull);
      expect(result.isSuspended, isTrue);
      expect(result.suspendUntilTaskIds, hasLength(1));
    });

    test('fails when leader agent not found', () async {
      templateRepo.add(
        _defWithConfig(
          const PipelineNodeConfig(
            teamId: teamId,
            prompt: 'Plan',
            dispatchMode: 'manager',
          ),
        ),
      );
      // leaderAgentId not added to agentRepo.
      teamRepo.setMembers(teamId, [
        TeamMember(
          teamId: teamId,
          agentId: leaderAgentId,
          role: TeamMemberRole.leader,
        ),
      ]);

      final body = registry.body(BuiltInBodyKeys.teamDispatch);
      final result = await body(_ctx());

      expect(result.isFailed, isTrue);
      expect(result.errorMessage, contains('leader agent'));
      expect(result.errorMessage, contains(leaderAgentId));
    });
  });
}
