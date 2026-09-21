import 'package:drift/drift.dart';

/// Per-workspace approval routing policy (never age-pruned — unlike `caches`).
///
/// [policyJson] is `ApprovalRoutingPolicy` wire JSON; domain owns the schema.
class ApprovalRoutingPoliciesTable extends Table {
  @override
  String get tableName => 'approval_routing_policies';

  /// The owning workspace (one policy per workspace file).
  TextColumn get workspaceId => text()();

  /// The `ApprovalRoutingPolicy` JSON.
  TextColumn get policyJson => text()();

  /// When the policy was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {workspaceId};
}
