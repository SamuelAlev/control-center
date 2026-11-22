import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
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
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
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
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show GoalSupervisor;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// A run acts for the person who asked for it: it commits as them and pushes
/// on their own sign-in. So every op a person starts or feeds a run with has
/// to hand the session's user to the messaging port. One that does not makes
/// the run nobody's (the bot's commits, and no push where the bot may not
/// push), and one that falls back to the owner runs a member's words with
/// the owner's sign-in.
void main() {
  const owner = 'olga';
  const member = 'eve';

  late _Port port;
  late RepoOpDispatcher dispatcher;

  setUp(() {
    port = _Port();
    dispatcher = RepoOpDispatcher(
      registry: _catalog(port, serverOwnerUserId: owner).ops,
      resolveServerOwner: (userId) async => userId == owner,
      resolveRole: (_, _) async => WorkspaceRole.member,
      mapException: mapAppExceptionToRpc,
    );
  });

  Future<Map<String, dynamic>> call(
    String userId,
    String op,
    Map<String, dynamic> args,
  ) => dispatcher.call(
    id: 1,
    params: {
      'op': op,
      'args': {'workspace_id': 'ws-1', 'space_id': 'space-1', ...args},
    },
    deviceId: 'device-$userId',
    userId: userId,
    sessionCapability: SessionCapability.fullClient,
  );

  test('a retried turn runs for the member who pressed Retry', () async {
    final answer = await call(member, 'dispatch.retryAgentTurn', {
      'failed_message_id': 'm-1',
    });
    expect(answer['error'], isNull);
    expect(port.retriedFor, [member]);
  });

  test('plan feedback is its author\'s, and so is the refining run', () async {
    final answer = await call(member, 'dispatch.refinePlan', {
      'feedback': 'Make it shorter',
    });
    expect(answer['error'], isNull);
    expect(port.refinedBy, [member]);
  });

  test(
    'a queued message is stored as its author\'s, never the owner\'s',
    () async {
      final answer = await call(member, 'steering.enqueue', {
        'conversation_id': 'conv-1',
        'message': 'also update the docs',
      });
      expect(answer['error'], isNull);
      expect(port.queuedBy, [member]);
    },
  );

  test('a client cannot name someone else as the person', () async {
    for (final MapEntry(key: op, value: args) in {
      'dispatch.retryAgentTurn': {
        'failed_message_id': 'm-1',
        'requested_by_user_id': owner,
      },
      'dispatch.refinePlan': {'feedback': 'x', 'sender_user_id': owner},
      'steering.enqueue': {
        'conversation_id': 'conv-1',
        'message': 'x',
        'sender_user_id': owner,
      },
    }.entries) {
      expect((await call(member, op, args))['error'], isNull, reason: op);
    }
    expect(port.retriedFor, [member]);
    expect(port.refinedBy, [member]);
    expect(port.queuedBy, [member]);
  });
}

/// Records whom each call was made for.
class _Port with _Unused implements MessagingPort {
  final retriedFor = <String?>[];
  final refinedBy = <String?>[];
  final queuedBy = <String?>[];

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
    String? requestedByUserId,
  }) async => retriedFor.add(requestedByUserId);

  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String spaceId,
    required String feedback,
    String? senderUserId,
  }) async => refinedBy.add(senderUserId);

  @override
  Future<({String messageId, bool steerable})?> enqueueSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    String? senderUserId,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    queuedBy.add(senderUserId);
    return (messageId: 'steer-1', steerable: false);
  }
}

/// One space, in `ws-1`.
class _Messaging with _Unused implements MessagingRepository {
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async =>
      workspaceId == 'ws-1' && spaceId == 'space-1'
      ? Space(
          id: spaceId,
          name: 'Space',
          workspaceId: workspaceId,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        )
      : null;
}

/// No space reviews a pull request.
class _ReviewSpaces with _Unused implements ReviewSpaceRepository {
  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(const []);
}

class _Users with _Unused implements UserRepository {
  @override
  Future<User?> getById(String id) async =>
      User(id: id, handle: id, displayName: id, createdAt: DateTime.utc(2026));
}

class _Members with _Unused implements WorkspaceMembershipRepository {
  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      null;

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => const [];
}

RemoteRpcCatalog _catalog(
  MessagingPort port, {
  required String? serverOwnerUserId,
}) => buildRemoteRpcCatalog(
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
