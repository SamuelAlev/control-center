import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';
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
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
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

/// An editor launched on the host runs as the server's OS user outside any
/// sandbox, so listing, and opening a worktree in, the host's editors is the
/// server owner's; a workspace admin is no grant on the host. Even the owner
/// opens a PR only of a repository linked to the workspace, and no worktree is
/// made for a refused call.
void main() {
  const owner = 'olga';
  const member = 'eve';

  late _Launcher launcher;
  late _EnsuredWorktrees worktrees;
  late RepoOpDispatcher dispatcher;

  setUp(() {
    launcher = _Launcher();
    worktrees = _EnsuredWorktrees();
    final repos = _IsolatedRepos(
      IsolatedRepo(
        id: 'worktree',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        repoId: 'repo-1',
        path: '/srv/worktrees/space-1',
        branch: 'main',
        backend: RepoIsolationBackend.rift,
        sourcePath: '/srv/source',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    dispatcher = RepoOpDispatcher(
      registry: _catalog(
        launcher,
        worktrees,
        repos,
        serverOwnerUserId: owner,
      ).ops,
      resolveServerOwner: (userId) async => userId == owner,
      // Both are admins of the workspace; only one owns the server.
      resolveRole: (_, _) async => WorkspaceRole.admin,
      mapException: mapAppExceptionToRpc,
    );
  });

  Future<Map<String, dynamic>> call(
    String userId,
    String op, [
    Map<String, dynamic> args = const {},
  ]) => dispatcher.call(
    id: 1,
    params: {
      'op': op,
      'args': {'workspace_id': 'ws-1', ...args},
    },
    deviceId: 'device-$userId',
    userId: userId,
    sessionCapability: SessionCapability.fullClient,
  );

  const openPr = {
    'repo_full_name': 'octo/repo',
    'pr_number': 7,
    'pr_external_id': 'PR_node',
    'editor_id': 'vscode',
  };
  const openSpace = {
    'space_id': 'space-1',
    'repo_id': 'repo-1',
    'editor_id': 'vscode',
  };

  test('a workspace admin who is not the server owner is refused, and no '
      'editor starts and no worktree is made', () async {
    for (final MapEntry(key: op, value: args) in {
      'ide.detectEditors': const <String, dynamic>{},
      'ide.openPrInEditor': openPr,
      'ide.openSpaceWorktree': openSpace,
    }.entries) {
      final error = (await call(member, op, args))['error'] as Map?;
      expect(error?['code'], RpcErrorCodes.unauthorized, reason: op);
      expect(
        (error?['data'] as Map?)?['kind'],
        'server_owner_required',
        reason: op,
      );
    }
    expect(launcher.detected, 0);
    expect(launcher.opened, isEmpty);
    expect(worktrees.requested, isEmpty);
  });

  test('the server owner lists the editors and opens a conversation '
      'worktree', () async {
    final listed = await call(owner, 'ide.detectEditors');
    expect(
      (((listed['result'] as Map)['data'] as Map)['editors'] as List).single,
      containsPair('id', 'vscode'),
    );
    final opened = await call(owner, 'ide.openSpaceWorktree', openSpace);
    expect(opened['error'], isNull);
    expect(launcher.opened, ['/srv/worktrees/space-1']);
  });

  test('even the server owner opens no PR of a repository the workspace '
      'has not linked', () async {
    final error =
        (await call(owner, 'ide.openPrInEditor', openPr))['error'] as Map?;
    expect(error?['code'], RpcErrorCodes.workspaceMismatch);
    expect(worktrees.requested, isEmpty);
    expect(launcher.opened, isEmpty);
  });
}

class _IsolatedRepos with _Unused implements IsolatedRepoRepository {
  _IsolatedRepos(this.worktree);

  final IsolatedRepo worktree;

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => workspaceId == worktree.workspaceId && spaceId == worktree.spaceId
      ? [worktree]
      : const [];

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async =>
      workspaceId == worktree.workspaceId &&
          spaceId == worktree.spaceId &&
          repoId == worktree.repoId
      ? worktree
      : null;
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
  EditorLauncherPort launcher,
  _EnsuredWorktrees worktrees,
  IsolatedRepoRepository isolatedRepos, {
  required String? serverOwnerUserId,
}) => buildRemoteRpcCatalog(
  serverOwnerUserId: serverOwnerUserId,
  editorLauncher: launcher,
  ensurePrWorktree: worktrees.ensure,
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
  isolatedRepoRepository: isolatedRepos,
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

class _Messaging with _Unused implements MessagingRepository {}

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

class _ReviewSpaces with _Unused implements ReviewSpaceRepository {}

class _RunLogs with _Unused implements AgentRunLogRepository {}

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

/// Records what it was asked to open; starts nothing.
class _Launcher implements EditorLauncherPort {
  final opened = <String>[];
  int detected = 0;

  @override
  Future<List<IdeEditor>> detectEditors() async {
    detected++;
    return const [
      IdeEditor(id: 'vscode', displayName: 'VS Code', installed: true),
    ];
  }

  @override
  Future<void> openDirectory({
    required String editorId,
    required String directoryPath,
  }) async => opened.add(directoryPath);
}

/// Records each PR worktree it was asked for; makes none.
class _EnsuredWorktrees {
  final requested = <String>[];

  Future<String> ensure({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title = '',
    String? repoId,
  }) async {
    requested.add(repoFullName);
    return '/srv/worktrees/$repoFullName';
  }
}
