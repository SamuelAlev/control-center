import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Association table linking a PR review to a messaging space.
///
/// A review space is just a regular `group` space — the review context
/// is established by this association, not by the space type. A space may
/// carry several associations and a PR may be associated more than once, so
/// neither pair is unique; every lookup reads the newest.
@TableIndex(
  name: 'idx_review_spaces_prExternalId',
  columns: {#prExternalId, #createdAt},
)
@TableIndex(name: 'idx_review_spaces_space', columns: {#spaceId, #createdAt})
class ReviewSpacesTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Linked space identifier; the association goes with its space.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// Linked workspace identifier.
  TextColumn get workspaceId => text().customConstraint('NOT NULL')();

  /// GitHub PR node ID.
  TextColumn get prExternalId => text()();

  /// GitHub PR number.
  IntColumn get prNumber => integer()();

  /// Repository full name, e.g. `"owner/repo"`.
  TextColumn get repoFullName => text()();

  /// A `ReviewSpaceStatus` wire name: `requested`, `in_progress`,
  /// `awaiting_approval`, `completed`.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(PlatformStoredValues.reviewSpaceStatus))
      .withDefault(const Constant('requested'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'review_spaces';

  @override
  Set<Column> get primaryKey => {id};
}
