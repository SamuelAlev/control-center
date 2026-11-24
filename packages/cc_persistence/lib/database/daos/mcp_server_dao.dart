import 'package:cc_persistence/database/tables/mcp_servers.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show SqlExtendedError;

part 'mcp_server_dao.g.dart';

/// Data access object for the MCP servers configured in ONE workspace.
///
/// Every method is scoped by hanging off a [WorkspaceDatabase]: the isolation
/// boundary is the database file.
@DriftAccessor(tables: [McpServersTable])
class McpServerDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$McpServerDaoMixin {
  /// Creates an [McpServerDao] bound to one workspace's database.
  McpServerDao(super.attachedDatabase);

  /// Every server, by name.
  Future<List<McpServersTableData>> all() =>
      (select(mcpServersTable)..orderBy([
            (t) => OrderingTerm.asc(t.name),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .get();

  /// One server, or null.
  Future<McpServersTableData?> byId(String id) => (select(
    mcpServersTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a server, or updates the one with its id. Returns false, writing
  /// nothing, when another server of the same owner already holds its name:
  /// the unique key refuses it, and it is never resolved by replacing that
  /// server.
  Future<bool> upsert(McpServersTableCompanion entry) async {
    try {
      return await transaction(() async {
        final table = mcpServersTable;
        final clash =
            await (selectOnly(table)
                  ..addColumns([table.id])
                  ..where(
                    table.name.equals(entry.name.value) &
                        table.userId.equals(entry.userId.value) &
                        table.id.equals(entry.id.value).not(),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (clash != null) {
          return false;
        }
        await into(table).insertOnConflictUpdate(entry);
        return true;
      });
    } on Object catch (error) {
      // A writer that slipped between the check and the insert still meets
      // the unique key.
      if (sqliteCauseOf(error)?.extendedResultCode ==
          SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE) {
        return false;
      }
      rethrow;
    }
  }

  /// Deletes one server. Returns whether there was one.
  Future<bool> deleteById(String id) async =>
      await (delete(mcpServersTable)..where((t) => t.id.equals(id))).go() > 0;
}
