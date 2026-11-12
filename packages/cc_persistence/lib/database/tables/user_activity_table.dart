import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// Drift table for the append-only per-user audit trail.
///
/// One row per human-attributed action, written at the op chokepoint.
/// Workspace-scoped; rows are never updated and are pruned by the retention
/// service.
// The audit pages walk it newest first with the id as tiebreak, and the
// retention sweep deletes by its time.
@TableIndex(name: 'idx_user_activity_created', columns: {#createdAt, #id})
class UserActivityTable extends Table {
  /// Unique entry identifier.
  TextColumn get id => text()();

  /// The workspace the action happened in (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The human who performed the action. No foreign key: `users` lives in
  /// `global.db`.
  TextColumn get userId => text()();

  /// What happened (op name or semantic action). Open set: every op name.
  TextColumn get action => text()();

  /// Kind of entity acted on, when known. Open set: named by each op.
  TextColumn get targetType => text().nullable()();

  /// Id of the entity acted on, when known. No foreign key: it names a row
  /// of whichever table [targetType] means, or none.
  TextColumn get targetId => text().nullable()();

  /// The device the action came from, when known.
  TextColumn get deviceId => text().nullable()();

  /// The client IP observed for the call, when known.
  TextColumn get ip => text().nullable()();

  /// ISO 3166-1 alpha-2 country code resolved from the IP at record time,
  /// when resolvable (null for private/loopback/unknown).
  TextColumn get countryCode => text().nullable()();

  /// Sanitized JSON object of the mutation's arguments (and a few
  /// contextual result fields). Null when nothing useful survived
  /// redaction.
  TextColumn get details => text().nullable().check(
    // ignore: recursive_getters
    isJsonObject(details),
  )();

  /// When the action happened.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'user_activity';

  @override
  Set<Column> get primaryKey => {id};
}
