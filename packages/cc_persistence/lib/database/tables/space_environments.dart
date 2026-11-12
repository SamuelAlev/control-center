import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/environment_definitions.dart';
import 'package:cc_persistence/database/tables/rigs_tables.dart';
import 'package:drift/drift.dart';

/// Drift table of the environments spaces own.
///
/// **Workspace-scoped**, with no `workspace_id` column: the database file is
/// the scope. A space runs at most one environment per definition. Fields the
/// server filters on are typed; the rest is JSON written from the entity's wire
/// forms.
///
/// [spaceId] is intentionally NOT a foreign key: the environment service
/// reads the space's rows AFTER the space is deleted (`SpaceDeleted`) to stop
/// what they run, which a cascade would erase first.
@TableIndex(
  name: 'idx_space_environments_definition',
  columns: {#definitionId},
)
@TableIndex(name: 'idx_space_environments_rig', columns: {#rigId})
class SpaceEnvironmentsTable extends Table {
  /// Environment id, a UUID.
  TextColumn get id => text()();

  /// Owning space. Not a foreign key: see the class doc.
  TextColumn get spaceId => text()();

  /// The definition it was started from. A definition is not deleted while
  /// an environment still uses it.
  TextColumn get definitionId =>
      text().references(EnvironmentDefinitionsTable, #id)();

  /// Its name.
  TextColumn get name => text()();

  /// Where it stands, as `EnvironmentStatus.wire`.
  TextColumn get status =>
      // ignore: recursive_getters
      text().check(status.isIn(PlatformStoredValues.environmentStatus))();

  /// An `EnvironmentPlacement` name: `host` or `rig`.
  TextColumn get placement => text()
      // ignore: recursive_getters
      .check(placement.isIn(PlatformStoredValues.environmentPlacement))
      .withDefault(const Constant('host'))();

  /// The environment rig, at rig placement. Cleared when the rig's session
  /// row is purged.
  TextColumn get rigId => text().nullable().references(
    RigSessionsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Port assignments, as a JSON object.
  TextColumn get portsJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(portsJson))
      .withDefault(const Constant('{}'))();

  /// Endpoints, as a JSON array.
  TextColumn get endpointsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(endpointsJson))
      .withDefault(const Constant('[]'))();

  /// Component states in start order, as a JSON array.
  TextColumn get componentsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(componentsJson))
      .withDefault(const Constant('[]'))();

  /// Chosen options, as a JSON object.
  TextColumn get optionsJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(optionsJson))
      .withDefault(const Constant('{}'))();

  /// Non-fatal notes, as a JSON array.
  TextColumn get warningsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(warningsJson))
      .withDefault(const Constant('[]'))();

  /// The last failure as a JSON object, or null.
  TextColumn get lastErrorJson =>
      // ignore: recursive_getters
      text().nullable().check(isJsonObject(lastErrorJson))();

  /// A change needs destroy and start.
  BoolColumn get needsRecreate =>
      boolean().withDefault(const Constant(false))();

  /// Who started it. No foreign key: users live in the global database.
  TextColumn get createdBy => text()();

  /// When it was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When it last saw activity.
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  String get tableName => 'space_environments';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {spaceId, definitionId},
  ];
}
