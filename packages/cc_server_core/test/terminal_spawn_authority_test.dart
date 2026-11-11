import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
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
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_command_buffer.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show GoalSupervisor;
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// Only the server's owner opens a shell on the host outside a sandbox; for
/// everyone else `terminal.spawn` is a sandboxed shell in the workspace's own
/// directories, and every session op is the opener's alone. A workspace role
/// is no grant on the host: anyone can own a workspace.
void main() {
  const owner = 'olga';

  late _Terminals recorded;
  late RemoteRpcCatalog catalog;

  RemoteRpcCatalog build(TerminalSessionPort terminals) =>
      _catalog(terminals, serverOwnerUserId: owner);

  Future<Map<String, dynamic>> call(
    RemoteRpcCatalog catalog,
    String op,
    String userId,
    Map<String, dynamic> args,
  ) {
    final found = catalog.ops.ops.firstWhere((o) => o.name == op);
    return found.handler(
      RepoOpContext(
        args: args,
        workspaceId: 'ws-1',
        deviceId: 'device-$userId',
        userId: userId,
        role: WorkspaceRole.owner,
      ),
    );
  }

  setUp(() {
    recorded = _Terminals();
    catalog = build(recorded);
  });

  group('the op decides who may use the host shell, from the session', () {
    test('the server owner may', () async {
      await call(catalog, 'terminal.spawn', owner, {'rows': 24, 'cols': 80});
      expect(recorded.spawns.single, (owner, true));
    });

    test('a workspace owner who is not the server owner may not', () async {
      await call(catalog, 'terminal.spawn', 'eve', {
        'rows': 24,
        'cols': 80,
        'backend': 'none',
      });
      expect(recorded.spawns.single, ('eve', false));
    });

    test('with no server owner recorded, nobody may', () async {
      final terminals = _Terminals();
      final bare = _catalog(terminals, serverOwnerUserId: null);
      await call(bare, 'terminal.spawn', owner, {'rows': 24, 'cols': 80});
      expect(terminals.spawns.single, (owner, false));
    });
  });

  test('every session op and stream carries the caller', () async {
    for (final op in ['terminal.write', 'terminal.resize', 'terminal.kill']) {
      await call(catalog, op, 'eve', {
        'session_id': 'tty-1',
        'data': '',
        'rows': 1,
        'cols': 1,
      });
    }
    for (final name in ['terminal.output', 'terminal.titles']) {
      catalog.watch
          .lookup(name)!
          .handler(
            const WatchQueryContext(
              args: {'session_id': 'tty-1'},
              workspaceId: 'ws-1',
              deviceId: 'device-eve',
              userId: 'eve',
            ),
          );
    }
    expect(recorded.users, [
      ('write', 'eve'),
      ('resize', 'eve'),
      ('kill', 'eve'),
      ('output', 'eve'),
      ('titles', 'eve'),
    ]);
  });

  group('through the real terminal service', () {
    late Directory root;
    late Directory outside;
    late _Sandbox sandbox;
    late RemoteRpcCatalog real;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cc-term-auth-');
      outside = Directory.systemTemp.createTempSync('cc-term-outside-');
      addTearDown(() {
        root.deleteSync(recursive: true);
        outside.deleteSync(recursive: true);
      });
      sandbox = _Sandbox();
      real = build(
        TerminalSessionService(manager: sandbox, filesystem: _Fs(root.path)),
      );
    });

    test('a member asking for the host shell is refused', () async {
      await expectLater(
        call(real, 'terminal.spawn', 'eve', {
          'rows': 24,
          'cols': 80,
          'backend': 'none',
        }),
        throwsA(isA<AuthException>()),
      );
      expect(sandbox.wrapped, isEmpty);
    });

    test('a member naming no backend gets the sandbox, in the workspace '
        'directory', () async {
      // The server's default is the host shell; for a member it must be the
      // sandbox. This fake sandbox refuses after recording what it was given.
      await expectLater(
        call(real, 'terminal.spawn', 'eve', {'rows': 24, 'cols': 80}),
        throwsA(isA<UnsupportedError>()),
      );
      final (config, cwd) = sandbox.wrapped.single;
      expect(cwd, root.resolveSymbolicLinksSync());
      // An agent's profile, not the owner's playground: the home rc files
      // are write-denied.
      expect(config.skipMandatoryHomeRcDenies, isFalse);
    });

    test(
      'a member\'s cwd outside the workspace is refused for native',
      () async {
        await expectLater(
          call(real, 'terminal.spawn', 'eve', {
            'rows': 24,
            'cols': 80,
            'backend': 'native',
            'cwd': outside.path,
          }),
          throwsA(isA<ValidationException>()),
        );
        expect(sandbox.wrapped, isEmpty);
      },
    );

    test('the owner\'s sandboxed shell is confined too', () async {
      await expectLater(
        call(real, 'terminal.spawn', owner, {
          'rows': 24,
          'cols': 80,
          'backend': 'native',
          'cwd': outside.path,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

/// Records what the ops hand the port.
class _Terminals implements TerminalSessionPort {
  @override
  ({String? spaceId})? ownedSessionOf(String sessionId) => null;

  @override
  String? openerOf(String sessionId) => null;

  final spawns = <(String, bool)>[];
  final users = <(String, String)>[];

  @override
  Future<String> spawn({
    required String workspaceId,
    required String actingUserId,
    required bool hostShellAllowed,
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
  }) async {
    spawns.add((actingUserId, hostShellAllowed));
    return 'tty-1';
  }

  @override
  String? backendOf(String sessionId) => null;

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) {
    users.add(('output', userId));
    return const Stream.empty();
  }

  @override
  Stream<String> titles({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) {
    users.add(('titles', userId));
    return const Stream.empty();
  }

  @override
  Future<TerminalWriteResult> write({
    required String workspaceId,
    required String userId,
    required String sessionId,
    required List<int> data,
  }) async {
    users.add(('write', userId));
    return TerminalWriteResult.none;
  }

  @override
  Future<void> resize({
    required String workspaceId,
    required String userId,
    required String sessionId,
    required int rows,
    required int cols,
  }) async => users.add(('resize', userId));

  @override
  Future<void> kill({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) async => users.add(('kill', userId));
}

/// A sandbox that records what it was asked to wrap and runs nothing.
class _Sandbox extends SandboxManager {
  _Sandbox() : super(hiddenPaths: const []);

  final wrapped = <(SandboxConfig, String?)>[];

  @override
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async {
    wrapped.add((config, workingDirectory));
    throw UnsupportedError('no sandbox in this test');
  }
}

class _Fs implements WorkspaceFilesystemPort {
  _Fs(this.root);

  final String root;

  @override
  Future<String> workspaceDir(String workspaceId) async => root;

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<String> ensureSpaceDir(String workspaceId, String spaceId) async =>
      root;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RemoteRpcCatalog _catalog(
  TerminalSessionPort terminals, {
  required String? serverOwnerUserId,
}) => buildRemoteRpcCatalog(
  serverOwnerUserId: serverOwnerUserId,
  terminalSessions: terminals,
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
    members: null,
    forgeRead:
        ({required workspaceId, required userId, required repoId}) async {},
  ),
  spaceReadRepository: _SpaceReads(),
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

class _ReviewFindingStatus with _Unused implements ReviewFindingStatusPort {}

class _Tickets with _Unused implements TicketRepository {}

class _Projects with _Unused implements ProjectRepository {}

class _TicketWorkflow with _Unused implements TicketWorkflowService {}

class _Messaging with _Unused implements MessagingRepository {}

class _Workspaces with _Unused implements WorkspaceRepository {}

class _Newsfeed with _Unused implements NewsfeedRepository {}

class _Agents with _Unused implements AgentRepository {}

class _Repos with _Unused implements RepoRepository {}

class _SpaceReads with _Unused implements SpaceReadRepository {}

class _MemoryDomains with _Unused implements MemoryDomainRepository {}

class _MemoryGrants with _Unused implements MemoryAccessGrantRepository {}

class _WorkingMemory with _Unused implements AgentWorkingMemoryRepository {}

class _MemoryFacts with _Unused implements MemoryFactRepository {}

class _MemoryPolicies with _Unused implements MemoryPolicyRepository {}

class _ReviewSpaces with _Unused implements ReviewSpaceRepository {}

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
