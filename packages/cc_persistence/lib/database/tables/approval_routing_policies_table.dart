import 'package:drift/drift.dart';

/// The per-workspace approval ROUTING policy (who an approval gate asks, and
/// how it escalates when unanswered) — one row per workspace.
///
/// This used to live in the generic `caches` table (`cacheKind:
/// 'approval_routing'`, key `'policy'`), which `DatabaseRetentionService`
/// prunes by `updatedAt` age — so a policy configured once and not edited for
/// the retention window was silently DELETED and the workspace reverted to
/// the built-in defaults. A security control that garbage-collects itself is
/// exactly the failure mode the `workspace_settings` doc warns about; the
/// policy now has a durable, never-pruned home. The sweeper's per-approval
/// tier STATE stays in `caches` on purpose: it is genuinely staleness-bounded
/// (a pruned tier row costs at most one duplicate escalation comment, and
/// decided approvals' rows should die on the timer).
///
/// [policyJson] is the `ApprovalRoutingPolicy` wire JSON — the domain value
/// object owns the schema, so extending the policy (per-class routing, the
/// durable-approval threshold) is a JSON evolution, not a migration.
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
