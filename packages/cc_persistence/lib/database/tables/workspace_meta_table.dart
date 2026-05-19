import 'package:drift/drift.dart';

/// Self-identification for a workspace database file.
///
/// Exactly one row, written when the file is created. It makes a
/// `workspaces/<id>.db` file self-describing, which is what lets
/// `workspace.export` hand out a single file and `workspace.import` verify that
/// what came back is a workspace database (and whose):
///
///  * [workspaceId] — the workspace this file holds. An import that disagrees
///    with the filename is rejected rather than silently adopted.
///  * [installId] — the `server_meta.install_id` of the server that created it,
///    so importing another install's file is a recognised (and allowed, but
///    logged) cross-install move rather than an invisible one.
///
/// It is NOT a settings table: the workspace's own row (name, logo, position,
/// owner) stays in `global.db`'s `workspaces` registry, which is what the
/// switcher lists without opening any workspace file.
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
