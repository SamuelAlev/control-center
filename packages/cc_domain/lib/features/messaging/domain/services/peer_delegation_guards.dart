import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';

export 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart'
    show AutonomyLevel;

/// The outcome of a guard check — allowed, or denied with a reason that reaches
/// the agent verbatim (never a silent no-op).
class GuardResult {
  /// A pass.
  const GuardResult.allow() : allowed = true, refusal = null;

  /// A denial carrying the human/agent-facing [refusal] reason.
  const GuardResult.deny(this.refusal) : allowed = false;

  /// Whether the action is permitted.
  final bool allowed;

  /// The refusal reason when [allowed] is false.
  final String? refusal;
}

/// The deterministic, server-side delegation/peer-messaging guards (PRD 22 §3).
///
/// Every guard is enforced at a chokepoint — never by prompt instruction
/// ("please don't loop" is not a guard). Pure and injectable so the chokepoint
/// can evaluate a request and refuse loudly with the named reason.
class DelegationGuards {
  /// Creates [DelegationGuards].
  const DelegationGuards({this.maxDepth = 3});

  /// The maximum delegation-chain depth (default 3).
  final int maxDepth;

  /// Refuses a hop that would push the chain past [maxDepth]. [currentDepth] is
  /// the delegator's own chain depth; the new delegate would be at
  /// `currentDepth + 1`.
  GuardResult checkDepth(int currentDepth) {
    final next = currentDepth + 1;
    if (next > maxDepth) {
      return GuardResult.deny(
        'Delegation refused: chain depth $next exceeds the cap of $maxDepth.',
      );
    }
    return const GuardResult.allow();
  }

  /// Refuses a hop that would form a cycle (A→B→…→A). [chainAgentIds] is the
  /// ordered set of agents already in the chain (delegator last); [targetId] is
  /// the proposed delegate.
  GuardResult checkCycle(List<String> chainAgentIds, String targetId) {
    if (chainAgentIds.contains(targetId)) {
      final named = [...chainAgentIds, targetId].join(' → ');
      return GuardResult.deny('Delegation refused: cycle detected ($named).');
    }
    return const GuardResult.allow();
  }

  /// Refuses when the delegate would act with more autonomy than the delegator.
  GuardResult checkAutonomyCeiling(
    AutonomyLevel delegator,
    AutonomyLevel requested,
  ) {
    if (!requested.atMost(delegator)) {
      return GuardResult.deny(
        'Delegation refused: a delegate cannot run "${requested.wire}" above '
        'the delegator ceiling "${delegator.wire}".',
      );
    }
    return const GuardResult.allow();
  }

  /// Refuses when the delegator's inherited budget envelope is exhausted —
  /// delegation bills the *delegator's* remaining budget and cannot mint more
  /// (governance hard-stops apply transitively).
  GuardResult checkBudgetEnvelope(int remainingCents) {
    if (remainingCents <= 0) {
      return const GuardResult.deny(
        "Delegation refused: the delegator's budget envelope is exhausted "
        '(delegation cannot mint budget).',
      );
    }
    return const GuardResult.allow();
  }

  /// Evaluates every guard for a delegation/ask hop in one call (the chokepoint
  /// entry point), returning the first failure or allow. [chainAgentIds] must
  /// include the delegator (last) so the combined ask+delegate chain is checked
  /// as one (PRD 22 Clarifications: one chain-id threads both).
  GuardResult evaluate({
    required List<String> chainAgentIds,
    required int chainDepth,
    required String targetAgentId,
    required AutonomyLevel delegatorAutonomy,
    required AutonomyLevel requestedAutonomy,
    required int remainingBudgetCents,
  }) {
    final depth = checkDepth(chainDepth);
    if (!depth.allowed) {
      return depth;
    }
    final cycle = checkCycle(chainAgentIds, targetAgentId);
    if (!cycle.allowed) {
      return cycle;
    }
    final autonomy = checkAutonomyCeiling(delegatorAutonomy, requestedAutonomy);
    if (!autonomy.allowed) {
      return autonomy;
    }
    return checkBudgetEnvelope(remainingBudgetCents);
  }
}

/// A pure sliding-window rate limiter per ordered agent pair (PRD 22 §3) — kills
/// ping-pong storms deterministically. Stateful but injectable-clock, so it is
/// testable. Keyed by `from|to` so A→B and B→A are limited independently.
class PairRateLimiter {
  /// Creates a [PairRateLimiter].
  PairRateLimiter({
    this.maxPerWindow = 10,
    this.window = const Duration(minutes: 1),
  });

  /// Maximum messages per [window] for one ordered pair.
  final int maxPerWindow;

  /// The sliding window duration.
  final Duration window;

  final Map<String, List<DateTime>> _events = {};

  /// Records an attempt from [from] to [to] at [now]; returns whether it is
  /// within the cap (false ⇒ rate-limited, surfaced with a visible notice).
  bool tryAcquire(String from, String to, DateTime now) {
    final key = '$from|$to';
    final list = _events.putIfAbsent(key, () => <DateTime>[]);
    list.removeWhere((t) => now.difference(t) > window);
    if (list.length >= maxPerWindow) {
      return false;
    }
    list.add(now);
    return true;
  }

  /// Clears all state (e.g. workspace reset / test teardown).
  void reset() => _events.clear();
}
