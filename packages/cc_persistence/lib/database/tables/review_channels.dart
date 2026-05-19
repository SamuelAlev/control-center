import 'package:drift/drift.dart';

/// Association table linking a PR review to a messaging channel.
///
/// A review channel is just a regular `group` channel — the review context
/// is established by this association, not by the channel type.
@TableIndex(name: 'idx_review_channels_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_review_channels_prExternalId', columns: {#prExternalId})
class ReviewChannelsTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Linked channel identifier.
  TextColumn get channelId => text().customConstraint(
    'NOT NULL REFERENCES channels (id) ON DELETE CASCADE',
  )();

  /// Linked workspace identifier.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// GitHub PR node ID.
  TextColumn get prExternalId => text()();

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
