import 'package:drift/drift.dart';

/// Association table linking a PR review to a messaging channel.
///
/// Follows the [WorkspaceReposTable] pattern: composite PK, FKs to both
/// sides with CASCADE, lives in shared `core/database/tables/`, owns its DAO.
/// A review channel is just a regular `group` channel — the review context
@TableIndex(name: 'idx_review_channels_workspaceId', columns: {#workspaceId})
/// is established by this association, not by the channel type.
@TableIndex(name: 'idx_review_channels_prNodeId', columns: {#prNodeId})
class ReviewChannelsTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Linked channel identifier.
  TextColumn get channelId => text().customConstraint(
    'NOT NULL REFERENCES channels (id) ON DELETE CASCADE',
  )();

  /// Linked workspace identifier.
  TextColumn get workspaceId => text().customConstraint(
    'NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE',
  )();

  /// GitHub PR node ID.
  TextColumn get prNodeId => text()();

  /// GitHub PR number.
  IntColumn get prNumber => integer()();

  /// Repository full name, e.g. `"owner/repo"`.
  TextColumn get repoFullName => text()();

  /// Review status: `requested`, `in_progress`, `awaiting_approval`, `completed`.
  TextColumn get status => text().withDefault(const Constant('requested'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'review_channels';

  @override
  Set<Column> get primaryKey => {id};
}
