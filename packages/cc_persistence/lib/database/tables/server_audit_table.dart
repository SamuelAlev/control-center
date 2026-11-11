import 'package:drift/drift.dart';

/// Drift table for the server-scope audit trail.
///
/// One row per install-wide mutating op call (no workspace owns it, which is
/// why this lives in `global.db`). Rows hold the caller, the op, the names of
/// the arguments and the outcome; never an argument value. Append-only, capped
/// to the newest rows by the DAO.
@TableIndex(name: 'idx_server_audit_created', columns: {#createdAt})
class ServerAuditTable extends Table {
  /// Unique entry identifier.
  TextColumn get id => text()();

  /// The person who made the call.
  TextColumn get userId => text()();

  /// The device the call came from, when known.
  TextColumn get deviceId => text().nullable()();

  /// The client address the session observed, when known.
  TextColumn get ip => text().nullable()();

  /// The op name.
  TextColumn get op => text()();

  /// JSON array of the argument names, sorted.
  TextColumn get argNames => text()();

  /// `ok`, `denied` or `failed`.
  TextColumn get outcome => text()();

  /// When the call ended.
  DateTimeColumn get createdAt => dateTime()();

  @override
  String get tableName => 'server_audit';

  @override
  Set<Column> get primaryKey => {id};
}
