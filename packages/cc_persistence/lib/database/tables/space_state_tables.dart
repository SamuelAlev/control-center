import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// The take-over standing on a space: a person holds its worktree and no
/// agent run is dispatched into it until they hand it back.
///
/// One row per space at most (the key is the space), so claiming a take-over
/// is one conditional insert. The row is the dispatch gate and lives until it
/// is handed back; it goes with its space.
class SpaceTakeoversTable extends Table {
  @override
  String get tableName => 'space_takeovers';

  /// The space taken over.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// Who holds it. No foreign key: users live in the global database.
  TextColumn get userId => text()();

  /// The holder's name as shown when it started.
  TextColumn get displayName => text()();

  /// When it started.
  DateTimeColumn get since => dateTime()();

  /// Run ids paused at a turn boundary, as a JSON array; resumed on hand-back.
  TextColumn get pausedRunIds => text()
      // ignore: recursive_getters
      .check(isJsonArray(pausedRunIds))
      .withDefault(const Constant('[]'))();

  /// Run ids stopped because they had no safe turn boundary, as a JSON array.
  TextColumn get stoppedRunIds => text()
      // ignore: recursive_getters
      .check(isJsonArray(stoppedRunIds))
      .withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {spaceId};
}

/// The checker agent a space names: it reviews every other agent's finished
/// main run there. A setting, kept until someone changes it; it goes with its
/// space.
@TableIndex(name: 'idx_space_checkers_agent', columns: {#agentId})
class SpaceCheckersTable extends Table {
  @override
  String get tableName => 'space_checkers';

  /// The space.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// The checker agent; the setting goes with it.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// When it was named.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {spaceId};
}
