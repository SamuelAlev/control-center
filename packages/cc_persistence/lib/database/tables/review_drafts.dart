import 'package:drift/drift.dart';

/// Drift table for storing review comment drafts.
///
/// Keyed by `{owner}/{repo}/{prNumber}` so that each PR gets one draft.
class ReviewDrafts extends Table {
  /// Composite key: `{owner}/{repo}/{prNumber}`.
  TextColumn get id => text()();

  /// GitHub owner (user or org).
  TextColumn get owner => text()();

  /// GitHub repository name.
  TextColumn get repo => text()();

  /// GitHub pull request number.
  IntColumn get prNumber => integer()();

  /// The draft comment text (markdown).
  TextColumn get commentText => text()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
