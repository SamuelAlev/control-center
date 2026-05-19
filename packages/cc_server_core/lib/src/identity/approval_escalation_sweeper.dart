import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/approval_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_routing_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';

/// Escalates unanswered approval gates along the workspace routing policy.
///
/// With N members, a gate must know who to ask — and must not rot when that
/// person is away. This sweeper periodically walks every workspace's pending
/// approvals, derives the current escalation tier from the approval's age and
/// the workspace [ApprovalRoutingPolicy], and on a tier change:
///
///  * publishes [ApprovalEscalated] carrying the users now responsible (so
///    notifications route to them, not to everyone), and
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
    required ApprovalWorkflowService workflow,
    DomainEventBus? eventBus,
    this.interval = const Duration(minutes: 5),
    DateTime Function()? now,
    void Function(String message)? onError,
  }) : _approvals = approvals,
       _workspaces = workspaces,
       _members = members,
       _cache = cache,
       _workflow = workflow,
       _eventBus = eventBus,
       _now = now ?? DateTime.now,
       _onError = onError;

  /// Cache kind holding the per-workspace routing policy + sweep state.
  static const cacheKind = 'approval_routing';

  /// Cache key of the workspace policy JSON.
  static const policyKey = 'policy';

  final ApprovalRepository _approvals;
  final WorkspaceRepository _workspaces;
  final WorkspaceMembershipRepository _members;
  final CacheRepository _cache;
  final ApprovalWorkflowService _workflow;
  final DomainEventBus? _eventBus;
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
  Future<ApprovalRoutingPolicy> policyFor(String workspaceId) async {
    try {
      final raw = await _cache.read(workspaceId, cacheKind, policyKey);
      if (raw == null) {
        return ApprovalRoutingPolicy.defaults;
      }
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? ApprovalRoutingPolicy.fromJson(decoded)
          : ApprovalRoutingPolicy.defaults;
    } catch (_) {
      return ApprovalRoutingPolicy.defaults;
    }
  }

  /// Persists [workspaceId]'s routing policy.
  Future<void> setPolicy(String workspaceId, ApprovalRoutingPolicy policy) =>
      _cache.put(
        workspaceId,
        cacheKind,
        policyKey,
        jsonEncode(policy.toJson()),
      );

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
      _eventBus?.publish(
        ApprovalEscalated(
          workspaceId: workspaceId,
          approvalId: approval.id,
          tier: tier,
          targetUserIds: targets,
          occurredAt: now,
        ),
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
      await _cache.put(workspaceId, cacheKind, stateKey, '$tier');
      escalated++;
    }
    return escalated;
  }
}
