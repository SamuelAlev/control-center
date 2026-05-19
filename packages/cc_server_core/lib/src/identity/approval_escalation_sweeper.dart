import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_routing_policy_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_routing_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';

/// Escalates unanswered approval gates along the workspace routing policy.
///
/// With N members, a gate must know who to ask — and must not rot when that
/// person is away. This sweeper periodically walks every workspace's pending
/// approvals, derives the current escalation tier from the approval's age and
/// the workspace [ApprovalRoutingPolicy] and on a tier change:
///
///  * records WHO the new tier routes to as an audited system action (the
///    tier number alone does not answer "why am I being asked?") and
///  * appends a system comment to the approval so the escalation is visible
///    and attributable in the thread.
///
/// First-decision-wins is untouched — the workflow service already enforces
/// the single pending→decided transition with attribution.
class ApprovalEscalationSweeper {
  /// Creates an [ApprovalEscalationSweeper].
  ApprovalEscalationSweeper({
    required ApprovalRepository approvals,
    required WorkspaceRepository workspaces,
    required WorkspaceMembershipRepository members,
    required CacheRepository cache,
    required ApprovalRoutingPolicyRepository policies,
    required ApprovalWorkflowService workflow,
    DomainEventBus? eventBus,
    this.interval = const Duration(minutes: 5),
    DateTime Function()? now,
    void Function(String message)? onError,
  }) : _approvals = approvals,
       _workspaces = workspaces,
       _members = members,
       _cache = cache,
       _policies = policies,
       _workflow = workflow,
       _activity = ActivityLogger(eventBus: eventBus),
       _now = now ?? DateTime.now,
       _onError = onError;

  /// Cache kind holding per-approval sweep STATE (escalation tiers). The
  /// POLICY no longer lives here: `caches` rows are pruned by `updatedAt`
  /// age, so a policy configured once and not edited for the retention
  /// window was silently deleted and the workspace reverted to defaults.
  /// Tier state is genuinely staleness-bounded (a pruned row costs at most
  /// one duplicate escalation comment), so it stays.
  static const cacheKind = 'approval_routing';

  /// Legacy cache key the policy JSON used to live under — still read once
  /// per workspace as a migrate-on-read fallback so an already-configured
  /// install keeps its policy across the upgrade.
  static const policyKey = 'policy';

  final ApprovalRepository _approvals;
  final WorkspaceRepository _workspaces;
  final WorkspaceMembershipRepository _members;
  final CacheRepository _cache;
  final ApprovalRoutingPolicyRepository _policies;
  final ApprovalWorkflowService _workflow;
  final ActivityLogger _activity;
  final DateTime Function() _now;
  final void Function(String message)? _onError;
  static const _routing = ApprovalRoutingService();

  /// Sweep cadence.
  final Duration interval;

  Timer? _timer;

  /// Starts the periodic sweep (first pass on the next event-loop tick).
  void start() {
    _timer?.cancel();
    unawaited(Future<void>.microtask(runOnce));
    _timer = Timer.periodic(interval, (_) => unawaited(runOnce()));
  }

  /// Stops the periodic sweep.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Loads [workspaceId]'s routing policy (defaults when unset/malformed).
  ///
  /// Reads the durable store first; on a miss, falls back ONCE to the legacy
  /// `caches` row and migrates it forward, so an install configured before
  /// the durable table existed keeps its policy (unless the retention sweep
  /// already ate the row — the bug that forced this move).
  Future<ApprovalRoutingPolicy> policyFor(String workspaceId) async {
    try {
      final stored = await _policies.get(workspaceId);
      if (stored != null) {
        return stored;
      }
      final raw = await _cache.read(workspaceId, cacheKind, policyKey);
      if (raw == null) {
        return ApprovalRoutingPolicy.defaults;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return ApprovalRoutingPolicy.defaults;
      }
      final legacy = ApprovalRoutingPolicy.fromJson(decoded);
      await _policies.set(workspaceId, legacy);
      return legacy;
    } catch (_) {
      return ApprovalRoutingPolicy.defaults;
    }
  }

  /// Persists [workspaceId]'s routing policy (durable, never age-pruned).
  Future<void> setPolicy(String workspaceId, ApprovalRoutingPolicy policy) =>
      _policies.set(workspaceId, policy);

  /// Runs one escalation pass across every workspace. Returns how many
  /// approvals escalated. Never throws — failures are reported per workspace
  /// and retried on the next tick.
  Future<int> runOnce() async {
    var escalated = 0;
    final List<Workspace> workspaces;
    try {
      workspaces = await _workspaces.watchAll().first;
    } catch (e) {
      _onError?.call('approval escalation sweep failed to list workspaces: $e');
      return 0;
    }
    for (final workspace in workspaces) {
      if (workspace.isDeleted) {
        continue;
      }
      try {
        escalated += await _sweepWorkspace(workspace.id);
      } catch (e) {
        _onError?.call(
          'approval escalation sweep failed for ${workspace.id}: $e',
        );
      }
    }
    return escalated;
  }

  Future<int> _sweepWorkspace(String workspaceId) async {
    final pending = await _approvals
        .watchByStatus(workspaceId, 'pending')
        .first;
    if (pending.isEmpty) {
      return 0;
    }
    final policy = await policyFor(workspaceId);
    final members = await _members.getForWorkspace(workspaceId);
    final now = _now();
    var escalated = 0;
    for (final approval in pending) {
      final tier = _routing.tierFor(
        createdAt: approval.createdAt,
        now: now,
        policy: policy,
      );
      if (tier == 0) {
        continue;
      }
      final stateKey = 'tier_${approval.id}';
      final lastRaw = await _cache.read(workspaceId, cacheKind, stateKey);
      final last = int.tryParse(lastRaw ?? '') ?? 0;
      if (tier <= last) {
        continue;
      }
      final targets = _routing.targetsFor(
        approval: approval,
        policy: policy,
        members: members,
        tier: tier,
        requestingUserId: approval.requestedByActorType == 'user'
            ? approval.requestedById
            : null,
      );
      await _workflow.comment(
        approval.id,
        workspaceId: workspaceId,
        authorType: 'system',
        body:
            'Unanswered for ${policy.escalationTimeout.inMinutes * tier} '
            'minutes — escalated to tier $tier '
            '(${tier == 1 ? 'admins' : 'owner'}).',
      );
      // After the comment, never before it: a failed comment aborts the sweep
      // and the tier is retried next tick, so an audit line written first
      // would claim an escalation that did not land — and would duplicate.
      _activity.logSystemAction(
        action: 'escalated',
        entityType: 'approval',
        entityId: approval.id,
        details: targets.isEmpty
            ? 'tier $tier (nobody matched the tier)'
            : 'tier $tier → ${targets.join(', ')}',
        workspaceId: workspaceId,
      );
      await _cache.put(workspaceId, cacheKind, stateKey, '$tier');
      escalated++;
    }
    return escalated;
  }
}
