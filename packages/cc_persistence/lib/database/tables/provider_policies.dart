import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_provider_policies_created', columns: {#createdAt})
/// Drift table for per-workspace provider-governance policy (PRD 05).
///
/// Each row is one allow/deny statement (`action` × `resource` globs) that the
/// model catalog's `finalize` consults to remove denied providers, making them
/// unselectable. Workspace-scoped: every read filters by [workspaceId].
class ProviderPoliciesTable extends Table {
  /// Unique statement id.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Action glob (e.g. `provider.use`).
  TextColumn get action => text().withDefault(const Constant('provider.use'))();

  /// Resource glob (e.g. `anthropic`, `*-cn`, `*`).
  TextColumn get resource => text()();

  /// Effect: `allow` or `deny`.
  TextColumn get effect => text().check(
    // ignore: recursive_getters
    effect.isIn(AgentsStoredValues.policyEffect),
  )();

  /// Policy layer (`global` | `user` | `workspace`); stored rows are workspace.
  TextColumn get layer => text()
      // ignore: recursive_getters
      .check(layer.isIn(AgentsStoredValues.policyLayer))
      .withDefault(const Constant('workspace'))();

  /// When the statement was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the statement was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'provider_policies';

  @override
  Set<Column> get primaryKey => {id};
}
