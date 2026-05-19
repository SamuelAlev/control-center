import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';

/// Persistence port for the per-workspace [ApprovalRoutingPolicy].
///
/// The policy is durable security configuration — who an approval gate asks
/// and how it escalates — so it lives in its own table, never in a
/// staleness-pruned cache (it used to be a `caches` row and the retention
/// sweep silently deleted it after 21 quiet days, reverting the workspace to
/// the built-in defaults).
abstract interface class ApprovalRoutingPolicyRepository {
  /// The stored policy for [workspaceId], or null when never configured
  /// (callers fall back to [ApprovalRoutingPolicy.defaults]).
  Future<ApprovalRoutingPolicy?> get(String workspaceId);

  /// Persists [policy] as [workspaceId]'s routing policy.
  Future<void> set(String workspaceId, ApprovalRoutingPolicy policy);
}
