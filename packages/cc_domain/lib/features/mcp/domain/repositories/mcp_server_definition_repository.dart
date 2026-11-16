import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';

/// The MCP servers configured for each workspace, stored in that workspace's
/// own database.
///
/// Every call names its workspace, and a definition is written to the
/// database of its own [McpServerDefinition.workspaceId]: there is no second
/// value to disagree with it.
abstract interface class WorkspaceMcpServerRepository {
  /// Every server configured in [workspaceId], by name.
  Future<List<McpServerDefinition>> list(String workspaceId);

  /// The server [id] of [workspaceId], or null when that workspace has none.
  Future<McpServerDefinition?> get(String workspaceId, String id);

  /// Inserts or replaces [definition] in its workspace. Throws
  /// [McpServerDefinitionException.nameTaken] when another server of that
  /// workspace already has its name.
  Future<void> save(McpServerDefinition definition);

  /// Removes server [id] from [workspaceId]; false when there was none.
  Future<bool> delete(String workspaceId, String id);
}

/// The server owner's personal MCP servers added by hand, kept in the host's
/// data directory beside the ones discovered in their own tool configs.
abstract interface class PersonalMcpServerRepository {
  /// Every personal server added by hand, by name.
  Future<List<McpServerDefinition>> list();

  /// The server [id], or null.
  Future<McpServerDefinition?> get(String id);

  /// Inserts or replaces [definition] (which has no workspace). Throws
  /// [McpServerDefinitionException.nameTaken] on a name clash.
  Future<void> save(McpServerDefinition definition);

  /// Removes server [id]; false when there was none.
  Future<bool> delete(String id);
}
