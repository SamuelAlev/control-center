import 'package:drift/drift.dart';

/// Tracks isolated copy-on-write worktrees provisioned per conversation/unit.
///
/// Workspace-scoped: every row carries [workspaceId] and queries MUST filter on
/// it. Keyed uniquely by `(workspaceId, channelId, repoId)` so re-dispatching
/// into the same conversation reuses the existing worktree.
///
/// [channelId] is intentionally NOT a foreign key with cascade: garbage
/// collection reads the row AFTER the channel is deleted to also tear down the
/// on-disk worktree, which a DB cascade could not do.
@TableIndex(name: 'idx_isolated_repos_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_isolated_repos_channel', columns: {#channelId})
@TableIndex(name: 'idx_isolated_repos_ticket', columns: {#ticketId})
@TableIndex(
  name: 'idx_isolated_repos_unit',
  columns: {#workspaceId, #channelId, #repoId},
  unique: true,
)
class IsolatedReposTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Owning workspace (the isolation boundary).
  TextColumn get workspaceId => text().customConstraint(
        'NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE',
      )();

  /// The conversation/channel this worktree belongs to (the unit).
  TextColumn get channelId => text()();

  /// The source repo this is a copy of.
  TextColumn get repoId => text().customConstraint(
        'NOT NULL REFERENCES repos (id) ON DELETE CASCADE',
      )();

  /// Absolute path to the isolated worktree on disk.
  TextColumn get path => text()();

  /// Branch checked out in the worktree.
  TextColumn get branch => text()();

  /// Backend that produced it (`rift` | `gitWorktree`).
  TextColumn get backend => text().withDefault(const Constant('rift'))();

  /// Absolute path to the original repo this was copied from.
  TextColumn get sourcePath => text()();

  /// Owning ticket id, when the unit is a ticket.
  TextColumn get ticketId => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'isolated_repos';

  @override
  Set<Column> get primaryKey => {id};
}
