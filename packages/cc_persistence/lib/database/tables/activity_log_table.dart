import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_activity_log_agent', columns: {#actorId})
@TableIndex(name: 'idx_activity_log_entity', columns: {#entityType, #entityId})
// The recent feed walks it newest first; the retention sweep deletes by it.
@TableIndex(name: 'idx_activity_log_created', columns: {#createdAt})
@TableIndex(name: 'idx_activity_log_run', columns: {#runId})
/// Drift table for activity log entries.
class ActivityLogTable extends Table {
  /// Unique log entry identifier.
  TextColumn get id => text()();

  /// Workspace this entry is scoped to: the one this file holds. An entry
  /// that names no workspace is not written to any workspace file.
  TextColumn get workspaceId => text()();

  /// Type of the actor (e.g. 'agent', 'user', 'system'). Open set: written
  /// from `ActivityLogged` events, which carry it as free text.
  TextColumn get actorType => text()();

  /// Id of the acting agent, if any.
  TextColumn get actorId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The action performed. Open set, as [actorType].
  TextColumn get action => text()();

  /// Type of the entity acted upon. Open set, as [actorType].
  TextColumn get entityType => text()();

  /// Id of the entity acted upon. No foreign key: it names a row of
  /// whichever table [entityType] means.
  TextColumn get entityId => text().nullable()();

  /// Optional details about the action: free text, which some writers fill
  /// with JSON and others with a sentence.
  TextColumn get details => text().nullable()();

  /// Optional run id that produced this entry. `ON DELETE SET NULL`: the
  /// audit row outlives the run log the retention sweep prunes.
  TextColumn get runId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When this entry was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'activity_log';

  @override
  Set<Column> get primaryKey => {id};
}
