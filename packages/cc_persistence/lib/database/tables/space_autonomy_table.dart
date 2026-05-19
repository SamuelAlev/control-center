import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Graduated per-space agent autonomy (PRD 16 §12): each agent's autonomy
/// is a first-class, adjustable per-space control — `proposeOnly` /
/// `actWithApproval` / `actFreely` — enforced at the harness's fail-closed
/// approval gate.
@TableIndex(name: 'idx_space_autonomy_workspaceId', columns: {#workspaceId})
class SpaceAutonomyTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The space this dial applies to.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// The agent the dial applies to.
  TextColumn get agentId => text()();

  /// `proposeOnly` | `actWithApproval` | `actFreely`.
  TextColumn get autonomyLevel => text()();

  /// Last change time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'space_autonomy';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, spaceId, agentId},
  ];
}
