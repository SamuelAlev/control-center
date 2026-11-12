import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:drift/drift.dart';

/// Drift table of stored environment definitions.
///
/// **Workspace-scoped**, with no `workspace_id` column for the same reason as
/// `repos`: the database file is the scope, and every definition binds roles to
/// repos of this workspace.
///
/// [definitionJson] is the text the server validates again at read time. For an
/// in-repo source it is the last APPROVED content, never the file's current
/// state, so what runs on the host changes only when an admin approves a hash.
@TableIndex(
  name: 'idx_environment_definitions_source_repo',
  columns: {#sourceRepoId},
)
class EnvironmentDefinitionsTable extends Table {
  /// Definition id.
  TextColumn get id => text()();

  /// Display name.
  TextColumn get name => text()();

  /// The definition as a JSON object.
  TextColumn get definitionJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(definitionJson))();

  /// The repo holding an in-repo definition, or null. Unlinking the repo
  /// keeps the definition at its last approved text and stops tracking the
  /// file.
  TextColumn get sourceRepoId => text().nullable().references(
    ReposTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Its path in that repo.
  TextColumn get sourcePath => text().nullable()();

  /// The blob hash an admin approved.
  TextColumn get approvedBlobHash => text().nullable()();

  /// Workspace-side overrides, as a JSON object.
  TextColumn get overridesJson =>
      // ignore: recursive_getters
      text().nullable().check(isJsonObject(overridesJson))();

  /// Who wrote it. Null for a generated definition. No foreign key: users
  /// live in the global database.
  TextColumn get createdBy => text().nullable()();

  /// The server owner who saved it while it ran something on the host; null
  /// when it runs nothing there or no owner approved it. Written only by the
  /// server on save, never from a client's copy. No foreign key: users live
  /// in the global database.
  TextColumn get hostApprovedBy => text().nullable()();

  /// When it was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When it last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'environment_definitions';

  @override
  Set<Column> get primaryKey => {id};
}
