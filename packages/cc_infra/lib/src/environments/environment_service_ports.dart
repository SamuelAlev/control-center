import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/cli_driver.dart';
import 'package:cc_infra/src/environments/compose_driver.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';
import 'package:cc_infra/src/environments/environment_task_runner.dart';
import 'package:cc_infra/src/environments/worktree_seed_files.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show RigEnvironmentRoute;

/// One repo a space holds.
class EnvironmentSpaceRepo {
  /// Creates an [EnvironmentSpaceRepo].
  const EnvironmentSpaceRepo({
    required this.repoId,
    required this.name,
    required this.slug,
    required this.worktreePath,
    required this.sourcePath,
    this.branch,
  });

  /// The workspace repo.
  final String repoId;

  /// Display name.
  final String name;

  /// Directory slug.
  final String slug;

  /// The space's worktree.
  final String worktreePath;

  /// The registered source checkout.
  final String sourcePath;

  /// The checked-out branch.
  final String? branch;
}

/// A space, as far as environments care.
class EnvironmentSpaceInfo {
  /// Creates an [EnvironmentSpaceInfo].
  const EnvironmentSpaceInfo({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.branch,
    this.kind = 'space',
    this.repos = const [],
    this.prNumber,
    this.prRepo,
    this.prHeadSha,
    this.isFork = false,
  });

  /// Space id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Display name.
  final String name;

  /// The branch environments are named after.
  final String branch;

  /// `space` or `pr`.
  final String kind;

  /// Its repos.
  final List<EnvironmentSpaceRepo> repos;

  /// PR number, in a PR space.
  final int? prNumber;

  /// `owner/name`, in a PR space.
  final String? prRepo;

  /// Head commit, in a PR space.
  final String? prHeadSha;

  /// Whether this holds a fork PR's code.
  final bool isFork;

  /// The repo [repoId], or null.
  EnvironmentSpaceRepo? repo(String repoId) {
    for (final repo in repos) {
      if (repo.repoId == repoId) {
        return repo;
      }
    }
    return null;
  }
}

/// A repo linked to a workspace.
class EnvironmentWorkspaceRepo {
  /// Creates an [EnvironmentWorkspaceRepo].
  const EnvironmentWorkspaceRepo({
    required this.id,
    required this.name,
    required this.sourcePath,
    required this.defaultBranch,
  });

  /// Repo id.
  final String id;

  /// Display name.
  final String name;

  /// The registered checkout.
  final String sourcePath;

  /// Its default branch.
  final String defaultBranch;
}

/// What the service needs to know about spaces and repos.
abstract interface class EnvironmentSpaceDirectory {
  /// Every registered workspace.
  Future<List<String>> workspaceIds();

  /// The space [spaceId].
  ///
  /// Throws `WorkspaceMismatchException` for a space of another workspace,
  /// which is where every entry point gets its isolation from, and
  /// `NotFoundException` for one that does not exist.
  Future<EnvironmentSpaceInfo> space(String workspaceId, String spaceId);

  /// Adds [repoId] to the space, with a worktree at the default branch.
  Future<EnvironmentSpaceRepo> addRepoToSpace(
    String workspaceId,
    String spaceId,
    String repoId,
  );

  /// Whether [repoId] is linked to [workspaceId].
  Future<bool> isRepoLinked(String workspaceId, String repoId);

  /// The repos linked to [workspaceId].
  Future<List<EnvironmentWorkspaceRepo>> workspaceRepos(String workspaceId);
}

/// CC's shared router. `RigPortsService` has all three as
/// `ensureEnvironmentRouter`, `setEnvironmentRoutes`, `clearEnvironmentRoutes`.
///
/// Not `EnvironmentRouting`: that name is the definition's value object.
abstract interface class EnvironmentRoutingPort {
  /// Starts the router if it isn't up, and returns its port.
  Future<int> ensureRouter();

  /// Replaces what [environmentId] routes. Throws `ArgumentError` when a
  /// hostname belongs to another environment.
  void setRoutes(String environmentId, Map<String, RigEnvironmentRoute> routes);

  /// Removes what [environmentId] routes.
  void clearRoutes(String environmentId);
}

/// Opens a viewer on a desktop app's windows.
abstract interface class EnvironmentHostWindows {
  /// Opens one for [pids], returning its rig id.
  Future<String> open({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required String componentId,
    required List<int> pids,
    required EnvironmentAppInputMode inputMode,
  });

  /// Closes a viewer.
  Future<void> close(String rigId);
}

/// A running environment rig.
class EnvironmentRigInstance {
  /// Creates an [EnvironmentRigInstance].
  const EnvironmentRigInstance({
    required this.rigId,
    this.endpoints = const [],
  });

  /// The rig.
  final String rigId;

  /// What it publishes.
  final List<EnvironmentEndpoint> endpoints;
}

/// Runs `compose` and `task` components inside a microVM.
abstract interface class EnvironmentRigHost {
  /// Boots the rig, or reuses a stopped one, and brings its compose stack up.
  Future<EnvironmentRigInstance> start({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required EnvironmentDefinition definition,
    required Map<String, String> worktrees,
    required Map<String, String> environment,
  });

  /// Stops the rig, keeping its disk.
  Future<void> stop({required String workspaceId, required String rigId});

  /// Destroys it.
  Future<void> destroy({required String workspaceId, required String rigId});

  /// Whether [rigId] still exists and runs. A rig outlived by its row was
  /// reclaimed by its TTL or lost with the host.
  Future<bool> isRunning({required String workspaceId, required String rigId});

  /// Runs [argv] in the guest. With a null [rigId], in the space's rig,
  /// booting one when there is none.
  Future<EnvironmentExecResult> exec({
    required String workspaceId,
    required String spaceId,
    required List<String> argv,
    String? rigId,
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  });
}

/// A throwaway checkout for [EnvironmentTestCloneProvider].
class EnvironmentTestClone {
  /// Creates an [EnvironmentTestClone].
  const EnvironmentTestClone({required this.space, required this.dispose});

  /// A space that exists only for this test, holding every role's repo.
  final EnvironmentSpaceInfo space;

  /// Removes the clones.
  final Future<void> Function() dispose;
}

/// Makes pristine clones of a definition's repos.
typedef EnvironmentTestCloneProvider =
    Future<EnvironmentTestClone> Function(
      String workspaceId,
      EnvironmentDefinition definition,
    );

/// Brings a PR worktree to [headSha]. Returns the changed paths, or null when
/// the worktree isn't clean and was left alone.
typedef EnvironmentWorktreeSync =
    Future<List<String>?> Function({
      required String workspaceId,
      required String spaceId,
      required String headSha,
    });

/// When a space last saw a message, run, terminal input or focused tab.
typedef EnvironmentActivityProbe =
    Future<DateTime?> Function(String workspaceId, String spaceId);

/// Whether [by] is an admin of [workspaceId].
typedef EnvironmentAdminCheck =
    Future<bool> Function(String workspaceId, Principal by);

/// Everything `EnvironmentService` is built from.
class EnvironmentServiceDependencies {
  /// Creates an [EnvironmentServiceDependencies].
  const EnvironmentServiceDependencies({
    required this.definitions,
    required this.environments,
    required this.runs,
    required this.leases,
    required this.allocator,
    required this.directory,
    required this.routing,
    required this.events,
    required this.compose,
    required this.cli,
    required this.supervisor,
    required this.tasks,
    required this.runner,
    required this.stateDirFor,
    required this.isAdmin,
    required this.home,
    this.seeds = const WorktreeSeedFiles(),
    this.windows,
    this.rigHost,
    this.syncWorktree,
    this.lastActivity,
    this.testClone,
    this.now = DateTime.now,
    this.maintenanceInterval = const Duration(seconds: 10),
    this.watchedPollInterval = const Duration(seconds: 10),
    this.idlePollInterval = const Duration(minutes: 5),
  });

  /// Stored definitions.
  final EnvironmentDefinitionRepository definitions;

  /// Stored environments.
  final SpaceEnvironmentRepository environments;

  /// Run records.
  final EnvironmentRunRepository runs;

  /// Host-wide leases.
  final EnvironmentLeaseRepository leases;

  /// The one allocator of this host, over [leases].
  final EnvironmentLeaseAllocator allocator;

  /// Spaces and repos.
  final EnvironmentSpaceDirectory directory;

  /// The router.
  final EnvironmentRoutingPort routing;

  /// Where status events go, and lifecycle events come from.
  final DomainEventBus events;

  /// The compose driver.
  final ComposeDriver compose;

  /// The CLI driver.
  final CliDriver cli;

  /// The process supervisor.
  final EnvironmentProcessSupervisor supervisor;

  /// The task runner.
  final EnvironmentTaskRunner tasks;

  /// Runs checks and git reads.
  final EnvironmentCommandRunner runner;

  /// `<dataDir>/<ws>/environments/<id>`.
  final String Function(String workspaceId, String environmentId) stateDirFor;

  /// Decides `approval` fork starts.
  final EnvironmentAdminCheck isAdmin;

  /// The server user's home.
  final String home;

  /// Copies seed files.
  final WorktreeSeedFiles seeds;

  /// Host windows, or null where there are none.
  final EnvironmentHostWindows? windows;

  /// The rig host. Null makes rig placement a clear error.
  final EnvironmentRigHost? rigHost;

  /// Syncs a PR worktree. Null leaves environments on their commit.
  final EnvironmentWorktreeSync? syncWorktree;

  /// Reads a space's activity. Null counts only environment use.
  final EnvironmentActivityProbe? lastActivity;

  /// Makes clones for `testDefinition`. Null makes it record a refusal.
  final EnvironmentTestCloneProvider? testClone;

  /// The clock.
  final DateTime Function() now;

  /// How often polling, idle stop and repo checks look for work.
  final Duration maintenanceInterval;

  /// Status polling while a client watches the space.
  final Duration watchedPollInterval;

  /// Status polling otherwise.
  final Duration idlePollInterval;
}
