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
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_server_core/src/space_provisioning_service.dart';
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
  spaceId: 'ch',
  repoId: repoId,
  backend: RepoIsolationBackend.gitWorktree,
  path: '/tmp/wt-$repoId',
  branch: 'conv/ch',
  sourcePath: '/tmp/repo-$repoId',
  createdAt: DateTime(2025),
);

SpaceParticipant _participant(String agentId) => SpaceParticipant(
  id: 'p-$agentId',
  spaceId: 'ch',
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
  late List<(String, SpaceProvisioningStatus)> statusCalls;
  late List<(String, SpaceProvisioningStep)> stepCalls;
  late DomainEventBus eventBus;
  late List<SpaceProvisioningChanged> announced;

  SpaceProvisioningService buildSut({
    Duration timeout = const Duration(minutes: 10),
    Future<List<String>?> Function(String, String)? spaceRepoIds,
  }) {
    statusCalls = [];
    stepCalls = [];
    return SpaceProvisioningService(
      provisioner: provisioner,
      writeMcpConfig: (cwd, {workspaceId, agentId, conversationId}) async {
        provisioner.writtenMcpDirs.add(cwd);
        File('$cwd/.mcp.json').writeAsStringSync('{}');
      },
      agentRepository: agentRepo,
      messagingRepository: messagingRepo,
      workspaceRepository: workspaceRepo,
      isolatedRepoRepository: isolatedRepoRepo,
      setProvisioningStatus: (workspaceId, spaceId, status) async {
        statusCalls.add((spaceId, status));
      },
      setProvisioningStep: (workspaceId, spaceId, step) async {
        stepCalls.add((spaceId, step));
      },
      spaceRepoIds: spaceRepoIds,
      eventBus: eventBus,
      timeout: timeout,
    );
  }

  setUp(() {
    eventBus = DomainEventBus();
    announced = [];
    eventBus.on<SpaceProvisioningChanged>().listen(announced.add);
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

      await service.provision(workspaceId: 'ws', spaceId: 'ch');

      expect(statusCalls, [
        ('ch', SpaceProvisioningStatus.provisioning),
        ('ch', SpaceProvisioningStatus.ready),
      ]);
      expect(provisioner.calls, 0);
    },
  );

  test('short-circuits to ready when the space has no agents', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = const [];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
    expect(provisioner.calls, 0);
  });

  test(
    'checks out nothing when the space explicitly selected no repos',
    () async {
      // A space created with every repo deselected: the selection callback
      // returns an EMPTY list (distinct from null = "no selection, all
      // repos") and the space is ready without a single provisioner call —
      // agents or not.
      workspaceRepo.repos = [_repo('r1'), _repo('r2')];
      messagingRepo.participants = [_participant('a1')];
      agentRepo.agents = {'a1': _agent('a1')};
      final service = buildSut(
        spaceRepoIds: (workspaceId, spaceId) async => const <String>[],
      );

      await service.provision(workspaceId: 'ws', spaceId: 'ch');

      expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
      expect(provisioner.calls, 0);
    },
  );

  test('a null selection provisions every workspace repo', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut(
      spaceRepoIds: (workspaceId, spaceId) async => null,
    );

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
    expect(provisioner.calls, 1);
  });

  test('a subset selection provisions only the selected repos', () async {
    workspaceRepo.repos = [_repo('r1'), _repo('r2')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    // One worktree satisfies verification because only r1 was selected.
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut(
      spaceRepoIds: (workspaceId, spaceId) async => const ['r1'],
    );

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
    expect(provisioner.calls, 1);
  });

  test('reports failed when a worktree is missing', () async {
    workspaceRepo.repos = [_repo('r1'), _repo('r2')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    // Only one worktree for two repos → verification fails.
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.failed));
  });

  test('reports ready when all worktrees + overlays are provisioned', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
    expect(provisioner.calls, 1);
    expect(provisioner.writtenMcpDirs, isNotEmpty);
  });

  test('cancel stops the clone and reports stopped, not failed', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    provisioner.hang = true; // a clone in flight, going nowhere
    final service = buildSut();

    final running = service.provision(workspaceId: 'ws', spaceId: 'ch');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.cancel(workspaceId: 'ws', spaceId: 'ch');
    await running;

    expect(
      provisioner.cancelledSpaces,
      contains('ws/ch'),
      reason: 'the running git command has to be killed, not just awaited',
    );
    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.cancelled));
    expect(
      statusCalls.map((c) => c.$2),
      isNot(contains(SpaceProvisioningStatus.failed)),
      reason: 'work the operator stopped is not a failure',
    );
  });

  test('retrying after a stop clears the mark and provisions again', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    final service = buildSut();

    await service.cancel(workspaceId: 'ws', spaceId: 'ch');
    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(provisioner.cancelledSpaces, isNot(contains('ws/ch')));
    expect(statusCalls.last, ('ch', SpaceProvisioningStatus.ready));
  });

  test(
    'flips to failed when provisioning exceeds the watchdog timeout',
    () async {
      workspaceRepo.repos = [_repo('r1')];
      messagingRepo.participants = [_participant('a1')];
      agentRepo.agents = {'a1': _agent('a1')};
      provisioner.hang = true; // a git fetch that never returns
      final service = buildSut(timeout: const Duration(milliseconds: 50));

      await service.provision(workspaceId: 'ws', spaceId: 'ch');

      expect(statusCalls.first, ('ch', SpaceProvisioningStatus.provisioning));
      expect(statusCalls.last, ('ch', SpaceProvisioningStatus.failed));
    },
  );

  test('publishes agent and repo steps while provisioning', () async {
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    provisioner.reportRepoNames = ['repo-r1'];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', spaceId: 'ch');

    expect(
      stepCalls,
      containsAllInOrder([
        (
          'ch',
          const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.agent,
            subject: 'Architect',
          ),
        ),
        (
          'ch',
          const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'repo-r1',
          ),
        ),
      ]),
    );
  });

  test('announces the same progress on the event bus', () async {
    // The space row is what a client watching the space reads; the bus is
    // how a surface that is not watching a row (the chat bridge's task card)
    // learns a fresh space is still cloning.
    workspaceRepo.repos = [_repo('r1')];
    messagingRepo.participants = [_participant('a1')];
    agentRepo.agents = {'a1': _agent('a1')};
    isolatedRepoRepo.worktrees = [_worktree('r1')];
    provisioner.reportRepoNames = ['repo-r1'];
    final service = buildSut();

    await service.provision(workspaceId: 'ws', spaceId: 'ch');
    await pumpEventQueue();

    expect(
      announced.map((e) => (e.workspaceId, e.spaceId, e.status, e.step)),
      containsAllInOrder([
        ('ws', 'ch', SpaceProvisioningStatus.provisioning, null),
        (
          'ws',
          'ch',
          SpaceProvisioningStatus.provisioning,
          const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.agent,
            subject: 'Architect',
          ),
        ),
        (
          'ws',
          'ch',
          SpaceProvisioningStatus.provisioning,
          const SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.repo,
            subject: 'repo-r1',
          ),
        ),
        ('ws', 'ch', SpaceProvisioningStatus.ready, null),
      ]),
    );
  });
}

class _FakeProvisioner implements RepoWorkspaceProvisionerPort {
  int calls = 0;
  final writtenMcpDirs = <String>[];

  /// When set, [ensureSpaceWorkspace] blocks (a hung git fetch) so the
  /// watchdog-timeout path can be exercised. Cancelling the space releases it,
  /// the way killing the real git process does.
  bool hang = false;
  final Completer<void> _hangGate = Completer<void>();

  /// Repo names to report through `onRepoProvision` (as materializing on the
  /// base branch) when called.
  List<String> reportRepoNames = const [];

  @override
  Future<String> ensureSpaceWorkspace({
    required String workspaceId,
    required String spaceId,
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
    void Function(String repoName)? onRepoSetupScript,
    CancellationToken? cancel,
  }) async {
    calls++;
    if (hang) {
      await _hangGate.future;
      if (isSpaceProvisioningCancelled(workspaceId, spaceId)) {
        return fallbackDir;
      }
    }
    for (final name in reportRepoNames) {
      onRepoProvision?.call(name, prHead: false);
    }
    final dir = await Directory.systemTemp.createTemp('prov-test-');
    return dir.path;
  }

  @override
  void cancelSpaceProvisioning(String workspaceId, String spaceId) {
    cancelledSpaces.add('$workspaceId/$spaceId');
    if (!_hangGate.isCompleted) {
      _hangGate.complete();
    }
  }

  @override
  void clearSpaceProvisioningCancellation(String workspaceId, String spaceId) {
    cancelledSpaces.remove('$workspaceId/$spaceId');
  }

  @override
  bool isSpaceProvisioningCancelled(String workspaceId, String spaceId) =>
      cancelledSpaces.contains('$workspaceId/$spaceId');

  /// Spaces this fake was asked to stop provisioning.
  final Set<String> cancelledSpaces = {};

  @override
  Future<void> releaseSpace({
    required String workspaceId,
    required String spaceId,
  }) async {}

  @override
  Future<void> releaseSpaceReposOutside({
    required String workspaceId,
    required String spaceId,
    required Set<String>? keepRepoIds,
  }) async {}

  @override
  Future<void> releaseSpaceAnyWorkspace({required String spaceId}) async {}

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
  List<SpaceParticipant> participants = const [];

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
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
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId) =>
      Future.value(worktrees);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
