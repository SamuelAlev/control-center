import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Drift table definition for pull requests.
@TableIndex(name: 'idx_pull_requests_workspaceId', columns: {#workspaceId})
class PullRequestsTable extends Table {
  /// Unique PR identifier.
  TextColumn get id => text()();

  /// Linked workspace identifier.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// GitHub PR URL, once created.
  TextColumn get githubPrUrl => text().nullable()();

  /// GitHub PR number, once created.
  IntColumn get githubPrNumber => integer().nullable()();

  /// PR title.
  TextColumn get title => text()();

  /// PR body (markdown).
  TextColumn get body => text()();

  /// Status, e.g. 'draft' or 'created'.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Optional diff summary text.
  TextColumn get diffSummary => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when the PR was merged, if at all.
  DateTimeColumn get mergedAt => dateTime().nullable()();

  /// Timestamp when the PR was closed, if at all.
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
