import 'package:control_center/core/database/tables/agents.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_activity_log_agent', columns: {#actorId})
@TableIndex(name: 'idx_activity_log_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_activity_log_created', columns: {#createdAt})
@TableIndex(name: 'idx_activity_log_workspace', columns: {#workspaceId, #createdAt})
/// Drift table for activity log entries.
class ActivityLogTable extends Table {
  /// Unique log entry identifier.
  TextColumn get id => text()();
  /// Workspace this entry is scoped to. Nullable only for genuinely
  /// app-level entries; every workspace-scoped DAO read filters on it.
  TextColumn get workspaceId => text().nullable()();
  /// Type of the actor (e.g. 'agent', 'user').
  TextColumn get actorType => text()();
  /// Id of the acting agent, if any.
  TextColumn get actorId => text().nullable().references(
        AgentsTable,
        #id,
        onDelete: KeyAction.setNull,
      )();
  /// The action performed.
  TextColumn get action => text()();
  /// Type of the entity acted upon.
  TextColumn get entityType => text()();
  /// Id of the entity acted upon.
  TextColumn get entityId => text().nullable()();
  /// Optional JSON details about the action.
  TextColumn get details => text().nullable()();
  /// Optional run id that produced this entry.
  TextColumn get runId => text().nullable()();
  /// When this entry was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
