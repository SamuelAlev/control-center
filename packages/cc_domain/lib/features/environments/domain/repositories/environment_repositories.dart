import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';

/// Stored definitions. Every call is scoped to a workspace.
abstract interface class EnvironmentDefinitionRepository {
  /// Every definition in [workspaceId].
  Future<List<EnvironmentDefinitionRecord>> list(String workspaceId);

  /// One definition, or null.
  Future<EnvironmentDefinitionRecord?> get(String workspaceId, String id);

  /// Inserts or replaces [record].
  Future<void> save(EnvironmentDefinitionRecord record);

  /// Deletes one definition.
  Future<void> delete(String workspaceId, String id);
}

/// Stored environments. Every call is scoped to a workspace.
abstract interface class SpaceEnvironmentRepository {
  /// Every environment in [workspaceId].
  Future<List<SpaceEnvironment>> list(String workspaceId);

  /// The environments of one space.
  Future<List<SpaceEnvironment>> forSpace(String workspaceId, String spaceId);

  /// One environment, or null.
  Future<SpaceEnvironment?> get(String workspaceId, String id);

  /// Inserts or replaces [environment].
  Future<void> save(SpaceEnvironment environment);

  /// Deletes one environment.
  Future<void> delete(String workspaceId, String id);
}

/// Stored run records. Every call is scoped to a workspace.
abstract interface class EnvironmentRunRepository {
  /// Inserts [run].
  Future<void> start(EnvironmentRun run);

  /// Replaces a run's output tail.
  Future<void> updateOutput(String workspaceId, String id, String output);

  /// Finishes a run.
  Future<void> finish(
    String workspaceId,
    String id, {
    required EnvironmentRunStatus status,
    required DateTime completedAt,
    int? exitCode,
    String? error,
    String? output,
  });

  /// Recent runs of a space, newest first.
  Future<List<EnvironmentRun>> forSpace(
    String workspaceId,
    String spaceId, {
    int limit = 50,
  });

  /// Recent runs of a definition, newest first.
  Future<List<EnvironmentRun>> forDefinition(
    String workspaceId,
    String definitionId, {
    int limit = 50,
  });

  /// One run, or null.
  Future<EnvironmentRun?> get(String workspaceId, String id);

  /// Runs left `running` by a server that went away.
  Future<void> failInterrupted(String workspaceId, DateTime now);
}

/// Port leases, host-wide.
abstract interface class EnvironmentLeaseRepository {
  /// Every lease.
  Future<List<EnvironmentLease>> all();

  /// The lease a space holds for a definition, or null.
  Future<EnvironmentLease?> forSpace(
    String workspaceId,
    String spaceId,
    String definitionId,
  );

  /// Inserts [lease]; false when its block or pool slot is already taken.
  Future<bool> tryInsert(EnvironmentLease lease);

  /// Releases a space's lease for a definition.
  Future<void> release(String workspaceId, String spaceId, String definitionId);

  /// Releases every lease of a space.
  Future<void> releaseSpace(String workspaceId, String spaceId);
}
