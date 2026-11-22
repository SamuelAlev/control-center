// The code-server stand-in is a POSIX shell script.
@TestOn('!windows')
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
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
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/ide/domain/code_server_port.dart';
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
import 'package:cc_infra/src/ide/code_server_service.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// The embedded editor runs as the server's OS user, so only the server owner
/// may open or drive it; a workspace admin is no grant on the host. A session
/// belongs to its opener, VS Code's workspace trust stays on and a folder's
/// tasks never start on their own.
void main() {
  const owner = 'olga';
  const member = 'eve';

  late Directory tmp;
  late CodeServerService service;
  late RepoOpDispatcher dispatcher;
  late RemoteRpcCatalog catalog;

  File launches() => File('${tmp.path}/launches');

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_code_server_authority');
    final worktree = Directory('${tmp.path}/worktree')..createSync();
    final os = Platform.isMacOS ? 'darwin' : 'linux';
    final uname = Process.runSync('uname', ['-m']).stdout as String;
    final arch = uname.contains('arm64') || uname.contains('aarch64')
        ? 'arm64'
        : 'x64';
    // Records each launch's argv, one argument per line, then a separator.
    final bin = File('${tmp.path}/code-server/$os-$arch/bin/code-server')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '#!/bin/sh\n'
        'case "\$*" in *--install-extension*) exit 0;; esac\n'
        'for a in "\$@"; do printf "%s\\n" "\$a"; done >> "${tmp.path}/launches"\n'
        'echo "--" >> "${tmp.path}/launches"\n'
        'echo "HTTP server listening on http://127.0.0.1:45678/"\n'
        'exec sleep 60\n',
      );
    Process.runSync('chmod', ['755', bin.path]);
    for (final ext in codeServerCuratedExtensions) {
      Directory(
        '${tmp.path}/code-server/extensions/'
        '${ext.publisher}.${ext.name}-${ext.version}',
      ).createSync(recursive: true);
    }
    final repos = _IsolatedRepos(
      IsolatedRepo(
        id: 'worktree',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        repoId: 'repo-1',
        path: worktree.path,
        branch: 'main',
        backend: RepoIsolationBackend.rift,
        sourcePath: '${tmp.path}/source',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    service = CodeServerService(
      isolatedRepos: repos,
      dataRoot: tmp.path,
      attemptManagedDownload: false,
    );
    catalog = _catalog(service, repos, serverOwnerUserId: owner);
    dispatcher = RepoOpDispatcher(
      registry: catalog.ops,
      resolveServerOwner: (userId) async => userId == owner,
      // Both are admins of the workspace; only one owns the server.
      resolveRole: (_, _) async => WorkspaceRole.admin,
    );
    addTearDown(() async {
      await service.disposeAll();
      tmp.deleteSync(recursive: true);
    });
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

  test('a workspace admin who is not the server owner is refused, and told '
      'why', () async {
    final ops = {
      'codeServer.open': {
        'space_id': 'space-1',
        'repo_id': 'repo-1',
        'auto_save': 'afterDelay',
      },
      'codeServer.saveFile': {'space_id': 'space-1', 'path': 'a.dart'},
      'codeServer.close': {'session_id': 'whatever'},
      'codeServer.openFile': {
        'space_id': 'space-1',
        'window_id': 'w',
        'path': 'a.dart',
      },
      'codeServer.closeFile': {'space_id': 'space-1', 'path': 'a.dart'},
    };
    for (final MapEntry(key: op, value: args) in ops.entries) {
      final res = await call(member, op, args);
      final error = res['error'] as Map?;
      expect(error?['code'], RpcErrorCodes.unauthorized, reason: op);
      expect(
        (error?['data'] as Map?)?['kind'],
        'server_owner_required',
        reason: op,
      );
    }
    expect(launches().existsSync(), isFalse);
    for (final name in [
      'codeServer.watchOpenRequests',
      'codeServer.watchDirtyState',
    ]) {
      expect(
        catalog.watch.lookup(name)!.serverAuthority,
        ServerAuthority.serverOwner,
        reason: name,
      );
    }
  });

  test('the server owner opens the editor, bound to them', () async {
    final res = await call(owner, 'codeServer.open', {
      'space_id': 'space-1',
      'repo_id': 'repo-1',
      'auto_save': 'afterDelay',
    });
    final result = (res['result'] as Map)['data'] as Map<String, dynamic>;
    expect(result['status'], 'ready');
    final sessionId = result['session_id'] as String;
    // At least 96 random bits, URL-safe.
    expect(sessionId.length, greaterThanOrEqualTo(16));
    final session = service.lookup(sessionId)!;
    expect(session.userId, owner);
    expect(session.deviceId, 'device-$owner');
  });

  test('a reassigned device gets a fresh capability, never the previous '
      'user\'s', () async {
    final first = await service.ensureSession(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      repoId: 'repo-1',
      deviceId: 'device-shared',
      userId: owner,
    );
    final again = await service.ensureSession(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      repoId: 'repo-1',
      deviceId: 'device-shared',
      userId: owner,
    );
    final other = await service.ensureSession(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      repoId: 'repo-1',
      deviceId: 'device-shared',
      userId: member,
    );
    expect(again.sessionId, first.sessionId);
    expect(other.sessionId, isNot(first.sessionId));
    expect(service.lookup(other.sessionId)!.userId, member);
    // The previous user's capability is revoked, not handed over.
    expect(service.lookup(first.sessionId), isNull);
  });

  test(
    'workspace trust stays on and tasks never start automatically',
    () async {
      // A settings file an earlier server seeded with trust turned off.
      final settings = File('${tmp.path}/code-server/ws-1/User/settings.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'security.workspace.trust.enabled': false,
            'security.workspace.trust.startupPrompt': 'never',
            'security.workspace.trust.banner': 'never',
            'security.workspace.trust.emptyWindow': false,
            'editor.fontSize': 15,
          }),
        );

      await call(owner, 'codeServer.open', {
        'space_id': 'space-1',
        'repo_id': 'repo-1',
        'auto_save': 'afterDelay',
      });

      final seeded =
          jsonDecode(settings.readAsStringSync()) as Map<String, dynamic>;
      expect(seeded['security.workspace.trust.enabled'], isTrue);
      expect(seeded['task.allowAutomaticTasks'], 'off');
      for (final key in [
        'security.workspace.trust.startupPrompt',
        'security.workspace.trust.banner',
        'security.workspace.trust.emptyWindow',
      ]) {
        expect(seeded.containsKey(key), isFalse, reason: key);
      }
      expect(seeded['editor.fontSize'], 15);

      final argv = launches().readAsLinesSync();
      expect(argv, contains('--user-data-dir'));
      expect(argv.where((a) => a.contains('trust')), isEmpty);
    },
  );

  test(
    'identity.me tells only the server owner they can use the host',
    () async {
      final mine = await call(owner, 'identity.me');
      expect(((mine['result'] as Map)['data'] as Map)['can_use_host'], isTrue);
      final theirs = await call(member, 'identity.me');
      expect(
        ((theirs['result'] as Map)['data'] as Map)['can_use_host'],
        isFalse,
      );
    },
  );

  test('identity.me names the identity provider the caller is pinned to, '
      'never the subject', () async {
    final pinned = await call(owner, 'identity.me');
    final pinnedData = (pinned['result'] as Map)['data'] as Map;
    expect(pinnedData['sso_issuer'], 'https://idp.example');
    expect(jsonEncode(pinnedData), isNot(contains('subject-olga')));
    final unpinned = await call(member, 'identity.me');
    expect(
      ((unpinned['result'] as Map)['data'] as Map).containsKey('sso_issuer'),
      isFalse,
    );
  });
}

class _IsolatedRepos with _Unused implements IsolatedRepoRepository {
  _IsolatedRepos(this.worktree);

  final IsolatedRepo worktree;

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
  // The server owner signs in through an identity provider; the member, with
  // a blank pin, does not.
  @override
  Future<User?> getById(String id) async => User(
    id: id,
    handle: id,
    displayName: id,
    ssoIssuer: id == 'olga' ? 'https://idp.example' : '',
    ssoSubject: id == 'olga' ? 'subject-olga' : null,
    createdAt: DateTime.utc(2026),
  );
}

class _Members with _Unused implements WorkspaceMembershipRepository {
  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      null;

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => const [];
}

RemoteRpcCatalog _catalog(
  CodeServerPort codeServer,
  IsolatedRepoRepository isolatedRepos, {
  required String? serverOwnerUserId,
}) => buildRemoteRpcCatalog(
  serverOwnerUserId: serverOwnerUserId,
  codeServer: codeServer,
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

class _Workspaces with _Unused implements WorkspaceRepository {}

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
