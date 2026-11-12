import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Each person's editor layout (panes, tabs, sizes) of a space's messaging IDE
/// or a pull request's workbench.
///
/// Personal state that roams with the person across their devices. It is
/// rewritten only when the arrangement changes, so nothing prunes it by age.
class EditorLayoutsTable extends Table {
  @override
  String get tableName => 'editor_layouts';

  /// Whose layout it is. No foreign key: users live in the global database.
  TextColumn get userId => text()();

  /// What it arranges: an `EditorLayoutSurface` wire name.
  TextColumn get surface => text().check(
    // ignore: recursive_getters
    surface.isIn(PlatformStoredValues.editorLayoutSurface),
  )();

  /// The space id or the `owner/repo#number` of the pull request. No foreign
  /// key: it names a space or a forge pull request, depending on [surface].
  TextColumn get target => text()();

  /// The client's encoded layout.
  // ignore: recursive_getters
  TextColumn get layout => text().check(isJson(layout))();

  /// When it last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, surface, target};
}
