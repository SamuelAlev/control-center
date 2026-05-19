import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_persistence/database/daos/ticket_sync_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/ticket_sync_mappers.dart';

const _mapper = TicketSyncMapper();

/// Drift-backed [TicketSyncConfigRepository].
///
/// Sync configs are workspace-scoped rows in the workspace's own database file;
/// the `workspaceId` on each method (or on the entity being written) picks the
/// file.
class DaoTicketSyncConfigRepository implements TicketSyncConfigRepository {
  /// Creates a [DaoTicketSyncConfigRepository] over the per-workspace
  /// databases.
  DaoTicketSyncConfigRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TicketSyncDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketSyncDao;

  @override
  Future<void> upsert(TicketSyncConfig config) =>
      _dao(config.workspaceId).upsertConfig(_mapper.configToCompanion(config));

  @override
  Future<List<TicketSyncConfig>> enabledForWorkspace(String workspaceId) async {
    final rows = await _dao(
      workspaceId,
    ).enabledConfigsForWorkspace(workspaceId);
    return rows.map(_mapper.configFromRow).toList();
  }

  @override
  Future<TicketSyncConfig?> forVendor(String workspaceId, String vendor) async {
    final row = await _dao(workspaceId).configForVendor(workspaceId, vendor);
    return row == null ? null : _mapper.configFromRow(row);
  }

  @override
  Future<List<TicketSyncConfig>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).configsForWorkspace(workspaceId);
    return rows.map(_mapper.configFromRow).toList();
  }

  @override
  Stream<List<TicketSyncConfig>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchConfigsForWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.configFromRow).toList());

  @override
  Future<int> delete(String id, {required String workspaceId}) =>
      _dao(workspaceId).deleteConfig(id, workspaceId);
}

/// Drift-backed [TicketSyncLinkRepository].
class DaoTicketSyncLinkRepository implements TicketSyncLinkRepository {
  /// Creates a [DaoTicketSyncLinkRepository] over the per-workspace databases.
  DaoTicketSyncLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TicketSyncDao _dao(String workspaceId) => _dbs.of(workspaceId).ticketSyncDao;

  @override
  Future<void> upsert(TicketSyncLink link) async {
    final dao = _dao(link.workspaceId);
    // Idempotent on (workspaceId, ticketId, vendor): update the existing row by
    // id when present, else insert. (The PK is the synthetic id, so a plain
    // insert-or-replace would not dedupe on the natural key.)
    final existing = await dao.linkForTicketVendor(
      link.workspaceId,
      link.ticketId,
      link.vendor,
    );
    final companion = _mapper.linkToCompanion(link);
    if (existing == null) {
      await dao.insertLink(companion);
    } else {
      await dao.updateLinkById(existing.id, companion);
    }
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
