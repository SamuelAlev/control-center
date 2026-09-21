import 'package:drift/drift.dart';

/// Self-identification for a workspace database file.
///
/// Exactly one row, written when the file is created.
/// It makes a `workspaces/<id>.db` file self-describing, which is what lets
/// `workspace.export` hand out a single file and `workspace.import` verify that what came
/// back is a workspace database (and whose):
/// * [workspaceId] — the workspace this file holds.
class WorkspaceMetaTable extends Table {
  /// Single-row guard: always `0`.
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// The workspace this database file belongs to.
  TextColumn get workspaceId => text()();

  /// The `server_meta.install_id` of the server that created this file.
  TextColumn get installId => text()();

  /// Schema version of the workspace database when the file was created.
  IntColumn get createdWithSchemaVersion => integer()();

  /// When the file was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_meta';

  @override
  Set<Column> get primaryKey => {id};
}
