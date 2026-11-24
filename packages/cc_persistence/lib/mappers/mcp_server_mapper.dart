import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Rows ↔ entities for the `mcp_servers` table.
///
/// Timestamps come back in UTC, the zone the entity's wire form uses:
/// `DateTime ==` compares zones, so a local value would never equal the
/// definition it was saved from.
class McpServerMapper {
  /// Creates an [McpServerMapper].
  const McpServerMapper();

  /// Row → entity. Rows carry no workspace column, so the caller names the file
  /// they came from.
  McpServerDefinition fromRow(McpServersTableData row, String workspaceId) =>
      McpServerDefinition(
        id: row.id,
        workspaceId: workspaceId,
        userId: row.userId.isEmpty ? null : row.userId,
        name: row.name,
        transport: McpServerTransport.fromWire(row.transport),
        command: row.command,
        args: _strings(row.argsJson),
        url: row.url,
        envNames: _strings(row.envNamesJson),
        headerNames: _strings(row.headerNamesJson),
        enabled: row.enabled,
        createdBy: row.createdBy,
        hostApprovedBy: row.hostApprovedBy,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );

  /// Entity → row. The workspace is the database it is written to.
  McpServersTableCompanion toCompanion(McpServerDefinition definition) =>
      McpServersTableCompanion(
        id: Value(definition.id),
        userId: Value(definition.userId ?? ''),
        name: Value(definition.name),
        transport: Value(definition.transport.wire),
        command: Value(definition.command),
        argsJson: Value(jsonEncode(definition.args)),
        url: Value(definition.url),
        envNamesJson: Value(jsonEncode(definition.envNames)),
        headerNamesJson: Value(jsonEncode(definition.headerNames)),
        enabled: Value(definition.enabled),
        createdBy: Value(definition.createdBy),
        hostApprovedBy: Value(definition.hostApprovedBy),
        createdAt: Value(definition.createdAt),
        updatedAt: Value(definition.updatedAt),
      );

  /// The strings of a JSON array column. The column's check guarantees an
  /// array, and every element was written as a string.
  static List<String> _strings(String json) => [
    for (final value in jsonDecode(json) as List<Object?>) '$value',
  ];
}
