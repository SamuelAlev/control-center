import 'package:drift/drift.dart';

/// A GitHub repository registered as a skill source for a workspace (the
/// replacement for the removed skills.sh registry).
///
/// Sources are workspace-scoped: the catalogs you browse belong to the
/// workspace whose skills they install into. The row is provenance + sync
/// metadata only — it never grants trust; every install still passes the
/// mandatory scan gate. `skills-lock.json` stays the file-based source of
/// truth for what is installed.
@TableIndex(name: 'idx_skill_sources_workspace', columns: {#workspaceId})
class SkillSourcesTable extends Table {
  @override
  String get tableName => 'skill_sources';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// GitHub owner (user or org login).
  TextColumn get owner => text()();

  /// GitHub repository name.
  TextColumn get repo => text()();

  /// Normalized `https://github.com/owner/repo` URL as entered.
  TextColumn get url => text()();

  /// Repository description at add/sync time (untrusted).
  TextColumn get description => text().withDefault(const Constant(''))();

  /// The repo's default branch (the browsing ref).
  TextColumn get defaultBranch => text().withDefault(const Constant(''))();

  /// Star count at add/sync time (untrusted popularity signal).
  IntColumn get starCount => integer().withDefault(const Constant(0))();

  /// Skills discovered at the last sync.
  IntColumn get skillCount => integer().withDefault(const Constant(0))();

  /// When the catalog was last listed.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// The last sync's error, if any.
  TextColumn get lastError => text().nullable()();

  /// Row creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, owner, repo},
  ];
}
