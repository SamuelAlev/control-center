import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';

/// One host-readiness result.
class EnvironmentCheckResult {
  /// Creates an [EnvironmentCheckResult].
  const EnvironmentCheckResult({
    required this.id,
    required this.label,
    required this.ok,
    this.hint,
    this.fix,
  });

  /// Stable id.
  final String id;

  /// What to show.
  final String label;

  /// Whether it passed.
  final bool ok;

  /// What to do.
  final String? hint;

  /// A copyable fix.
  final String? fix;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'ok': ok,
    if (hint != null) 'hint': hint,
    if (fix != null) 'fix': fix,
  };
}

/// Output of a one-shot command.
class EnvironmentExecResult {
  /// Creates an [EnvironmentExecResult].
  const EnvironmentExecResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Exit code.
  final int exitCode;

  /// Standard output.
  final String stdout;

  /// Standard error.
  final String stderr;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'exit_code': exitCode,
    'stdout': stdout,
    'stderr': stderr,
  };
}

/// An environment and the space it runs in. The name is null for a space that
/// can no longer be read, which is exactly when destroying it matters most.
typedef EnvironmentInstance = ({
  SpaceEnvironment environment,
  String? spaceName,
});

/// The environment feature as the RPC layer, tools, the gateway and pipelines
/// see it. Authorization happens at those entry points; the service owns
/// workspace scoping and derives the environment from the space.
abstract interface class EnvironmentPort {
  /// Every definition in a workspace.
  Future<List<EnvironmentDefinitionRecord>> listDefinitions(String workspaceId);

  /// One definition, or null.
  Future<EnvironmentDefinitionRecord?> definition(
    String workspaceId,
    String definitionId,
  );

  /// The definitions a space can start.
  Future<List<EnvironmentDefinitionRecord>> eligibleDefinitions(
    String workspaceId,
    String spaceId,
  );

  /// Validates and stores a definition. Throws `ValidationException`.
  Future<EnvironmentDefinitionRecord> saveDefinition({
    required String workspaceId,
    String? definitionId,
    required Map<String, dynamic> definition,
    required Principal by,
  });

  /// Links a definition to a file on a repo's default branch, approving the
  /// blob it currently has.
  Future<EnvironmentDefinitionRecord> approveSource({
    required String workspaceId,
    String? definitionId,
    required String repoId,
    required String path,
    Map<String, dynamic>? overrides,
    String? expectedBlobHash,
    required Principal by,
  });

  /// What a linked definition's file holds now, for the review diff.
  Future<Map<String, dynamic>?> sourceUpdate(
    String workspaceId,
    String definitionId,
  );

  /// Deletes a definition.
  Future<void> deleteDefinition(String workspaceId, String definitionId);

  /// Scans a repo's checkout and proposes a definition. Nothing is stored.
  Future<Map<String, dynamic>> draftDefinition(
    String workspaceId,
    String repoId,
  );

  /// Runs a definition's host checks.
  Future<List<EnvironmentCheckResult>> check(
    String workspaceId,
    String definitionId,
  );

  /// Runs a throwaway environment end to end. Returns a run id at once.
  Future<String> testDefinition(String workspaceId, String definitionId);

  /// Everything [definitionId] still holds, in every space, for someone
  /// deciding what to free up. Gone rows are left out.
  Future<List<EnvironmentInstance>> definitionEnvironments(
    String workspaceId,
    String definitionId,
  );

  /// The environments of a space.
  Future<List<SpaceEnvironment>> environmentsFor(
    String workspaceId,
    String spaceId,
  );

  /// Updates to one space's environments.
  Stream<List<SpaceEnvironment>> watch(String workspaceId, String spaceId);

  /// Starts, or reuses, the space's environment.
  Future<SpaceEnvironment> ensure({
    required String workspaceId,
    required String spaceId,
    String? definitionId,
    Map<String, dynamic> options = const {},
    required Principal by,
  });

  /// Runs the `setup` verb of a start that stopped for a person, on a terminal
  /// they can answer, and returns its session id. The start carries on by
  /// itself when the verb succeeds. Calling again while it runs returns the
  /// same session.
  ///
  /// For a person only: this is what a password gets typed into.
  Future<String> startSetup(
    String workspaceId,
    String spaceId, {
    required Principal by,
  });

  /// Stops it, keeping what its tools keep.
  Future<SpaceEnvironment> stop(
    String workspaceId,
    String spaceId, {
    required Principal by,
  });

  /// Returns data to its baseline.
  Future<SpaceEnvironment> reset(
    String workspaceId,
    String spaceId, {
    required Principal by,
  });

  /// Re-applies the worktree's current state.
  Future<SpaceEnvironment> refresh(
    String workspaceId,
    String spaceId, {
    required Principal by,
  });

  /// Destroys it.
  Future<void> destroy(
    String workspaceId,
    String spaceId, {
    required Principal by,
  });

  /// Restarts one component or service.
  Future<void> restart(
    String workspaceId,
    String spaceId,
    String target, {
    required Principal by,
  });

  /// Stops one process.
  Future<void> stopProcess(
    String workspaceId,
    String spaceId,
    String componentId, {
    required Principal by,
  });

  /// Runs a command in a service.
  Future<EnvironmentExecResult> exec(
    String workspaceId,
    String spaceId, {
    required String service,
    required List<String> command,
    required Principal by,
  });

  /// The last lines of a process or service.
  Future<String> logs(
    String workspaceId,
    String spaceId, {
    required String target,
    int tail = 200,
  });

  /// Streams a process or service.
  Stream<String> followLogs(
    String workspaceId,
    String spaceId, {
    required String target,
    int tail = 200,
  });

  /// Runs a task by id. Returns the finished run.
  Future<EnvironmentRun> runTask(
    String workspaceId,
    String spaceId,
    String taskId, {
    List<String> arguments = const [],
    required Principal by,
  });

  /// Recent runs of a space.
  Future<List<EnvironmentRun>> runs(String workspaceId, String spaceId);

  /// Recent runs of a definition.
  Future<List<EnvironmentRun>> definitionRuns(
    String workspaceId,
    String definitionId,
  );

  /// Builds and opens a desktop app.
  Future<void> launchApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    bool rebuild = false,
    required Principal by,
  });

  /// Closes a desktop app.
  Future<void> stopApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    required Principal by,
  });

  /// The contract environment for a space's terminals, or empty.
  Future<Map<String, String>> terminalEnvironment(
    String workspaceId,
    String spaceId,
  );

  /// The ports a run in this space may reach, leasing them if needed.
  Future<List<int>> sandboxLoopbackPorts(String workspaceId, String spaceId);

  /// The command names a run in this space gets a shim for. Empty when the
  /// space can't run an environment.
  Future<Set<String>> agentShimTools(String workspaceId, String spaceId);

  /// The hostnames a run in this space may reach through its proxy.
  Future<Map<String, String>> sandboxHosts(String workspaceId, String spaceId);
}
