import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';
import 'package:cc_server_core/src/channel_provisioning_service.dart';
import 'package:test/test.dart';

Agent _agent(String id, {String name = 'Architect'}) => Agent(
  id: id,
  name: name,
  title: name,
  agentMdPath: '/tmp/$id/AGENTS.md',
  workspaceId: 'ws',
  createdAt: DateTime(2025),
  skills: AgentSkills(const []),
);

Repo _repo(String id) => Repo(
  id: id,
  name: 'repo-$id',
  path: '/tmp/repo-$id',
  remoteOwner: 'owner',
  remoteName: 'repo-$id',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

IsolatedRepo _worktree(String repoId) => IsolatedRepo(
  id: 'wt-$repoId',
  workspaceId: 'ws',
  channelId: 'ch',
  repoId: repoId,
  backend: RepoIsolationBackend.gitWorktree,
  path: '/tmp/wt-$repoId',
  branch: 'conv/ch',
  sourcePath: '/tmp/repo-$repoId',
  createdAt: DateTime(2025),
);

ChannelParticipant _participant(String agentId) => ChannelParticipant(
  id: 'p-$agentId',
  channelId: 'ch',
  principalId: agentId,
  participantType: PrincipalType.agent,
  role: 'member',
  joinedAt: DateTime(2025),
);

void main() {
  late _FakeProvisioner provisioner;
  late _FakeAgentRepo agentRepo;
  late _FakeMessagingRepo messagingRepo;
  late _FakeWorkspaceRepo workspaceRepo;
  late _FakeIsolatedRepoRepo isolatedRepoRepo;
  late List<(String, ChannelProvisioningStatus)> statusCalls;
  late List<(String, ChannelProvisioningStep)> stepCalls;
  late DomainEventBus eventBus;
  late List<ChannelProvisioningChanged> announced;

  ChannelProvisioningService buildSut({
    Duration timeout = const Duration(minutes: 10),
  }) {
    statusCalls = [];
    stepCalls = [];
    return ChannelProvisioningService(
      provisioner: provisioner,
      writeMcpConfig: (cwd, {workspaceId, agentId, conversationId}) async {
        provisioner.writtenMcpDirs.add(cwd);
        File('$cwd/.mcp.json').writeAsStringSync('{}');
      },
      agentRepository: agentRepo,
      messagingRepository: messagingRepo,
      workspaceRepository: workspaceRepo,
      isolatedRepoRepository: isolatedRepoRepo,
      setProvisioningStatus: (workspaceId, channelId, status) async {
        statusCalls.add((channelId, status));
      },
      setProvisioningStep: (workspaceId, channelId, step) async {
        stepCalls.add((channelId, step));
      },
      eventBus: eventBus,
      timeout: timeout,
    );
  }

  setUp(() {
    eventBus = DomainEventBus();
    announced = [];
    eventBus.on<ChannelProvisioningChanged>().listen(announced.add);
    provisioner = _FakeProvisioner();
    agentRepo = _FakeAgentRepo();
    messagingRepo = _FakeMessagingRepo();
    workspaceRepo = _FakeWorkspaceRepo();
    isolatedRepoRepo = _FakeIsolatedRepoRepo();
  });

  test(
    'short-circuits to ready when the workspace has no linked repos',
    () async {
      workspaceRepo.repos = const [];
      final service = buildSut();

      await service.provision(workspaceId: 'ws', channelId: 'ch');

      expect(statusCalls, [
        ('ch', ChannelProvisioningStatus.provisioning),
        ('ch', ChannelProvisioningStatus.ready),
      ]);
      expect(provisioner.calls, 0);
    },
  );

  test('short-circuits to ready when the channel has no agents', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = const [];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', channelId: 'ch');

    expect(statusCalls.last, ('ch', ChannelProvisioningStatus.ready));
    expect(provisioner.calls, 0);
  });

  test('reports failed when a worktree is missing', () async {
    workspaceRepo.repos = [_repo('r1'), _repo('r2')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    // Only one worktree for two repos → verification fails.
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', channelId: 'ch');

    expect(statusCalls.last, ('ch', ChannelProvisioningStatus.failed));
  });

  test('reports ready when all worktrees + overlays are provisioned', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', channelId: 'ch');

    expect(statusCalls.last, ('ch', ChannelProvisioningStatus.ready));
    expect(provisioner.calls, 1);
    expect(provisioner.writtenMcpDirs, isNotEmpty);
  });

  test(
    'flips to failed when provisioning exceeds the watchdog timeout',
    () async {
      workspaceRepo.repos = [_repo('r1')];
      messagingRepo.participants = [_participant('a1')];
      agentRepo.agents = {'a1': _agent('a1')};
      provisioner.hang = true; // a git fetch that never returns
      final service = buildSut(timeout: const Duration(milliseconds: 50));

      await service.provision(workspaceId: 'ws', channelId: 'ch');

      expect(statusCalls.first, ('ch', ChannelProvisioningStatus.provisioning));
      expect(statusCalls.last, ('ch', ChannelProvisioningStatus.failed));
    },
  );

  test('publishes agent and repo steps while provisioning', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    provisioner.reportRepoNames = ['repo-r1'];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', channelId: 'ch');

    expect(
      stepCalls,
      containsAllInOrder([
        (
          'ch',
          const ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.agent,
            subject: 'Architect',
          ),
        ),
        (
          'ch',
          const ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.repo,
            subject: 'repo-r1',
          ),
        ),
      ]),
    );
  });

  test('announces the same progress on the event bus', () async {
    // The channel row is what a client watching the channel reads; the bus is
    // how a surface that is not watching a row (the chat bridge's task card)
    // learns a fresh channel is still cloning.
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    provisioner.reportRepoNames = ['repo-r1'];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', channelId: 'ch');
    await pumpEventQueue();

    expect(
      announced.map((e) => (e.workspaceId, e.channelId, e.status, e.step)),
      containsAllInOrder([
        ('ws', 'ch', ChannelProvisioningStatus.provisioning, null),
        (
          'ws',
          'ch',
          ChannelProvisioningStatus.provisioning,
          const ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.agent,
            subject: 'Architect',
          ),
        ),
        (
          'ws',
          'ch',
          ChannelProvisioningStatus.provisioning,
          const ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.repo,
            subject: 'repo-r1',
          ),
        ),
        ('ws', 'ch', ChannelProvisioningStatus.ready, null),
      ]),
    );
  });
}

class _FakeProvisioner implements RepoWorkspaceProvisionerPort {
  int calls = 0;
  final writtenMcpDirs = <String>[];

  /// When set, [ensureConversationWorkspace] never completes (a hung git
  /// fetch) so the watchdog-timeout path can be exercised.
  bool hang = false;

  /// Repo names to report through `onRepoProvision` (as materializing on the
  /// base branch) when called.
  List<String> reportRepoNames = const [];

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String agentSlug,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
    String? prHeadRef,
    String? prHeadRepoFullName,
    String? prBranch,
    Set<String>? repoAllowlist,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
  }) async {
    calls++;
    if (hang) {
      await Completer<void>().future;
    }
    for (final name in reportRepoNames) {
      onRepoProvision?.call(name, prHead: false);
    }
    final dir = await Directory.systemTemp.createTemp('prov-test-');
    return dir.path;
  }

  @override
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  }) async {}

  @override
  Future<void> releaseConversationAnyWorkspace({
    required String channelId,
  }) async {}

  @override
  Future<void> releaseTicket({required String ticketId}) async {}

  @override
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  }) async => 0;

  @override
  Future<int> sweepStale({required String workspaceId}) async => 0;
}

class _FakeAgentRepo implements AgentRepository {
  Map<String, Agent> agents = {};

  @override
  Future<Agent?> getById(String workspaceId, String id) async => agents[id];

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => null;

  @override
  Stream<List<Agent>> watchAll() => Stream.value(const []);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(agents.values.toList());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessagingRepo implements MessagingRepository {
  List<ChannelParticipant> participants = const [];

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaceRepo implements WorkspaceRepository {
  List<Repo> repos = const [];

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIsolatedRepoRepo implements IsolatedRepoRepository {
  List<IsolatedRepo> worktrees = const [];

  @override
  Future<List<IsolatedRepo>> forChannel(String workspaceId, String channelId) =>
      Future.value(worktrees);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
