import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:drift/drift.dart';

/// Why a node of an executing plan left its declared scope, and whether its
/// step is held until someone continues it. Goes with its orchestration.
class PlanDivergencesTable extends Table {
  @override
  String get tableName => 'plan_divergences';

  /// The orchestration executing the plan.
  TextColumn get orchestrationId => text().references(
    OrchestrationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The plan node.
  TextColumn get nodeKey => text()();

  /// What diverged, as a JSON array of strings.
  // ignore: recursive_getters
  TextColumn get reasons => text().check(isJsonArray(reasons))();

  /// Whether the node's step is held.
  BoolColumn get held => boolean()();

  /// When it was found.
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {orchestrationId, nodeKey};
}
