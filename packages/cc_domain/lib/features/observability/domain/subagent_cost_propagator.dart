import 'dart:async';

/// Serializes subagent-cost roll-ups onto a parent run so concurrent
/// propagations to the **same** parent never lose a read-modify-write update.
///
/// When a subagent finishes, its cost rolls up to the parent run's
/// `childCostCents` field. The roll-up is a read-modify-write: read the parent's
/// current child cost, add the delta, write it back. If two subagents of the
/// same parent finish at the same time, a naive `read; add; write` interleaves
/// (both read the same base, both write base + their own delta) and one delta is
/// lost. This propagator wraps each parent run in a per-key
/// [Future]-chain lock so updates to one parent are applied strictly serially,
/// while different parents proceed concurrently.
///
/// The store itself is injected via the [readChildCostCents] /
/// [writeChildCostCents] hooks so this class stays pure-domain (no database
/// dependency). Each acquire chains onto the previous tail [Future] for the key, swallows that
/// tail's errors so one failed link never wedges the chain, and removes the map
/// entry once it is the last link in the chain.
class SubagentCostPropagator {
  /// Creates a [SubagentCostPropagator] backed by the given store hooks.
  ///
  /// * [readChildCostCents] returns the parent run's current accumulated child
  ///   cost in US cents.
  /// * [writeChildCostCents] persists the new accumulated child cost in US cents.
  SubagentCostPropagator({
    required this.readChildCostCents,
    required this.writeChildCostCents,
  });

  /// Reads the parent run's current accumulated child cost, in US cents.
  final Future<int> Function(String parentRunId) readChildCostCents;

  /// Writes the parent run's new accumulated child cost, in US cents.
  final Future<void> Function(String parentRunId, int newChildCostCents)
  writeChildCostCents;

  /// Per-parent-key tail of the in-flight propagation chain.
  ///
  /// The value is the [Future] of the most recently enqueued propagation for
  /// that key; the next propagation chains onto it. The entry is deleted once
  /// the chain for that key drains, so idle keys hold no memory.
  final Map<String, Future<void>> _locks = <String, Future<void>>{};

  /// Adds [amountCents] to the parent run's accumulated child cost, serialized
  /// against any other propagation for the same [parentRunId].
  ///
  /// A non-positive [amountCents] is a no-op (subagents only ever add cost).
  /// Concurrent calls for the **same** [parentRunId] run strictly one after the
  /// other — each reads the value the previous call wrote — so no update is
  /// lost. Calls for **different** parent keys do not block each other.
  ///
  /// The returned [Future] completes when this call's read-modify-write has been
  /// applied. A failing read or write rejects this call's [Future] but does not
  /// wedge the chain: the next propagation for the same key still runs.
  Future<void> propagate(String parentRunId, int amountCents) {
    if (amountCents <= 0) {
      return Future<void>.value();
    }

    // Chain onto the previous tail for this key (or a resolved future if this is
    // the head). The previous tail is the error-swallowed `gate` (see below), so
    // one link's failure never wedges later links on the same key.
    final Future<void> previous = _locks[parentRunId] ?? Future<void>.value();
    final Future<void> work = previous.then(
      (_) => _applyDelta(parentRunId, amountCents),
    );

    // The gate stored as the new tail swallows this link's error so the next
    // propagation that chains onto it is not poisoned by an earlier failure.
    // It is also where cleanup hangs, so no derived future ever leaks the error.
    final Future<void> gate = work.then((_) {}, onError: (Object _) {});
    _locks[parentRunId] = gate;

    // When this link settles, remove the map entry — but only if `gate` is still
    // the tail (no later propagation has chained on in the meantime). This keeps
    // the map free of drained chains without dropping a live one.
    gate.whenComplete(() {
      if (identical(_locks[parentRunId], gate)) {
        _locks.remove(parentRunId);
      }
    });

    // The caller gets the real work future, so a failed read/write rejects this
    // call's Future (while the swallowed `gate` keeps the chain alive).
    return work;
  }

  /// Performs one read-modify-write of the parent run's child cost.
  Future<void> _applyDelta(String parentRunId, int amountCents) async {
    final int current = await readChildCostCents(parentRunId);
    await writeChildCostCents(parentRunId, current + amountCents);
  }
}
