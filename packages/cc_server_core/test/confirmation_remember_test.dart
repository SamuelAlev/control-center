import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show GoalSupervisor;
import 'package:cc_mcp/cc_mcp.dart' show McpToolDispatcher;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// "Approve for 8 hours" writes an expiring, narrow standing approval, no
/// wider than the responder may write, and clears out the expired ones.
void main() {
  const admin = 'ada';
  const member = 'eve';

  late PendingConfirmationRegistry registry;
  late _Policies policies;
  late RepoOpDispatcher dispatcher;

  setUp(() {
    registry = PendingConfirmationRegistry();
    policies = _Policies();
    dispatcher = RepoOpDispatcher(
      registry: _catalog(
        _Port(),
        serverOwnerUserId: null,
        pendingConfirmationRegistry: registry,
        actionPolicyRepository: policies,
      ).ops,
      resolveServerOwner: (_) async => false,
      resolveRole: (_, userId) async =>
          userId == admin ? WorkspaceRole.admin : WorkspaceRole.member,
      mapException: mapAppExceptionToRpc,
    );
  });

  ConfirmationRequest card({bool rememberable = true}) => ConfirmationRequest(
    spaceId: 'space-1',
    workspaceId: 'ws-1',
    agentId: 'agent-1',
    title: 'Agent would like to push to feature/a. Do you accept?',
    detail: 'Approving lets the agent push to feature/a.',
    rememberChoice: rememberable ? RememberScope.workspace : null,
    actionClasses: const ['gitPush'],
    constraintJson: rememberable
        ? const ActionConstraint(refs: ['feature/**']).encode()
        : null,
  );

  Future<Map<String, dynamic>> answer(
    String userId,
    ConfirmationRequest request, {
    String scope = 'space',
  }) {
    final id = registry.register(request).id;
    return dispatcher.call(
      id: 1,
      params: {
        'op': 'confirmation.respond',
        'args': {
          'id': id,
          'approved': true,
          'remember': {'scope': scope, 'ttl_seconds': 8 * 60 * 60},
        },
      },
      deviceId: 'device-$userId',
      userId: userId,
      sessionCapability: SessionCapability.fullClient,
    );
  }

  test('writes an expiring standing approval for the space', () async {
    final before = DateTime.now();
    final reply = await answer(member, card());
    expect(reply['error'], isNull);
    final rule = policies.list.single;
    expect(rule.provenance, 'remembered');
    expect(rule.decision, ActionDecision.allow);
    expect(rule.actionClass, ActionClass.gitPush);
    expect(rule.scopeType, ActionScopeType.space);
    expect(rule.scopeId, 'space-1');
    expect(rule.constraint, const ActionConstraint(refs: ['feature/**']));
    expect(rule.createdBy, member);
    expect(
      rule.expiresAt!.difference(before),
      greaterThanOrEqualTo(const Duration(hours: 8)),
    );
  });

  test('a member cannot write it for the whole workspace', () async {
    await answer(member, card(), scope: 'workspace');
    expect(policies.list.single.scopeType, ActionScopeType.space);
  });

  test('an admin can', () async {
    await answer(admin, card(), scope: 'workspace');
    expect(policies.list.single.scopeType, ActionScopeType.workspace);
  });

  test('nothing is written for a card that offered nothing', () async {
    final reply = await answer(member, card(rememberable: false));
    expect(reply['error'], isNull);
    expect(policies.list, isEmpty);
  });

  ConfirmationRequest unconstrained(List<String> classes) =>
      ConfirmationRequest(
        spaceId: 'space-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        title: 'Agent would like to go ahead. Do you accept?',
        detail: 'Approving lets the agent go ahead.',
        rememberChoice: RememberScope.workspace,
        actionClasses: classes,
      );

  test('a commit is remembered for the space with no constraint', () async {
    await answer(member, unconstrained(const ['gitCommit']));
    final rule = policies.list.single;
    expect(rule.actionClass, ActionClass.gitCommit);
    expect(rule.provenance, 'remembered');
    expect(rule.scopeType, ActionScopeType.space);
    expect(rule.constraint, isNull);
    expect(rule.expiresAt, isNotNull);
  });

  test('no other class is ever remembered without a constraint', () async {
    for (final classes in const [
      ['gitPush'],
      ['prPublish'],
      ['gitCommit', 'gitPush'],
      ['hostExecution'],
    ]) {
      final reply = await answer(member, unconstrained(classes));
      expect(reply['error'], isNull);
    }
    expect(policies.list, isEmpty);
  });

  test('expired standing approvals in the workspace are pruned', () async {
    final now = DateTime.now();
    ActionPolicyRule existing(String id, String provenance, Duration offset) =>
        ActionPolicyRule(
          id: id,
          workspaceId: 'ws-1',
          scopeType: ActionScopeType.space,
          scopeId: 'space-1',
          actionClass: ActionClass.fileDelete,
          decision: ActionDecision.allow,
          provenance: provenance,
          expiresAt: now.add(offset),
          createdAt: now,
          updatedAt: now,
        );
    policies.list.addAll([
      existing('expired', 'remembered', const Duration(hours: -1)),
      existing('live', 'remembered', const Duration(hours: 1)),
      existing('expired-user-rule', 'user', const Duration(hours: -1)),
    ]);
    await answer(member, card());
    final ids = policies.list.map((r) => r.id).toList();
    expect(ids, isNot(contains('expired')));
    expect(ids, containsAll(['live', 'expired-user-rule']));
    expect(ids, hasLength(3));
  });

  group('a card a script\'s call raised', () {
    // End to end through the real registry and `confirmation.respond`: the
    // script ends while its call waits, the card comes down, and an answer
    // that arrives afterwards changes nothing.
    late List<GuardAudit> audits;
    late _Push push;
    late McpToolDispatcher tools;
    final origin = ScriptCallOrigin(
      parentToolCallId: 'toolu_repl',
      executionId: 'log-1/toolu_repl',
    );
    const scope = McpCallScope(
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      attested: true,
      runId: 'dispatch-1',
      runLogId: 'log-1',
    );

    setUp(() {
      audits = [];
      push = _Push();
      final port = RemoteConfirmationPort(registry);
      policies.list.add(
        ActionPolicyRule(
          id: 'ask-push',
          workspaceId: 'ws-1',
          scopeType: ActionScopeType.workspace,
          scopeId: '',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.prompt,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      tools = McpToolDispatcher(
        registry: McpToolRegistry([push]),
        confirmationPort: port,
        actionGuard: ActionGuardService(
          repository: policies,
          confirmationPort: port,
          onAudit: audits.add,
        ),
      );
    });

    /// Starts the script's push and waits until its card is up.
    Future<({Future<NestedCallOutcome> outcome, String cardId})> raise(
      CancellationToken cancel,
    ) async {
      final outcome = tools.callNested(
        scope,
        NestedCallRequest(
          sequence: 1,
          toolCallId: 'toolu_repl/1',
          name: 'push_branch',
          arguments: const {'ref': 'feature/a'},
          origin: origin,
          deadline: const Duration(seconds: 30),
          site: null,
          cancel: cancel,
        ),
        approvals: ScriptApprovalBudget(),
      );
      while (registry.snapshot.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final card = registry.snapshot.single;
      expect(card.request.origin, origin);
      return (outcome: outcome, cardId: card.id);
    }

    Future<Map<String, dynamic>> respond(String id) => dispatcher.call(
      id: 1,
      params: {
        'op': 'confirmation.respond',
        'args': {
          'id': id,
          'approved': true,
          'remember': {'scope': 'space', 'ttl_seconds': 8 * 60 * 60},
        },
      },
      deviceId: 'device-$member',
      userId: member,
      sessionCapability: SessionCapability.fullClient,
    );

    test('answered in time, it runs the call and may be remembered', () async {
      final raised = await raise(CancellationToken.none);
      final reply = await respond(raised.cardId);

      expect((reply['result'] as Map)['data'], {'ok': true});
      expect((await raised.outcome).status, NestedCallStatus.completed);
      expect(push.runs, 1);
      expect(
        policies.list.where((r) => r.provenance == 'remembered'),
        hasLength(1),
      );
    });

    test('is withdrawn when the script ends; a late approve approves '
        'nothing, writes nothing and is audited as a denial', () async {
      final scriptEnd = CancellationTokenSource();
      final raised = await raise(scriptEnd.token);

      scriptEnd.cancel('The script ended.');
      final outcome = await raised.outcome;
      expect(outcome.status, NestedCallStatus.cancelled);
      expect(registry.snapshot, isEmpty, reason: 'the card came down');
      expect(registry.pendingById(raised.cardId), isNull);

      final reply = await respond(raised.cardId);
      // Let anything the answer could have started settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((reply['result'] as Map)['data'], {'ok': false});
      expect(push.runs, 0);
      expect(policies.list.where((r) => r.provenance == 'remembered'), isEmpty);
      final audit = audits.single;
      expect(audit.decision, ActionDecision.deny);
      expect(audit.prompted, isTrue);
    });
  });

  test('a failed prune does not fail the answer', () async {
    policies.failReads = true;
    final reply = await answer(member, card());
    expect(reply['error'], isNull);
    expect((reply['result'] as Map)['data'], {'ok': true});
    expect(policies.list, hasLength(1));
  });
}

/// An in-memory policy store; [failReads] makes listing fail.
class _Policies with _Unused implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];
  bool failReads = false;

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async => list.add(rule);

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    if (failReads) {
      throw StateError('store unavailable');
    }
    return [
      for (final r in list)
        if (r.workspaceId == workspaceId) r,
    ];
  }

  @override
  Future<void> deleteRule(String workspaceId, String id) async =>
      list.removeWhere((r) => r.workspaceId == workspaceId && r.id == id);
}

/// A push tool a script calls; counts the times it ran.
class _Push extends McpTool {
  int runs = 0;

  @override
  String get name => 'push_branch';
  @override
  String get description => 'Pushes a branch.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'ref': {'type': 'string'},
    },
  };
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.gitPush};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    runs++;
    return CallResult.success('pushed');
  }
}

/// Unused: no op here dispatches a run.
class _Port with _Unused implements MessagingPort {}

class _Messaging with _Unused implements MessagingRepository {}

class _ReviewSpaces with _Unused implements ReviewSpaceRepository {}

class _Users with _Unused implements UserRepository {}

/// `ada` administers `ws-1`; everyone else is a member.
class _Members with _Unused implements WorkspaceMembershipRepository {
  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      WorkspaceMember(
        id: 'm-$userId',
        workspaceId: workspaceId,
        userId: userId,
        role: userId == 'ada' ? WorkspaceRole.admin : WorkspaceRole.member,
        joinedAt: DateTime.utc(2026),
      );

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => const [];
}

RemoteRpcCatalog _catalog(
  MessagingPort port, {
  required String? serverOwnerUserId,
  required PendingConfirmationRegistry pendingConfirmationRegistry,
  required ActionPolicyRepository actionPolicyRepository,
}) => buildRemoteRpcCatalog(
  pendingConfirmationRegistry: pendingConfirmationRegistry,
  actionPolicyRepository: actionPolicyRepository,
  serverOwnerUserId: serverOwnerUserId,
  messagingDispatch: port,
  userRepository: _Users(),
  membershipRepository: _Members(),
  inviteRepository: _Invites(),
  userActivityRepository: _Activity(),
  userPreferencesRepository: _Prefs(),
  inviteService: _InviteService(),
  reviewFindingStatus: _ReviewFindingStatus(),
  ticketRepository: _Tickets(),
  projectRepository: _Projects(),
  ticketWorkflow: _TicketWorkflow(),
  messagingRepository: _Messaging(),
  workspaceRepository: _Workspaces(),
  newsfeedRepository: _Newsfeed(),
  agentRepository: _Agents(),
  repoRepository: _Repos(),
  // No workspace databases: no space selections, so the gate exposes nothing.
  spaceRepoAccess: SpaceRepoAccess(
    dbs: null,
    messaging: _Messaging(),
    workspaces: _Workspaces(),
    members: _Members(),
    forgeRead:
        ({required workspaceId, required userId, required repoId}) async {},
  ),
  memoryDomainRepository: _MemoryDomains(),
  memoryAccessGrantRepository: _MemoryGrants(),
  agentWorkingMemoryRepository: _WorkingMemory(),
  memoryFactRepository: _MemoryFacts(),
  memoryPolicyRepository: _MemoryPolicies(),
  reviewSpaceRepository: _ReviewSpaces(),
  agentRunLogRepository: _RunLogs(),
  isolatedRepoRepository: _IsolatedRepos(),
  voiceProfileRepository: _VoiceProfiles(),
  meetingRepository: _Meetings(),
  ticketLinkRepository: _TicketLinks(),
  pipelineRunRepository: _PipelineRuns(),
  pipelineTemplateRepository: _PipelineTemplates(),
  pipelineTriggerRepository: _PipelineTriggers(),
  teamRepository: _Teams(),
  orchestrationRepository: _Orchestrations(),
  goalRepository: _Goals(),
  approvalRepository: _Approvals(),
  agentPresenceService: _Presence(),
  todoRepository: _Todos(),
  notificationFeedRepository: _NotificationFeed(),
  agentGoalRunRepository: _GoalRuns(),
  goalSupervisor: _GoalSupervisor(),
  pairedDeviceDao: _PairedDevices(),
  pairedDeviceSecretsPort: _PairedDeviceSecrets(),
  pairingServerUrl: '',
  calendarRepository: _Calendar(),
  prLifecycleRepositoryFor: (_) => _PrLifecycle(),
);

mixin _Unused {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Invites with _Unused implements WorkspaceInviteRepository {}

class _Activity with _Unused implements UserActivityRepository {}

class _Prefs with _Unused implements UserPreferencesRepository {}

class _InviteService with _Unused implements WorkspaceInviteService {}

class _ReviewFindingStatus with _Unused implements ReviewFindingStatusPort {}

class _Tickets with _Unused implements TicketRepository {}

class _Projects with _Unused implements ProjectRepository {}

class _TicketWorkflow with _Unused implements TicketWorkflowService {}

class _Workspaces with _Unused implements WorkspaceRepository {
  // No repository is linked to the workspace.
  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(const []);
}

class _Newsfeed with _Unused implements NewsfeedRepository {}

class _Agents with _Unused implements AgentRepository {}

class _Repos with _Unused implements RepoRepository {}

class _MemoryDomains with _Unused implements MemoryDomainRepository {}

class _MemoryGrants with _Unused implements MemoryAccessGrantRepository {}

class _WorkingMemory with _Unused implements AgentWorkingMemoryRepository {}

class _MemoryFacts with _Unused implements MemoryFactRepository {}

class _MemoryPolicies with _Unused implements MemoryPolicyRepository {}

class _RunLogs with _Unused implements AgentRunLogRepository {}

class _IsolatedRepos with _Unused implements IsolatedRepoRepository {}

class _VoiceProfiles with _Unused implements VoiceProfileRepository {}

class _Meetings with _Unused implements MeetingRepository {}

class _TicketLinks with _Unused implements TicketLinkRepository {}

class _PipelineRuns with _Unused implements PipelineRunRepository {}

class _PipelineTemplates with _Unused implements PipelineTemplateRepository {}

class _PipelineTriggers with _Unused implements PipelineTriggerRepository {}

class _Teams with _Unused implements TeamRepository {}

class _Orchestrations with _Unused implements OrchestrationRepository {}

class _Goals with _Unused implements GoalRepository {}

class _Approvals with _Unused implements ApprovalRepository {}

class _Presence with _Unused implements AgentPresenceService {}

class _Todos with _Unused implements TodoRepository {}

class _NotificationFeed with _Unused implements NotificationFeedRepository {}

class _GoalRuns with _Unused implements AgentGoalRunRepository {}

class _GoalSupervisor with _Unused implements GoalSupervisor {}

class _PairedDevices with _Unused implements PairedDeviceDao {}

class _PairedDeviceSecrets with _Unused implements PairedDeviceSecretsPort {}

class _Calendar with _Unused implements CalendarRepository {}

class _PrLifecycle with _Unused implements PrLifecycleRepository {}
