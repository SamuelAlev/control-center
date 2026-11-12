import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Graduated per-space agent autonomy (PRD 16 §12): each agent's autonomy
/// is a first-class, adjustable per-space control — `proposeOnly` /
/// `actWithApproval` / `actFreely` — enforced at the harness's fail-closed
/// approval gate.
///
/// One dial per agent per space: `(space_id, agent_id)` is unique and the
/// write is one `INSERT … ON CONFLICT` on it.
@TableIndex(name: 'idx_space_autonomy_agentId', columns: {#agentId})
class SpaceAutonomyTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The space this dial applies to.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// The agent the dial applies to. `ON DELETE CASCADE`: a dial for an agent
  /// that no longer exists governs nothing.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// `proposeOnly` | `actWithApproval` | `actFreely` (`AutonomyLevel.wire`).
  TextColumn get autonomyLevel => text().check(
    // ignore: recursive_getters
    autonomyLevel.isIn(SpacesStoredValues.autonomyLevel),
  )();

  /// Last change time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'space_autonomy';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {spaceId, agentId},
  ];
}
