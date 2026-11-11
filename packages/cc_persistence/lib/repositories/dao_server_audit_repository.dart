import 'dart:convert';

import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/repositories/server_audit_repository.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_persistence/database/daos/server_audit_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ServerAuditRepository] over the global database.
///
/// Holding this DAO is safe: `global.db` is one file for the whole install.
class DaoServerAuditRepository implements ServerAuditRepository {
  /// Creates a [DaoServerAuditRepository] over the global DAO.
  DaoServerAuditRepository(this._dao);

  final ServerAuditDao _dao;

  @override
  Future<void> append(ServerAuditEntry entry) => _dao.append(
    ServerAuditTableCompanion.insert(
      id: entry.id,
      userId: entry.userId,
      deviceId: Value(entry.deviceId),
      ip: Value(entry.ip),
      op: entry.op,
      argNames: jsonEncode(entry.argNames),
      outcome: entry.outcome.name,
      createdAt: entry.createdAt,
    ),
  );

  @override
  Future<List<ServerAuditEntry>> pageRows({
    ActivityCursor? olderThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) async => [
    for (final row in await _dao.pageRows(
      olderThan: olderThan,
      limit: limit,
      filter: filter,
    ))
      _toDomain(row),
  ];

  @override
  Future<List<ServerAuditEntry>> newerRows({
    required ActivityCursor newerThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) async => [
    for (final row in await _dao.newerRows(
      newerThan: newerThan,
      limit: limit,
      filter: filter,
    ))
      _toDomain(row),
  ];

  @override
  Future<int> count({
    AuditLogFilter filter = const AuditLogFilter(),
    ActivityCursor? newerThan,
  }) => _dao.count(filter: filter, newerThan: newerThan);

  @override
  Future<Map<String, int>> countByActor({
    AuditLogFilter filter = const AuditLogFilter(),
  }) => _dao.countBy((t) => t.userId, filter: filter);

  @override
  Future<Map<AuditOutcome, int>> countByOutcome({
    AuditLogFilter filter = const AuditLogFilter(),
  }) async {
    final byName = AuditOutcome.values.asNameMap();
    return {
      for (final e in (await _dao.countBy(
        (t) => t.outcome,
        filter: filter,
      )).entries)
        ?byName[e.key]: e.value,
    };
  }

  @override
  Stream<void> watchChanges() => _dao.watchChanges();

  static ServerAuditEntry _toDomain(ServerAuditTableData row) =>
      ServerAuditEntry(
        id: row.id,
        userId: row.userId,
        deviceId: row.deviceId,
        ip: row.ip,
        op: row.op,
        argNames: [
          for (final name in jsonDecode(row.argNames) as List) '$name',
        ],
        outcome: AuditOutcome.values.byName(row.outcome),
        createdAt: row.createdAt,
      );
}
