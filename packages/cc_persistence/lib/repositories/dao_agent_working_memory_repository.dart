import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_persistence/database/daos/agent_working_memory_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/agent_working_memory_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for agent working memory.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).agentWorkingMemoryDao` per call: working memory lives
/// in its workspace's own database file, so the workspace id picks the file
/// before any SQL runs.
class DaoAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  /// Creates a [DaoAgentWorkingMemoryRepository] over the per-workspace
  /// databases.
  DaoAgentWorkingMemoryRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final AgentWorkingMemoryMapper _mapper = const AgentWorkingMemoryMapper();

  AgentWorkingMemoryDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).agentWorkingMemoryDao;

  @override
  Stream<AgentWorkingMemory?> watchByAgent(
    String workspaceId,
    String agentId,
  ) => _dao(workspaceId)
      .watchByAgent(workspaceId, agentId)
      .map((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId) =>
      _dao(workspaceId)
          .getByAgent(workspaceId, agentId)
          .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<void> upsert(AgentWorkingMemory memory) =>
      // The entry carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(memory.workspaceId).upsert(
        db.AgentWorkingMemoryTableCompanion(
          id: Value(memory.id),
          workspaceId: Value(memory.workspaceId),
          agentId: Value(memory.agentId),
          content: Value(memory.content),
          updatedAt: Value(memory.updatedAt),
        ),
      );
}
