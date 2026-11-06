import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_persistence/database/daos/environment_lease_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/environment_mapper.dart';

const _mapper = EnvironmentMapper();

/// Drift-backed [EnvironmentDefinitionRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call: a cached
/// per-workspace DAO would answer every workspace from the first one.
class DaoEnvironmentDefinitionRepository
    implements EnvironmentDefinitionRepository {
  /// Creates a [DaoEnvironmentDefinitionRepository].
  DaoEnvironmentDefinitionRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<List<EnvironmentDefinitionRecord>> list(String workspaceId) async {
    final rows = await _dbs.of(workspaceId).environmentDao.definitions();
    return [
      for (final row in rows) _mapper.definitionFromRow(row, workspaceId),
    ];
  }

  @override
  Future<EnvironmentDefinitionRecord?> get(
    String workspaceId,
    String id,
  ) async {
    final row = await _dbs.of(workspaceId).environmentDao.definition(id);
    return row == null ? null : _mapper.definitionFromRow(row, workspaceId);
  }

  @override
  Future<void> save(EnvironmentDefinitionRecord record) => _dbs
      .of(record.workspaceId)
      .environmentDao
      .upsertDefinition(_mapper.definitionToCompanion(record));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dbs.of(workspaceId).environmentDao.deleteDefinition(id);
}

/// Drift-backed [SpaceEnvironmentRepository]. Resolves the DAO per call.
class DaoSpaceEnvironmentRepository implements SpaceEnvironmentRepository {
  /// Creates a [DaoSpaceEnvironmentRepository].
  DaoSpaceEnvironmentRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<List<SpaceEnvironment>> list(String workspaceId) async {
    final rows = await _dbs.of(workspaceId).environmentDao.environments();
    return [
      for (final row in rows) _mapper.environmentFromRow(row, workspaceId),
    ];
  }

  @override
  Future<List<SpaceEnvironment>> forSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _dbs
        .of(workspaceId)
        .environmentDao
        .environmentsOfSpace(spaceId);
    return [
      for (final row in rows) _mapper.environmentFromRow(row, workspaceId),
    ];
  }

  @override
  Future<SpaceEnvironment?> get(String workspaceId, String id) async {
    final row = await _dbs.of(workspaceId).environmentDao.environment(id);
    return row == null ? null : _mapper.environmentFromRow(row, workspaceId);
  }

  @override
  Future<void> save(SpaceEnvironment environment) => _dbs
      .of(environment.workspaceId)
      .environmentDao
      .upsertEnvironment(_mapper.environmentToCompanion(environment));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dbs.of(workspaceId).environmentDao.deleteEnvironment(id);
}

/// Drift-backed [EnvironmentRunRepository]. Resolves the DAO per call.
class DaoEnvironmentRunRepository implements EnvironmentRunRepository {
  /// Creates a [DaoEnvironmentRunRepository].
  DaoEnvironmentRunRepository(this._dbs);

  /// The error recorded on a run its server never finished.
  static const interruptedError = 'Interrupted by a server restart';

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<void> start(EnvironmentRun run) => _dbs
      .of(run.workspaceId)
      .environmentDao
      .insertRun(_mapper.runToCompanion(run));

  @override
  Future<void> updateOutput(String workspaceId, String id, String output) =>
      _dbs.of(workspaceId).environmentDao.updateRunOutput(id, output);

  @override
  Future<void> finish(
    String workspaceId,
    String id, {
    required EnvironmentRunStatus status,
    required DateTime completedAt,
    int? exitCode,
    String? error,
    String? output,
  }) => _dbs
      .of(workspaceId)
      .environmentDao
      .finishRun(
        id,
        status: status.name,
        completedAt: completedAt,
        exitCode: exitCode,
        error: error,
        output: output,
      );

  @override
  Future<List<EnvironmentRun>> forSpace(
    String workspaceId,
    String spaceId, {
    int limit = 50,
  }) async {
    final rows = await _dbs
        .of(workspaceId)
        .environmentDao
        .runsOfSpace(spaceId, limit: limit);
    return rows.map(_mapper.runFromRow).toList();
  }

  @override
  Future<List<EnvironmentRun>> forDefinition(
    String workspaceId,
    String definitionId, {
    int limit = 50,
  }) async {
    final rows = await _dbs
        .of(workspaceId)
        .environmentDao
        .runsOfDefinition(definitionId, limit: limit);
    return rows.map(_mapper.runFromRow).toList();
  }

  @override
  Future<EnvironmentRun?> get(String workspaceId, String id) async {
    final row = await _dbs.of(workspaceId).environmentDao.run(id);
    return row == null ? null : _mapper.runFromRow(row);
  }

  @override
  Future<void> failInterrupted(String workspaceId, DateTime now) => _dbs
      .of(workspaceId)
      .environmentDao
      .failRunning(now, error: interruptedError);
}

/// Drift-backed [EnvironmentLeaseRepository] over the global database.
///
/// Holding this DAO is safe: `global.db` is one file for the whole install.
class DaoEnvironmentLeaseRepository implements EnvironmentLeaseRepository {
  /// Creates a [DaoEnvironmentLeaseRepository] over the global DAO.
  DaoEnvironmentLeaseRepository(this._dao);

  final EnvironmentLeaseDao _dao;

  @override
  Future<List<EnvironmentLease>> all() async {
    final rows = await _dao.all();
    return rows.map(_mapper.leaseFromRow).toList();
  }

  @override
  Future<EnvironmentLease?> forSpace(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) async {
    final row = await _dao.forSpace(workspaceId, spaceId, definitionId);
    return row == null ? null : _mapper.leaseFromRow(row);
  }

  @override
  Future<bool> tryInsert(EnvironmentLease lease) =>
      _dao.tryInsert(_mapper.leaseToCompanion(lease));

  @override
  Future<void> release(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) => _dao.release(workspaceId, spaceId, definitionId);

  @override
  Future<void> releaseSpace(String workspaceId, String spaceId) =>
      _dao.releaseSpace(workspaceId, spaceId);
}
