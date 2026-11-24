import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';

/// The MCP servers configured in each workspace, the workspace's and each
/// member's own alike, stored in that workspace's own database.
///
/// Every call names its workspace, and a definition is written to the
/// database of its own [McpServerDefinition.workspaceId]: there is no second
/// value to disagree with it.
abstract interface class WorkspaceMcpServerRepository {
  /// Every server configured in [workspaceId], the workspace's and every
  /// member's own, by name.
  Future<List<McpServerDefinition>> list(String workspaceId);

  /// The server [id] of [workspaceId], or null when that workspace has none.
  Future<McpServerDefinition?> get(String workspaceId, String id);

  /// Inserts or replaces [definition] in its workspace. Throws
  /// [McpServerDefinitionException.nameTaken] when another server of the same
  /// scope (the workspace's, or the same member's) already has its name.
  Future<void> save(McpServerDefinition definition);

  /// Removes server [id] from [workspaceId]; false when there was none.
  Future<bool> delete(String workspaceId, String id);
}
