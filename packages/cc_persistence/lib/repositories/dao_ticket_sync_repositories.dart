import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_persistence/database/daos/ticket_sync_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    show TicketSyncConfigsTableData;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/ticket_sync_mappers.dart';

const _mapper = TicketSyncMapper();

/// Drift-backed [TicketSyncConfigRepository].
///
/// Sync configs are workspace-scoped rows in the workspace's own database file;
/// the `workspaceId` on each method (or on the entity being written) picks the
/// file. A config's webhook secret is kept in the server's secrets store
/// through [WebhookSecretVault]: the row stores only its reference, every read
/// resolves it, and deleting the config deletes it.
class DaoTicketSyncConfigRepository implements TicketSyncConfigRepository {
  /// Creates a [DaoTicketSyncConfigRepository] over the per-workspace
  /// databases, keeping webhook secrets in [_secrets].
  DaoTicketSyncConfigRepository(this._dbs, this._secrets);

  final WorkspaceDatabaseManager _dbs;
  final WebhookSecretVault _secrets;

  TicketSyncDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketSyncDao;

  @override
  Future<void> upsert(TicketSyncConfig config) async {
    final ref = WebhookSecretVault.ticketSyncRef(config.workspaceId, config.id);
    final secret = config.webhookSecret;
    final hasSecret = secret != null && secret.isNotEmpty;
    // Secret first: a row never names a reference with nothing behind it.
    if (hasSecret) {
      await _secrets.write(ref, secret);
    }
    await _dao(config.workspaceId).upsertConfig(
      _mapper.configToCompanion(
        config,
        webhookSecretRef: hasSecret ? ref : null,
      ),
    );
    if (!hasSecret) {
      await _secrets.delete(ref);
    }
  }

  @override
  Future<List<TicketSyncConfig>> enabledForWorkspace(String workspaceId) async {
    final rows = await _dao(
      workspaceId,
    ).enabledConfigsForWorkspace(workspaceId);
    return _fromRows(rows);
  }

  @override
  Future<TicketSyncConfig?> forVendor(String workspaceId, String vendor) async {
    final row = await _dao(workspaceId).configForVendor(workspaceId, vendor);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<TicketSyncConfig>> forWorkspace(String workspaceId) async =>
      _fromRows(await _dao(workspaceId).configsForWorkspace(workspaceId));

  @override
  Stream<List<TicketSyncConfig>> watchForWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchConfigsForWorkspace(workspaceId).asyncMap(_fromRows);

  @override
  Future<int> delete(String id, {required String workspaceId}) async {
    final deleted = await _dao(workspaceId).deleteConfig(id, workspaceId);
    if (deleted > 0) {
      await _secrets.delete(WebhookSecretVault.ticketSyncRef(workspaceId, id));
    }
    return deleted;
  }

  /// [row] as a config, its webhook secret resolved through the secrets store.
  Future<TicketSyncConfig> _fromRow(TicketSyncConfigsTableData row) async {
    final ref = row.webhookSecretRef;
    return _mapper.configFromRow(
      row,
      webhookSecret: ref == null ? null : await _secrets.read(ref),
    );
  }

  Future<List<TicketSyncConfig>> _fromRows(
    List<TicketSyncConfigsTableData> rows,
  ) => Future.wait(rows.map(_fromRow));
}

/// Drift-backed [TicketSyncLinkRepository].
class DaoTicketSyncLinkRepository implements TicketSyncLinkRepository {
  /// Creates a [DaoTicketSyncLinkRepository] over the per-workspace databases.
  DaoTicketSyncLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TicketSyncDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketSyncDao;

  @override
  Future<void> upsert(TicketSyncLink link) async {
    // Idempotent on (ticketId, vendor), the table's unique key: one
    // statement inserts or updates the existing link.
    await _dao(link.workspaceId).upsertLink(_mapper.linkToCompanion(link));
  }

  @override
  Future<TicketSyncLink?> forTicketVendor(
    String workspaceId,
    String ticketId,
    String vendor,
  ) async {
    final row = await _dao(
      workspaceId,
    ).linkForTicketVendor(workspaceId, ticketId, vendor);
    return row == null ? null : _mapper.linkFromRow(row);
  }

  @override
  Future<TicketSyncLink?> byExternalId(
    String workspaceId,
    String vendor,
    String externalId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).linkByExternalId(workspaceId, vendor, externalId);
    return row == null ? null : _mapper.linkFromRow(row);
  }

  @override
  Future<List<TicketSyncLink>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao(workspaceId).linksForTicket(workspaceId, ticketId);
    return rows.map(_mapper.linkFromRow).toList();
  }

  @override
  Future<int> delete(String id, {required String workspaceId}) =>
      _dao(workspaceId).deleteLink(id, workspaceId);
}

/// Drift-backed [TicketSyncLogRepository].
class DaoTicketSyncLogRepository implements TicketSyncLogRepository {
  /// Creates a [DaoTicketSyncLogRepository] over the per-workspace databases.
  DaoTicketSyncLogRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TicketSyncDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketSyncDao;

  @override
  Future<void> append(TicketSyncLogEntry entry) =>
      _dao(entry.workspaceId).insertLog(_mapper.logToCompanion(entry));

  @override
  Future<bool> hasProcessed(
    String workspaceId,
    String vendor,
    String dedupeKey,
  ) => _dao(workspaceId).hasProcessed(workspaceId, vendor, dedupeKey);

  @override
  Future<List<TicketSyncLogEntry>> recentForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).recentLogForWorkspace(workspaceId, limit: limit);
    return rows.map(_mapper.logFromRow).toList();
  }

  @override
  Stream<List<TicketSyncLogEntry>> watchForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) => _dao(workspaceId)
      .watchLogForWorkspace(workspaceId, limit: limit)
      .map((rows) => rows.map(_mapper.logFromRow).toList());
}
