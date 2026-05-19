import 'package:drift/drift.dart';

/// Drift table for the append-only per-user audit trail.
///
/// One row per human-attributed action, written at the op chokepoint.
/// Workspace-scoped; rows are never updated and are pruned by the retention
/// service.
@TableIndex(
  name: 'idx_user_activity_ws_created',
  columns: {#workspaceId, #createdAt},
)
class UserActivityTable extends Table {
  /// Unique entry identifier.
  TextColumn get id => text()();

  /// The workspace the action happened in (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The human who performed the action.
  TextColumn get userId => text()();

  /// What happened (op name or semantic action).
  TextColumn get action => text()();

  /// Kind of entity acted on, when known.
  TextColumn get targetType => text().nullable()();

  /// Id of the entity acted on, when known.
  TextColumn get targetId => text().nullable()();

  /// The device the action came from, when known.
  TextColumn get deviceId => text().nullable()();

  /// The client IP observed for the call, when known.
  TextColumn get ip => text().nullable()();

  /// ISO 3166-1 alpha-2 country code resolved from the IP at record time,
  /// when resolvable (null for private/loopback/unknown).
  TextColumn get countryCode => text().nullable()();

  /// When the action happened.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'user_activity';

  @override
  Set<Column> get primaryKey => {id};
}
