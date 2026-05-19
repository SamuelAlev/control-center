import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';

/// Pure routing logic for approval gates with N human members.
///
/// Tiers, in order: the policy's primary audience → every admin/owner → the
/// owner alone. [tierFor] derives the current tier from the approval's age;
/// [targetsFor] resolves the user ids asked at that tier. An empty tier
/// (e.g. an unknown requesting user) falls through to the next, so a gate is
/// never addressed to nobody. Decisions stay first-wins with attribution —
/// the workflow service enforces the single pending→decided transition.
class ApprovalRoutingService {
  /// Creates an [ApprovalRoutingService].
  const ApprovalRoutingService();

  /// How many tiers exist (primary, admins, owner).
  static const tierCount = 3;

  /// The escalation tier for an approval created at [createdAt], evaluated at
  /// [now]: 0 before the timeout elapses, then one tier per elapsed timeout,
  /// capped at the last tier.
  int tierFor({
    required DateTime createdAt,
    required DateTime now,
    required ApprovalRoutingPolicy policy,
  }) {
    final timeout = policy.escalationTimeout;
    if (timeout.inMicroseconds <= 0) {
      return 0;
    }
    final elapsed = now.difference(createdAt);
    if (elapsed.isNegative) {
      return 0;
    }
    final tier = elapsed.inMicroseconds ~/ timeout.inMicroseconds;
    return tier >= tierCount ? tierCount - 1 : tier;
  }

  /// The user ids asked to decide [approval] at [tier], given the workspace's
  /// [members] and [policy]. [requestingUserId] is the human whose action
  /// triggered the gated work (null when agent-initiated with no human in
  /// context).
  List<String> targetsFor({
    required Approval approval,
    required ApprovalRoutingPolicy policy,
    required List<WorkspaceMember> members,
    required int tier,
    String? requestingUserId,
  }) => targetsForTier(
    policy: policy,
    members: members,
    tier: tier,
    requestingUserId: requestingUserId,
  );

  /// The user ids asked to decide at [tier], independent of WHAT is being
  /// decided.
  ///
  /// The durable approval board and the ephemeral agent-action confirmations
  /// are different objects with different lifetimes, but "who should be asked,
  /// and who does it escalate to" is the same question — so they share this
  /// one implementation rather than growing a second routing policy nobody
  /// keeps in sync.
  List<String> targetsForTier({
    required ApprovalRoutingPolicy policy,
    required List<WorkspaceMember> members,
    required int tier,
    String? requestingUserId,
  }) {
    final admins = [
      for (final m in members)
        if (m.role.isAdmin) m.userId,
    ];
    final owners = [
      for (final m in members)
        if (m.role == WorkspaceRole.owner) m.userId,
    ];

    List<String> primary() => switch (policy.mode) {
      ApprovalRoutingMode.requestingUser => [
        if (requestingUserId != null &&
            members.any((m) => m.userId == requestingUserId))
          requestingUserId,
      ],
      ApprovalRoutingMode.anyAdmin => admins,
      ApprovalRoutingMode.owner => owners,
    };

    // Walk from the requested tier down the chain until one is non-empty.
    for (var t = tier; t < tierCount; t++) {
      final targets = switch (t) {
        0 => primary(),
        1 => admins,
        _ => owners,
      };
      if (targets.isNotEmpty) {
        return targets;
      }
    }
    // A workspace always has an owner membership (the bootstrap guarantees
    // it); admins ⊇ owner makes this unreachable in practice.
    return owners;
  }
}
