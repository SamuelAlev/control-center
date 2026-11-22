import 'package:cc_domain/cc_domain.dart' show GoalAlreadyActiveException;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/agent_goal_run_dao.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_goal_run_mapper.dart';

/// Drift-backed [AgentGoalRunRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentGoalRunDao` per call: supervised goals live in
/// their workspace's own database file, so the workspace id picks the file
/// before any SQL runs. [listActive] is the one read that spans files.
class DaoAgentGoalRunRepository implements AgentGoalRunRepository {
  /// Creates a [DaoAgentGoalRunRepository] over the per-workspace databases.
  DaoAgentGoalRunRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final AgentGoalRunMapper _mapper = const AgentGoalRunMapper();

  AgentGoalRunDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).agentGoalRunDao;

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async =>
      _mapper.toDomainList(
        await _dao(workspaceId).listByWorkspace(workspaceId),
      );

  @override
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  /// CROSS-WORKSPACE BY DESIGN: the supervisor's startup reconciler must resume
  /// every active goal regardless of workspace, so this read opens every
  /// workspace file. Each resulting re-dispatch is itself workspace-scoped. The
  /// scoped read path is [listByWorkspace].
  @override
  Future<List<AgentGoalRun>> listActive() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.agentGoalRunDao.listActive(),
      backgroundWriter: 'goal supervisor',
    );
    return _mapper.toDomainList([for (final rows in perWorkspace) ...rows]);
  }

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final row = await _dao(workspaceId).getActiveForAgent(workspaceId, agentId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<List<AgentGoalRun>> listHeld(
    String workspaceId, {
    GoalHold? hold,
  }) async => _mapper.toDomainList(
    await _dao(workspaceId).listHeld(workspaceId, hold: hold?.wire),
  );

  @override
  Future<List<AgentGoalRun>> listForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).listForPipelineRun(workspaceId, pipelineRunId),
  );

  @override
  Future<AgentGoalRun?> getByActiveRunId(
    String workspaceId,
    String runId,
  ) async {
    final row = await _dao(workspaceId).getByActiveRunId(workspaceId, runId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<bool> replaceIf(
    AgentGoalRun next, {
    required AgentGoalRun expected,
  }) async {
    if (next.id != expected.id || next.workspaceId != expected.workspaceId) {
      throw ArgumentError.value(
        next.id,
        'next',
        'must be the same goal as expected (${expected.id})',
      );
    }
    final db = _dbs.of(next.workspaceId);
    try {
      return await db.transaction(() async {
        final dao = db.agentGoalRunDao;
        final row = await dao.getById(next.workspaceId, next.id);
        // Compared as the domain reads it: a write lands only on the exact
        // goal the caller changed, never over a newer one.
        if (row == null || _mapper.toDomain(row) != expected) {
          return false;
        }
        return dao.replace(
          next.workspaceId,
          next.id,
          _mapper.toCompanion(next),
        );
      });
    } on Object catch (error) {
      if (next.status == AgentGoalStatus.active &&
          _violatesOneActiveGoal(error)) {
        throw GoalAlreadyActiveException(
          workspaceId: next.workspaceId,
          agentId: next.agentId,
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> recordSegmentEnd(
    String workspaceId,
    String goalId, {
    required String runId,
    required int costMicros,
    required DateTime at,
  }) => _dao(workspaceId).recordSegmentEnd(
    workspaceId,
    goalId,
    runId: runId,
    costMicros: costMicros,
    at: at,
  );

  @override
  Future<void> upsert(AgentGoalRun goal) async {
    // The goal carries its own workspace, so the file is picked from the
    // entity rather than from a parameter that could disagree with it.
    try {
      await _dao(goal.workspaceId).upsert(_mapper.toCompanion(goal));
    } on Object catch (error) {
      if (goal.status == AgentGoalStatus.active &&
          _violatesOneActiveGoal(error)) {
        throw GoalAlreadyActiveException(
          workspaceId: goal.workspaceId,
          agentId: goal.agentId,
        );
      }
      rethrow;
    }
  }

  /// Whether [error] is the one-active-goal-per-agent index refusing a row.
  static bool _violatesOneActiveGoal(Object error) {
    final cause = sqliteCauseOf(error);
    return cause != null &&
        cause.message.contains('UNIQUE constraint failed') &&
        cause.message.contains('agent_goal_runs.agent_id');
  }
}
