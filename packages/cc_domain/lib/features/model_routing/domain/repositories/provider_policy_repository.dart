import 'package:cc_domain/features/model_routing/domain/entities/provider_policy.dart';
import 'package:cc_domain/features/model_routing/domain/services/provider_policy_engine.dart';

/// A persisted provider-policy statement with its stable id, so the UI can edit
/// and delete individual rules.
class WorkspaceProviderPolicy {
  /// Creates a [WorkspaceProviderPolicy].
  const WorkspaceProviderPolicy({required this.id, required this.statement});

  /// Stable row id.
  final String id;

  /// The allow/deny statement.
  final PolicyStatement statement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceProviderPolicy &&
          id == other.id &&
          statement == other.statement;

  @override
  int get hashCode => Object.hash(id, statement);
}

/// Workspace-scoped store of provider-governance policy (PRD 05, feature #11).
///
/// All reads filter by `workspaceId` (workspace isolation invariant). The
/// catalog's `finalize` consumes [engineFor] to drop denied providers.
abstract interface class ProviderPolicyRepository {
  /// Lists the policy statements for a workspace.
  Future<List<WorkspaceProviderPolicy>> listForWorkspace(String workspaceId);

  /// Watches the policy statements for a workspace.
  Stream<List<WorkspaceProviderPolicy>> watchForWorkspace(String workspaceId);

  /// Inserts or updates a statement (by [id]) in a workspace.
  Future<void> upsert(String workspaceId, String id, PolicyStatement statement);

  /// Deletes a statement by [id], scoped to [workspaceId].
  Future<void> delete(String workspaceId, String id);

  /// Builds a policy engine from a workspace's stored statements.
  Future<ProviderPolicyEngine> engineFor(String workspaceId);
}
