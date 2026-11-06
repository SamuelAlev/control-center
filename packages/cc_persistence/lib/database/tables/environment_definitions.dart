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
class EnvironmentDefinitionsTable extends Table {
  /// Definition id.
  TextColumn get id => text()();

  /// Display name.
  TextColumn get name => text()();

  /// The definition as JSON text.
  TextColumn get definitionJson => text()();

  /// The repo holding an in-repo definition, or null.
  TextColumn get sourceRepoId => text().nullable()();

  /// Its path in that repo.
  TextColumn get sourcePath => text().nullable()();

  /// The blob hash an admin approved.
  TextColumn get approvedBlobHash => text().nullable()();

  /// Workspace-side overrides, as JSON text.
  TextColumn get overridesJson => text().nullable()();

  /// Who wrote it. Null for a generated definition.
  TextColumn get createdBy => text().nullable()();

  /// When it was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When it last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'environment_definitions';

  @override
  Set<Column> get primaryKey => {id};
}
