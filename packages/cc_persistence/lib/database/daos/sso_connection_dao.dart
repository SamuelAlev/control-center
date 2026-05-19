import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/sso_connections_table.dart';
import 'package:drift/drift.dart';

part 'sso_connection_dao.g.dart';

/// Data access object for [SsoConnectionsTable].
///
/// CROSS-WORKSPACE BY DESIGN — authentication is server-wide; membership is
/// the workspace boundary, gated by each connection's auto-member policy.
@DriftAccessor(tables: [SsoConnectionsTable])
class SsoConnectionDao extends DatabaseAccessor<GlobalDatabase>
    with _$SsoConnectionDaoMixin {
  /// Creates a [SsoConnectionDao] for the given database.
  SsoConnectionDao(super.attachedDatabase);

  /// Every connection, by id.
  Future<List<SsoConnectionsTableData>> getAll() =>
      (select(ssoConnectionsTable)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Watches every connection.
  Stream<List<SsoConnectionsTableData>> watchAll() =>
      (select(ssoConnectionsTable)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// The connection for [id] (the kind slug), or null.
  Future<SsoConnectionsTableData?> getById(String id) =>
      (select(ssoConnectionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts or updates a connection row.
  Future<void> upsert(SsoConnectionsTableCompanion entry) =>
      into(ssoConnectionsTable).insertOnConflictUpdate(entry);
}
