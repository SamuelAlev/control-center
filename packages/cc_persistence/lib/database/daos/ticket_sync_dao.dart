import 'package:cc_persistence/database/tables/ticket_sync_configs_table.dart';
import 'package:cc_persistence/database/tables/ticket_sync_links_table.dart';
import 'package:cc_persistence/database/tables/ticket_sync_log_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'ticket_sync_dao.g.dart';

/// Data access for the multi-vendor ticket sync tables: per-vendor configs,
/// ticket↔vendor links and the append-only sync audit log. All reads are
/// workspace-scoped.
@DriftAccessor(
  tables: [TicketSyncConfigsTable, TicketSyncLinksTable, TicketSyncLogTable],
)
class TicketSyncDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$TicketSyncDaoMixin {
  /// Creates a [TicketSyncDao].
  TicketSyncDao(super.db);

  // ── configs ──

  /// Inserts or updates a sync config (by primary key id).
  Future<void> upsertConfig(TicketSyncConfigsTableCompanion config) =>
      into(ticketSyncConfigsTable).insertOnConflictUpdate(config);

  /// Enabled configs for a workspace.
  Future<List<TicketSyncConfigsTableData>> enabledConfigsForWorkspace(
    String workspaceId,
  ) =>
      (select(ticketSyncConfigsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.enabled.equals(true),
          ))
          .get();

  /// The config for `(workspaceId, vendor)`, or null.
  Future<TicketSyncConfigsTableData?> configForVendor(
    String workspaceId,
    String vendor,
  ) =>
      (select(ticketSyncConfigsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.vendor.equals(vendor),
          ))
          .getSingleOrNull();

  /// All configs for a workspace.
  Future<List<TicketSyncConfigsTableData>> configsForWorkspace(
    String workspaceId,
  ) => (select(
    ticketSyncConfigsTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Watches all configs for a workspace.
  Stream<List<TicketSyncConfigsTableData>> watchConfigsForWorkspace(
    String workspaceId,
  ) =>
      (select(ticketSyncConfigsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.vendor)]))
          .watch();

  /// Deletes a config scoped to [workspaceId]. Returns rows deleted.
  Future<int> deleteConfig(String id, String workspaceId) => (delete(
    ticketSyncConfigsTable,
  )..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId))).go();

  // ── links ──

  /// The link for `(workspaceId, ticketId, vendor)`, or null.
  Future<TicketSyncLinksTableData?> linkForTicketVendor(
    String workspaceId,
    String ticketId,
    String vendor,
  ) =>
      (select(ticketSyncLinksTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.ticketId.equals(ticketId) &
                t.vendor.equals(vendor),
          ))
          .getSingleOrNull();

  /// The link for `(workspaceId, vendor, externalId)`, or null.
  Future<TicketSyncLinksTableData?> linkByExternalId(
    String workspaceId,
    String vendor,
    String externalId,
  ) =>
      (select(ticketSyncLinksTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.vendor.equals(vendor) &
                t.externalId.equals(externalId),
          ))
          .getSingleOrNull();

  /// All links for a ticket, scoped to [workspaceId].
  Future<List<TicketSyncLinksTableData>> linksForTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(ticketSyncLinksTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.ticketId.equals(ticketId),
          ))
          .get();

  /// Inserts a link.
  Future<void> insertLink(TicketSyncLinksTableCompanion link) =>
      into(ticketSyncLinksTable).insert(link);

  /// Updates a link by id.
  Future<void> updateLinkById(String id, TicketSyncLinksTableCompanion link) =>
      (update(ticketSyncLinksTable)..where((t) => t.id.equals(id))).write(link);

  /// Deletes a link scoped to [workspaceId]. Returns rows deleted.
  Future<int> deleteLink(String id, String workspaceId) => (delete(
    ticketSyncLinksTable,
  )..where((t) => t.id.equals(id) & t.workspaceId.equals(workspaceId))).go();

  // ── log ──

  /// Appends a sync log entry.
  Future<void> insertLog(TicketSyncLogTableCompanion entry) =>
      into(ticketSyncLogTable).insert(entry);

  /// Whether an `ok`/`deduplicated` entry already exists for the dedupe key.
  Future<bool> hasProcessed(
    String workspaceId,
    String vendor,
    String dedupeKey,
  ) async {
    final rows =
        await (select(ticketSyncLogTable)
              ..where(
                (t) =>
                    t.workspaceId.equals(workspaceId) &
                    t.vendor.equals(vendor) &
                    t.dedupeKey.equals(dedupeKey) &
                    t.outcome.isIn(['ok', 'deduplicated']),
              )
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  /// The most recent log entries for a workspace (newest first).
  Future<List<TicketSyncLogTableData>> recentLogForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) =>
      (select(ticketSyncLogTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Watches the recent log entries for a workspace.
  Stream<List<TicketSyncLogTableData>> watchLogForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) =>
      (select(ticketSyncLogTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();
}
