import 'package:drift/drift.dart';

/// Drift table definition for repositories.
///
/// **Workspace-scoped.** A repo row lives in its workspace's own database file,
/// so there is no `workspaceId` column and no join table: the file *is* the
/// scope. The former server-global `repos` table and its `workspace_repos`
/// many-to-many collapsed into this one table when the database was split into
/// `global.db` + one file per workspace — within a single workspace a repo is
/// linked exactly zero or one times, so the join row carried no information.
///
/// The two columns absorbed from the old link row are [position] (the
/// operator's manual drag-to-reorder order) and [linkedAt] (its tiebreak).
///
/// Consequence of the split: the same checkout registered in two workspaces is
/// two independent rows with two ids. Repo identity *across* workspaces is by
/// [path] (or owner/name), never by id.
class ReposTable extends Table {
  /// Unique repository identifier (unique within this workspace).
  TextColumn get id => text()();

  /// Human-readable display name (defaults to `owner/repo` at creation time).
  TextColumn get name => text()();

  /// Absolute filesystem path to the local working tree.
  TextColumn get path => text()();

  /// The forge this repo is hosted on (`github` / `gitlab` / `bitbucket`),
  /// parsed from the `origin` remote at registration.
  ///
  /// A workspace may hold repos on several forges at once, so this — not a
  /// workspace-level setting — is what selects an API adapter and a credential.
  TextColumn get forge => text().withDefault(const Constant('github'))();

  /// Owner path parsed from the repo's `origin` remote: a GitHub owner, a
  /// Bitbucket workspace, or a (possibly nested) GitLab namespace.
  TextColumn get remoteOwner => text().withDefault(const Constant(''))();

  /// Repository name parsed from the repo's `origin` remote.
  TextColumn get remoteName => text().withDefault(const Constant(''))();

  /// The operator's manual order within the workspace (drag-to-reorder in
  /// settings). Ascending, 0-based; the single ordering every repo list reads,
  /// with [linkedAt] as the stable tiebreak.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// When the repo was added to this workspace (the ordering tiebreak).
  DateTimeColumn get linkedAt => dateTime().withDefault(currentDateAndTime)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'repos';

  @override
  Set<Column> get primaryKey => {id};
}
