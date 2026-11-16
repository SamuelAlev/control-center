import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/mcp_server_mapper.dart';

const _mapper = McpServerMapper();

/// Drift-backed [WorkspaceMcpServerRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call: a cached
/// per-workspace DAO would answer every workspace from the first one. The
/// manager refuses an invalid or deleted workspace id before opening a file.
class DaoWorkspaceMcpServerRepository
    implements WorkspaceMcpServerRepository {
  /// Creates a [DaoWorkspaceMcpServerRepository].
  DaoWorkspaceMcpServerRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<List<McpServerDefinition>> list(String workspaceId) async {
    final rows = await _dbs.of(workspaceId).mcpServerDao.all();
    return [for (final row in rows) _mapper.fromRow(row, workspaceId)];
  }

  @override
  Future<McpServerDefinition?> get(String workspaceId, String id) async {
    final row = await _dbs.of(workspaceId).mcpServerDao.byId(id);
    return row == null ? null : _mapper.fromRow(row, workspaceId);
  }

  @override
  Future<void> save(McpServerDefinition definition) async {
    final workspaceId = definition.workspaceId;
    if (workspaceId == null) {
      throw ArgumentError.value(
        definition,
        'definition',
        'a workspace MCP server needs its workspace',
      );
    }
    final saved = await _dbs
        .of(workspaceId)
        .mcpServerDao
        .upsert(_mapper.toCompanion(definition));
    if (!saved) {
      throw const McpServerDefinitionException.nameTaken();
    }
  }

  @override
  Future<bool> delete(String workspaceId, String id) =>
      _dbs.of(workspaceId).mcpServerDao.deleteById(id);
}
