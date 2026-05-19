import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between the multi-vendor ticket-sync domain entities and their Drift
/// rows. Stateless (`static const`), like the other repo mappers.
class TicketSyncMapper {
  /// Creates a [TicketSyncMapper].
  const TicketSyncMapper();

  // ── config ──

  /// Domain config → companion.
  TicketSyncConfigsTableCompanion configToCompanion(TicketSyncConfig c) {
    return TicketSyncConfigsTableCompanion(
      id: Value(c.id),
      workspaceId: Value(c.workspaceId),
      vendor: Value(c.vendor),
      vendorProjectId: Value(c.vendorProjectId),
      direction: Value(c.direction.toStorageString()),
      fieldMapping: Value(c.fieldPolicy.toJson()),
      credentialRef: Value(c.credentialRef),
      webhookSecret: Value(c.webhookSecret),
      enabled: Value(c.enabled),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
    );
  }

  /// Row → domain config.
  TicketSyncConfig configFromRow(TicketSyncConfigsTableData row) {
    return TicketSyncConfig(
      id: row.id,
      workspaceId: row.workspaceId,
      vendor: row.vendor,
      vendorProjectId: row.vendorProjectId,
      direction: SyncDirection.fromStorage(row.direction),
      fieldPolicy: TicketFieldConflictPolicy.fromJson(row.fieldMapping),
      credentialRef: row.credentialRef,
      webhookSecret: row.webhookSecret,
      enabled: row.enabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ── link ──

  /// Domain link → companion.
  TicketSyncLinksTableCompanion linkToCompanion(TicketSyncLink l) {
    return TicketSyncLinksTableCompanion(
      id: Value(l.id),
      workspaceId: Value(l.workspaceId),
      ticketId: Value(l.ticketId),
      vendor: Value(l.vendor),
      externalId: Value(l.externalId),
      externalKey: Value(l.externalKey),
      externalUrl: Value(l.externalUrl),
      lastSyncedAt: Value(l.lastSyncedAt),
      lastDirection: Value(l.lastDirection?.toStorageString()),
    );
  }

  /// Row → domain link.
  TicketSyncLink linkFromRow(TicketSyncLinksTableData row) {
    return TicketSyncLink(
      id: row.id,
      workspaceId: row.workspaceId,
      ticketId: row.ticketId,
      vendor: row.vendor,
      externalId: row.externalId,
      externalKey: row.externalKey,
      externalUrl: row.externalUrl,
      lastSyncedAt: row.lastSyncedAt,
      lastDirection: row.lastDirection == null
          ? null
          : SyncDirection.fromStorage(row.lastDirection),
    );
  }

  // ── log ──

  /// Domain log entry → companion.
  TicketSyncLogTableCompanion logToCompanion(TicketSyncLogEntry e) {
    return TicketSyncLogTableCompanion(
      id: Value(e.id),
      workspaceId: Value(e.workspaceId),
      ticketId: Value(e.ticketId),
      vendor: Value(e.vendor),
      direction: Value(e.direction.toStorageString()),
      outcome: Value(e.outcome.toStorageString()),
      message: Value(e.message),
      dedupeKey: Value(e.dedupeKey),
      createdAt: Value(e.createdAt),
    );
  }

  /// Row → domain log entry.
  TicketSyncLogEntry logFromRow(TicketSyncLogTableData row) {
    return TicketSyncLogEntry(
      id: row.id,
      workspaceId: row.workspaceId,
      ticketId: row.ticketId,
      vendor: row.vendor,
      direction: SyncDirection.fromStorage(row.direction),
      outcome: SyncOutcome.fromStorage(row.outcome),
      message: row.message,
      dedupeKey: row.dedupeKey,
      createdAt: row.createdAt,
    );
  }
}
