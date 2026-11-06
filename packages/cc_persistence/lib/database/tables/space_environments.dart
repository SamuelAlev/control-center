import 'package:drift/drift.dart';

/// Drift table of the environments spaces own.
///
/// **Workspace-scoped**, with no `workspace_id` column: the database file is
/// the scope. A space runs at most one environment per definition. Fields the
/// server filters on are typed; the rest is JSON written from the entity's wire
/// forms.
class SpaceEnvironmentsTable extends Table {
  /// Environment id, a UUID.
  TextColumn get id => text()();

  /// Owning space.
  TextColumn get spaceId => text()();

  /// The definition it was started from.
  TextColumn get definitionId => text()();

  /// Its name.
  TextColumn get name => text()();

  /// Where it stands, as `EnvironmentStatus.wire`.
  TextColumn get status => text()();

  /// `host` or `rig`.
  TextColumn get placement => text().withDefault(const Constant('host'))();

  /// The environment rig, at rig placement.
  TextColumn get rigId => text().nullable()();

  /// Port assignments, as a JSON object.
  TextColumn get portsJson => text().withDefault(const Constant('{}'))();

  /// Endpoints, as a JSON array.
  TextColumn get endpointsJson => text().withDefault(const Constant('[]'))();

  /// Component states in start order, as a JSON array.
  TextColumn get componentsJson => text().withDefault(const Constant('[]'))();

  /// Chosen options, as a JSON object.
  TextColumn get optionsJson => text().withDefault(const Constant('{}'))();

  /// Non-fatal notes, as a JSON array.
  TextColumn get warningsJson => text().withDefault(const Constant('[]'))();

  /// The last failure as a JSON object, or null.
  TextColumn get lastErrorJson => text().nullable()();

  /// A change needs destroy and start.
  BoolColumn get needsRecreate =>
      boolean().withDefault(const Constant(false))();

  /// Who started it.
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
