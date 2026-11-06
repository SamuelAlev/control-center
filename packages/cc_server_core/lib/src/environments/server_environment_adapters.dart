import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/rigs/domain/ports/host_window_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart'
    show RigCloseReason;
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_mcp/cc_mcp.dart'
    show
        EnvironmentDestroyTool,
        EnvironmentDownTool,
        EnvironmentExecTool,
        EnvironmentLaunchAppTool,
        EnvironmentLogsTool,
        EnvironmentResetTool,
        EnvironmentRestartTool,
        EnvironmentRunTaskTool,
        EnvironmentStatusTool,
        EnvironmentStopAppTool,
        EnvironmentUpTool;
import 'package:cc_natives/cc_natives.dart'
    show RigWorktreeGuard, RigWorktreeTampered;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoEnvironmentDefinitionRepository,
        DaoEnvironmentLeaseRepository,
        DaoEnvironmentRunRepository,
        DaoReviewSpaceRepository,
        DaoSpaceEnvironmentRepository,
        GlobalDatabase,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:cc_server_core/src/space_provisioning_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// The provisioner exists long before the environment service does, so it
/// holds this and the runtime fills it in.
class LateWorktreeTasks implements WorktreeTaskPort {
  /// The real implementation, once it exists.
  WorktreeTaskPort? target;

  @override
  Future<bool> hasProvisionTasks(String workspaceId, String repoId) async =>
      await target?.hasProvisionTasks(workspaceId, repoId) ?? false;

  @override
  Future<Set<String>> reposWithEnvironments(String workspaceId) async =>
      await target?.reposWithEnvironments(workspaceId) ?? const {};

  @override
  Future<void> runProvision(
    WorktreeTaskContext context, {
    void Function(String line)? onOutput,
  }) async => target?.runProvision(context, onOutput: onOutput);

  @override
  Future<void> runArchive(WorktreeTaskContext context) async =>
      target?.runArchive(context);

  @override
  Future<void> beforeRelease(String workspaceId, String spaceId) async =>
      target?.beforeRelease(workspaceId, spaceId);
}

/// Whether a pull request's code comes from outside its base repo.
typedef EnvironmentForkLookup =
    Future<bool> Function(
      String workspaceId,
      String repoFullName,
      int prNumber,
    );

/// Spaces and repos as the environment service sees them.
class ServerEnvironmentDirectory implements EnvironmentSpaceDirectory {
  /// Creates a [ServerEnvironmentDirectory].
  ServerEnvironmentDirectory({
    required this._messaging,
    required this._repos,
    required this._isolated,
    required this._reviewSpaces,
    required this._workspaceIds,
    required this._isFork,
    required this._provision,
  });

  final MessagingRepository _messaging;
  final RepoRepository _repos;
  final IsolatedRepoRepository _isolated;
  final DaoReviewSpaceRepository _reviewSpaces;
  final Future<List<String>> Function() _workspaceIds;
  final EnvironmentForkLookup _isFork;
  final Future<void> Function(String workspaceId, String spaceId) _provision;

  /// Fork status never changes for a pull request, and this runs on every
  /// environment operation, so a positive lookup is kept. A failed lookup is
  /// not, so it can recover.
  final Map<String, bool> _forks = {};

  @override
  Future<List<String>> workspaceIds() => _workspaceIds();

  @override
  Future<EnvironmentSpaceInfo> space(String workspaceId, String spaceId) async {
    final space = await _messaging.getSpaceById(workspaceId, spaceId);
    if (space == null) {
      // Scoped lookup: a space of another workspace is indistinguishable from
      // one that does not exist, and scanning other workspaces to tell them
      // apart is exactly what isolation forbids.
      throw const NotFoundException('Space not found in this workspace');
    }
    final rows = await _isolated.forSpace(workspaceId, spaceId);
    final repos = <EnvironmentSpaceRepo>[];
    for (final row in rows) {
      final repo = await _repos.getById(workspaceId, row.repoId);
      if (repo == null) {
        continue;
      }
      repos.add(
        EnvironmentSpaceRepo(
          repoId: row.repoId,
          name: repo.name,
          slug: p.basename(row.path),
          worktreePath: row.path,
          sourcePath: repo.path,
          branch: row.branch,
        ),
      );
    }
    final review = await _reviewSpaces.watchBySpace(workspaceId, spaceId).first;
    final branch = repos.isEmpty
        ? space.name
        : repos.first.branch ?? space.name;
    if (review == null) {
      return EnvironmentSpaceInfo(
        id: spaceId,
        workspaceId: workspaceId,
        name: space.name,
        branch: branch,
        repos: repos,
      );
    }
    final head = repos.isEmpty ? null : await _headOf(repos.first.worktreePath);
    return EnvironmentSpaceInfo(
      id: spaceId,
      workspaceId: workspaceId,
      name: space.name,
      branch: branch,
      kind: 'pr',
      repos: repos,
      prNumber: review.prNumber,
      prRepo: review.repoFullName,
      prHeadSha: head,
      isFork: await _forkStatus(
        workspaceId,
        review.repoFullName,
        review.prNumber,
      ),
    );
  }

  Future<bool> _forkStatus(
    String workspaceId,
    String repoFullName,
    int prNumber,
  ) async {
    final key = '$workspaceId\u0000$repoFullName\u0000$prNumber';
    final known = _forks[key];
    if (known != null) {
      return known;
    }
    try {
      final fork = await _isFork(workspaceId, repoFullName, prNumber);
      _forks[key] = fork;
      return fork;
    } on Object catch (e) {
      // This gates what runs on the host, so not knowing means a fork.
      CcInfraLog.warning(
        'environments: could not read $repoFullName#$prNumber, treating it '
        'as a fork: $e',
      );
      return true;
    }
  }

  @override
  Future<EnvironmentSpaceRepo> addRepoToSpace(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    // Append to the selection, not to the worktrees that exist: a selected
    // repo may not be provisioned yet, and a null selection already means
    // every repo, this one included.
    final selection = await _messaging.spaceRepoSelection(workspaceId, spaceId);
    if (selection != null && !selection.contains(repoId)) {
      await _messaging.setSpaceRepos(workspaceId, spaceId, [
        ...selection,
        repoId,
      ]);
    }
    await _provision(workspaceId, spaceId);
    final info = await space(workspaceId, spaceId);
    final added = info.repo(repoId);
    if (added == null) {
      throw const ValidationException('Could not add the repo to this space');
    }
    return added;
  }

  @override
  Future<bool> isRepoLinked(String workspaceId, String repoId) =>
      _repos.exists(workspaceId, repoId);

  @override
  Future<List<EnvironmentWorkspaceRepo>> workspaceRepos(
    String workspaceId,
  ) async {
    final repos = await _repos.getAll(workspaceId);
    return [
      for (final repo in repos)
        if (repo.path.isNotEmpty)
          EnvironmentWorkspaceRepo(
            id: repo.id,
            name: repo.name,
            sourcePath: repo.path,
            defaultBranch: await _defaultBranch(repo.path),
          ),
    ];
  }

  /// Null when there is no answer, which includes a worktree a rig tampered
  /// with: a head nobody can read is a head no approval covers.
  static Future<String?> _headOf(String path) async {
    try {
      final result = await Process.run(
        'git',
        RigWorktreeGuard.gitArgs(['-C', path, 'rev-parse', 'HEAD']),
      );
      return result.exitCode == 0 ? '${result.stdout}'.trim() : null;
    } on RigWorktreeTampered {
      return null;
    }
  }

  static Future<String> _defaultBranch(String path) async {
    final result = await Process.run(
      'git',
      RigWorktreeGuard.gitArgs([
        '-C',
        path,
        'symbolic-ref',
        '--short',
        'refs/remotes/origin/HEAD',
      ]),
    );
    if (result.exitCode == 0) {
      final ref = '${result.stdout}'.trim();
      final slash = ref.indexOf('/');
      return slash < 0 ? ref : ref.substring(slash + 1);
    }
    return 'main';
  }
}

/// [RigPortsService] as the service's router.
class RigEnvironmentRouting implements EnvironmentRoutingPort {
  /// Creates a [RigEnvironmentRouting].
  RigEnvironmentRouting(this._ports);

  final RigPortsService _ports;

  @override
  Future<int> ensureRouter() => _ports.ensureEnvironmentRouter();

  @override
  void setRoutes(
    String environmentId,
    Map<String, RigEnvironmentRoute> routes,
  ) => _ports.setEnvironmentRoutes(environmentId, routes);

  @override
  void clearRoutes(String environmentId) =>
      _ports.clearEnvironmentRoutes(environmentId);
}

/// Opens window rigs for desktop apps.
class RigEnvironmentHostWindows implements EnvironmentHostWindows {
  /// Creates a [RigEnvironmentHostWindows].
  RigEnvironmentHostWindows(this._rigs);

  final RigService _rigs;
  final Map<String, String> _workspaces = {};

  @override
  Future<String> open({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required String componentId,
    required List<int> pids,
    required EnvironmentAppInputMode inputMode,
  }) async {
    final rig = await _rigs.openHostWindowRig(
      workspaceId: workspaceId,
      pids: pids.toSet(),
      openedBy: const AgentPrincipal('environment-service'),
      conversationId: spaceId,
      slotId: componentId,
      inputMode: inputMode == EnvironmentAppInputMode.foreground
          ? HostWindowInputMode.foreground
          : HostWindowInputMode.background,
    );
    _workspaces[rig.id] = workspaceId;
    return rig.id;
  }

  @override
  Future<void> close(String rigId) async {
    final workspaceId = _workspaces.remove(rigId);
    if (workspaceId != null) {
      await _rigs.close(
        workspaceId: workspaceId,
        rigId: rigId,
        reason: RigCloseReason.requested,
      );
    }
  }
}

/// Runs a real binary for the gateway: argv, never a shell.
Future<AgentEnvironmentResult> runAgentHostCommand(
  String binary,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String> environment = const {},
}) async {
  final executable = await resolveBinaryPath(binary);
  if (executable == null) {
    return AgentEnvironmentResult(
      exitCode: 5,
      stderr: '$binary is not installed',
    );
  }
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  ).timeout(const Duration(minutes: 30));
  return AgentEnvironmentResult(
    exitCode: result.exitCode,
    stdout: '${result.stdout}',
    stderr: '${result.stderr}',
  );
}

/// Pristine clones of a definition's repos, for a throwaway test.
EnvironmentTestCloneProvider environmentTestClones({
  required RepoIsolationPort isolation,
  required RepoRepository repos,
  required Future<String> Function(String workspaceId) parentDir,
}) => (workspaceId, definition) async {
  final parent = await parentDir(workspaceId);
  final id = const Uuid().v4().substring(0, 8);
  final made = <(RepoIsolationResult, String)>[];
  final cloned = <EnvironmentSpaceRepo>[];
  Future<void> dispose() async {
    for (final (clone, source) in made) {
      await isolation.destroy(
        path: clone.path,
        sourcePath: source,
        backend: clone.backend,
      );
    }
  }

  try {
    for (final role in definition.repos) {
      final repo = await repos.getById(workspaceId, role.repoId);
      if (repo == null || repo.path.isEmpty) {
        if (role.required) {
          throw ValidationException('Repo not found for role ${role.key}');
        }
        continue;
      }
      final clone = await isolation.provision(
        sourcePath: repo.path,
        destParentDir: parent,
        name: 'environment-test-$id-${role.key}',
        branch: 'cc-environment-test-$id',
        pristine: true,
      );
      made.add((clone, repo.path));
      cloned.add(
        EnvironmentSpaceRepo(
          repoId: role.repoId,
          name: repo.name,
          slug: p.basename(clone.path),
          worktreePath: clone.path,
          sourcePath: repo.path,
          branch: 'cc-environment-test-$id',
        ),
      );
    }
  } on Object {
    await dispose();
    rethrow;
  }
  return EnvironmentTestClone(
    space: EnvironmentSpaceInfo(
      id: 'test-$id',
      workspaceId: workspaceId,
      name: 'Test',
      branch: 'test-$id',
      repos: cloned,
    ),
    dispose: dispose,
  );
};

/// A PR worktree sync, as [clientPrSync] and the environments use it.
typedef PrWorktreeSync =
    Future<Map<String, dynamic>> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
    });

/// `worktree.syncToPrHead` as a client reaches it, or null on a server with no
/// [environments] and so no worktrees to sync.
PrWorktreeSync? clientPrSync(
  EnvironmentService? environments,
  PrWorktreeSync syncPrWorktree,
) => environments == null
    ? null
    : guardedPrSync(environments.whileHeadMoves, syncPrWorktree);

/// [syncPrWorktree] behind [whileHeadMoves], which may refuse. A refusal reads
/// like any failed sync, whose error the client shows.
PrWorktreeSync guardedPrSync(
  Future<Map<String, dynamic>> Function(
    String workspaceId,
    String spaceId,
    Future<Map<String, dynamic>> Function() move,
  )
  whileHeadMoves,
  PrWorktreeSync syncPrWorktree,
) =>
    ({
      required String workspaceId,
      required String spaceId,
      required String repoId,
    }) async {
      try {
        return await whileHeadMoves(
          workspaceId,
          spaceId,
          () => syncPrWorktree(
            workspaceId: workspaceId,
            spaceId: spaceId,
            repoId: repoId,
          ),
        );
      } on EnvironmentDriverException catch (e) {
        return {'ok': false, 'error': e.error.message};
      }
    };

/// Brings a PR space's worktrees to their PR head and reports what moved.
///
/// Returns null when a worktree is dirty, which leaves it alone.
Future<List<String>?> syncEnvironmentWorktrees({
  required IsolatedRepoRepository isolated,
  required Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  })
  syncPrWorktree,
  required String workspaceId,
  required String spaceId,
}) async {
  final changed = <String>[];
  for (final row in await isolated.forSpace(workspaceId, spaceId)) {
    final before = await ServerEnvironmentDirectory._headOf(row.path);
    final result = await syncPrWorktree(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: row.repoId,
    );
    if (result['dirty'] == true || result['ok'] == false) {
      return null;
    }
    final after = await ServerEnvironmentDirectory._headOf(row.path);
    if (before == null || after == null || before == after) {
      continue;
    }
    final diff = await Process.run(
      'git',
      RigWorktreeGuard.gitArgs([
        '-C',
        row.path,
        'diff',
        '--name-only',
        before,
        after,
      ]),
    );
    if (diff.exitCode == 0) {
      changed.addAll(
        '${diff.stdout}'.split('\n').where((line) => line.isNotEmpty),
      );
    }
  }
  return changed;
}

/// Builds the environment service and everything under it.
EnvironmentService buildServerEnvironmentService({
  required String dataDir,
  required EnvironmentDefinitionRepository definitions,
  required SpaceEnvironmentRepository environments,
  required EnvironmentRunRepository runs,
  required EnvironmentLeaseRepository leases,
  required DomainEventBus events,
  required TerminalSessionService terminals,
  required RigService rigs,
  required MessagingRepository messaging,
  required RepoRepository repos,
  required IsolatedRepoRepository isolated,
  required DaoReviewSpaceRepository reviewSpaces,
  required RepoIsolationPort isolation,
  required WorkspaceFilesystemPort filesystem,
  required Future<List<String>> Function() workspaceIds,
  required Future<void> Function(String workspaceId, String spaceId) provision,
  required EnvironmentForkLookup isFork,
  required EnvironmentAdminCheck isAdmin,
  required Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  })
  syncPrWorktree,
  required EnvironmentActivityProbe spaceActivity,
}) {
  final runner = EnvironmentCommandRunner();
  return EnvironmentService(
    EnvironmentServiceDependencies(
      definitions: definitions,
      environments: environments,
      runs: runs,
      leases: leases,
      allocator: EnvironmentLeaseAllocator(repository: leases),
      directory: ServerEnvironmentDirectory(
        messaging: messaging,
        repos: repos,
        isolated: isolated,
        reviewSpaces: reviewSpaces,
        workspaceIds: workspaceIds,
        isFork: isFork,
        provision: provision,
      ),
      routing: RigEnvironmentRouting(rigs.ports),
      events: events,
      compose: ComposeDriver(runner: runner),
      cli: CliDriver(runner: runner),
      supervisor: EnvironmentProcessSupervisor(terminals: terminals),
      tasks: EnvironmentTaskRunner(runs: runs),
      runner: runner,
      stateDirFor: (workspaceId, environmentId) =>
          p.join(dataDir, workspaceId, 'environments', environmentId),
      isAdmin: isAdmin,
      home: Platform.environment['HOME'] ?? '',
      windows: RigEnvironmentHostWindows(rigs),
      rigHost: RigEnvironmentHost(
        rigs,
        worktreeOf: (workspaceId, spaceId) async {
          final rows = await isolated.forSpace(workspaceId, spaceId);
          return rows.isEmpty ? null : rows.first.path;
        },
        // The only directories a rig may mount; anything else is refused.
        spaceWorktrees: (workspaceId, spaceId) async => [
          for (final row in await isolated.forSpace(workspaceId, spaceId))
            row.path,
        ],
      ),
      syncWorktree:
          ({
            required String workspaceId,
            required String spaceId,
            required String headSha,
          }) => syncEnvironmentWorktrees(
            isolated: isolated,
            syncPrWorktree: syncPrWorktree,
            workspaceId: workspaceId,
            spaceId: spaceId,
          ),
      lastActivity: spaceActivity,
      testClone: environmentTestClones(
        isolation: isolation,
        repos: repos,
        parentDir: (workspaceId) async {
          final directory = p.join(
            dataDir,
            workspaceId,
            'tmp',
            'environment_tests',
          );
          await filesystem.ensureDir(directory);
          return directory;
        },
      ),
    ),
  );
}

/// Builds the environment service and connects it to everything that was
/// created before it: the provisioner, dispatch, the gateway, the sandbox
/// proxy, terminals and MCP. Returns the service for the RPC catalog.
EnvironmentService wireServerEnvironments({
  required String dataDir,
  required WorkspaceDatabaseManager workspaceDbs,
  required GlobalDatabase globalDb,
  required DomainEventBus events,
  required TerminalSessionService terminals,
  required RigService rigs,
  required MessagingRepository messaging,
  required RepoRepository repos,
  required IsolatedRepoRepository isolated,
  required DaoReviewSpaceRepository reviewSpaces,
  required RepoIsolationPort isolation,
  required WorkspaceFilesystemPort filesystem,
  required WorkspaceRepository workspaces,
  required SpaceProvisioningService provisioning,
  required GitHubApiClient Function(String workspaceId, String owner)
  githubClientForOwner,
  required CachingWorkspaceMembershipRepository members,
  required Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  })
  syncPrWorktree,
  required LateWorktreeTasks worktreeTasks,
  required LateEnvironmentPort environments,
  required SandboxManager sandboxManager,
  required AgentRunGateway gateway,
  required ActionGuardService actionGuard,
  required McpToolRegistry mcpRegistry,
}) {
  final service = buildServerEnvironmentService(
    dataDir: dataDir,
    definitions: DaoEnvironmentDefinitionRepository(workspaceDbs),
    environments: DaoSpaceEnvironmentRepository(workspaceDbs),
    runs: DaoEnvironmentRunRepository(workspaceDbs),
    leases: DaoEnvironmentLeaseRepository(globalDb.environmentLeaseDao),
    events: events,
    terminals: terminals,
    rigs: rigs,
    messaging: messaging,
    repos: repos,
    isolated: isolated,
    reviewSpaces: reviewSpaces,
    isolation: isolation,
    filesystem: filesystem,
    workspaceIds: () async =>
        (await workspaces.watchAll().first).map((w) => w.id).toList(),
    provision: (workspaceId, spaceId) =>
        provisioning.provision(workspaceId: workspaceId, spaceId: spaceId),
    isFork: (workspaceId, repoFullName, prNumber) async {
      final parts = repoFullName.split('/');
      if (parts.length != 2) {
        return true;
      }
      final pr = await githubClientForOwner(
        workspaceId,
        parts.first,
      ).pr.getPullRequest(parts.first, parts.last, prNumber);
      return pr?.isFork ?? true;
    },
    isAdmin: (workspaceId, by) async {
      if (!by.isUser) {
        return false;
      }
      final member = await members.getMember(workspaceId, by.id);
      return member?.role.isAdmin ?? false;
    },
    syncPrWorktree: syncPrWorktree,
    spaceActivity: (workspaceId, spaceId) async {
      final rows = await workspaceDbs
          .of(workspaceId)
          .messagingDao
          .watchSpaceActivity(workspaceId)
          .first;
      DateTime? latest;
      for (final row in rows) {
        final at = row.lastMessageAt;
        if (row.spaceId == spaceId &&
            at != null &&
            (latest == null || at.isAfter(latest))) {
          latest = at;
        }
      }
      return latest;
    },
  );
  worktreeTasks.target = service;
  environments.target = service;
  terminals.hostEnvironment = service.terminalEnvironment;
  sandboxManager.environmentHostResolver = (scope, host) async {
    final separator = scope.indexOf('/');
    if (separator <= 0) {
      return null;
    }
    final hosts = await service.sandboxHosts(
      scope.substring(0, separator),
      scope.substring(separator + 1),
    );
    return hosts[host];
  };
  gateway.environments = AgentEnvironmentGateway(
    environments: service,
    context: service,
    guard: actionGuard,
    runHost: runAgentHostCommand,
  );
  mcpRegistry
    ..register(EnvironmentStatusTool(environments: service))
    ..register(EnvironmentUpTool(environments: service))
    ..register(EnvironmentDownTool(environments: service))
    ..register(EnvironmentResetTool(environments: service))
    ..register(EnvironmentDestroyTool(environments: service))
    ..register(EnvironmentRestartTool(environments: service))
    ..register(EnvironmentExecTool(environments: service))
    ..register(EnvironmentLogsTool(environments: service))
    ..register(EnvironmentRunTaskTool(environments: service))
    ..register(EnvironmentLaunchAppTool(environments: service))
    ..register(EnvironmentStopAppTool(environments: service));
  // start() subscribes first and then recovers, so a failed recovery never
  // leaves the service deaf to space deletions.
  unawaited(service.start());
  return service;
}
