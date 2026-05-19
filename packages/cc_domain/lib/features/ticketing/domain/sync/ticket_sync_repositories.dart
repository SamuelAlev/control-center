import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';

/// Persistence boundary for vendor sync connections (workspace-scoped).
abstract interface class TicketSyncConfigRepository {
  /// Inserts or updates a config.
  Future<void> upsert(TicketSyncConfig config);

  /// The enabled configs for a workspace.
  Future<List<TicketSyncConfig>> enabledForWorkspace(String workspaceId);

  /// The config for `(workspaceId, vendor)`, or null.
  Future<TicketSyncConfig?> forVendor(String workspaceId, String vendor);

  /// All configs for a workspace (enabled and disabled), for the settings UI.
  Future<List<TicketSyncConfig>> forWorkspace(String workspaceId);

  /// Watches all configs for a workspace.
  Stream<List<TicketSyncConfig>> watchForWorkspace(String workspaceId);

  /// Deletes a config by id, scoped to [workspaceId]. Returns rows deleted.
  Future<int> delete(String id, {required String workspaceId});
}

/// Persistence boundary for ticket↔vendor links (workspace-scoped).
abstract interface class TicketSyncLinkRepository {
  /// Inserts or updates a link (idempotent on `(workspaceId, ticketId, vendor)`).
  Future<void> upsert(TicketSyncLink link);

  /// The link for `(workspaceId, ticketId, vendor)`, or null.
  Future<TicketSyncLink?> forTicketVendor(
    String workspaceId,
    String ticketId,
    String vendor,
  );

  /// The local ticket id linked to `(workspaceId, vendor, externalId)`, or null.
  Future<TicketSyncLink?> byExternalId(
    String workspaceId,
    String vendor,
    String externalId,
  );

  /// All links for a ticket, scoped to [workspaceId].
  Future<List<TicketSyncLink>> forTicket(String workspaceId, String ticketId);

  /// Deletes a link, scoped to [workspaceId]. Returns rows deleted.
  Future<int> delete(String id, {required String workspaceId});
}

/// Persistence boundary for the append-only sync audit log (workspace-scoped).
abstract interface class TicketSyncLogRepository {
  /// Appends an entry.
  Future<void> append(TicketSyncLogEntry entry);

  /// Whether an `ok`/`deduplicated` entry already exists for `(workspaceId,
  /// vendor, dedupeKey)` — i.e. the inbound event was already processed.
  Future<bool> hasProcessed(
    String workspaceId,
    String vendor,
    String dedupeKey,
  );

  /// The most recent entries for a workspace (newest first), capped at [limit].
  Future<List<TicketSyncLogEntry>> recentForWorkspace(
    String workspaceId, {
    int limit = 100,
  });

  /// Watches the recent entries for a workspace.
  Stream<List<TicketSyncLogEntry>> watchForWorkspace(
    String workspaceId, {
    int limit = 100,
  });
}
