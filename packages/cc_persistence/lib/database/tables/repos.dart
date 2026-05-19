import 'package:cc_persistence/database/tables/workspace_repos.dart'
    show WorkspaceReposTable;
import 'package:drift/drift.dart';

/// Drift table definition for repositories.
///
/// Repos are managed independently from workspaces. A workspace can link to
/// zero or more repos via [WorkspaceReposTable].
class ReposTable extends Table {
  /// Unique repository identifier.
  TextColumn get id => text()();

  /// Human-readable display name (defaults to `owner/repo` at creation time).
  TextColumn get name => text()();

  /// Absolute filesystem path to the local working tree.
  TextColumn get path => text()();

  /// GitHub owner parsed from the repo's `origin` remote.
  TextColumn get githubOwner => text().withDefault(const Constant(''))();

  /// GitHub repo name parsed from the repo's `origin` remote.
  TextColumn get githubRepoName => text().withDefault(const Constant(''))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'repos';

  @override
  Set<Column> get primaryKey => {id};
}
