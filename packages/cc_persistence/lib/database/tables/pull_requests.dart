import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Drift table definition for pull requests a workspace drafts before they are
/// opened on the forge.
///
/// There is no natural key: a draft has no forge number until it is created,
/// and it names no repository.
// The list is newest first. The name predates the index's columns.
@TableIndex(name: 'idx_pull_requests_ws_created', columns: {#createdAt})
class PullRequestsTable extends Table {
  /// Unique PR identifier.
  TextColumn get id => text()();

  /// Linked workspace identifier.
  TextColumn get workspaceId => text()();

  /// GitHub PR URL, once created.
  TextColumn get prUrl => text().nullable()();

  /// GitHub PR number, once created.
  IntColumn get prNumber => integer().nullable()();

  /// PR title.
  TextColumn get title => text()();

  /// PR body (markdown).
  TextColumn get body => text()();

  /// A `PrGenerationStatus` name: `draft`, `published` or `created`.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(PlatformStoredValues.prGenerationStatus))
      .withDefault(const Constant('draft'))();

  /// Optional diff summary text.
  TextColumn get diffSummary => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when the PR was merged, if at all.
  DateTimeColumn get mergedAt => dateTime().nullable()();

  /// Timestamp when the PR was closed, if at all.
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  String get tableName => 'pull_requests';

  @override
  Set<Column> get primaryKey => {id};
}
