/// An ordered set of credentials some scope may run on, plus how to choose
/// between them — the provider-agnostic half of multi-account support.
///
/// One vocabulary, two mechanisms, because the transports fail over in
/// fundamentally different places and no amount of abstraction merges them:
///
///  * The **harness** owns the LLM call, so `FallbackProvider` swaps credential
///    mid-stream on a capacity error and the turn never restarts.
///  * The **`claude-code` adapter** spawns a CLI that owns its own credential,
///    so the account can only be chosen BEFORE the spawn; failing over means
///    re-running the turn.
///
/// What this file holds is the part they genuinely share: which credentials a
/// scope may use, in what order, and the rule for picking one. The ids are
/// opaque — Claude Code account ids in one lane, harness `credentialId`s in the
/// other.
library;

/// How an [AccountPool] picks which of its accounts a run signs in as.
enum AccountRotationStrategy {
  /// Always the first account in the pool. The degenerate case, and the
  /// default: one account attached behaves exactly as it did before pools
  /// existed.
  pinned('pinned'),

  /// Spread runs across the pool, advancing one step per dispatch.
  ///
  /// Use when the accounts are interchangeable and the goal is to keep any one
  /// plan from being the bottleneck. It does NOT look at usage — it is a fair
  /// share, not a load balancer, and an account that is already spent is still
  /// skipped by the headroom check every strategy applies.
  roundRobin('round_robin'),

  /// Drain accounts in order: stay on the first until it has no headroom, then
  /// the second, and so on.
  ///
  /// Use when the accounts are NOT interchangeable — a personal plan you would
  /// rather exhaust before touching the org's, say. The cost is that the
  /// account in front absorbs every run, so its window resets slowest.
  serial('serial');

  const AccountRotationStrategy(this.wire);

  /// Stable persisted/RPC spelling. Never the enum name — renaming a Dart
  /// symbol must not silently re-point every workspace's stored pool.
  final String wire;

  /// Parses [raw], defaulting to [pinned] for anything unrecognized.
  static AccountRotationStrategy fromWire(String? raw) {
    for (final s in values) {
      if (s.wire == raw) {
        return s;
      }
    }
    return pinned;
  }
}

/// An ordered set of Claude Code accounts a workspace (or one agent) may run
/// on, plus how to choose between them.
///
/// Empty means "not configured" — the caller falls back to the next scope out,
/// and ultimately to the server's default account. That is what keeps an
/// install that never opens this screen behaving exactly as before.
class AccountPool {
  /// Creates a [AccountPool].
  const AccountPool({
    this.accountIds = const [],
    this.strategy = AccountRotationStrategy.pinned,
  });

  /// Reads the persisted/RPC shape.
  factory AccountPool.fromJson(Map<String, dynamic> json) {
    final ids = json['account_ids'];
    return AccountPool(
      accountIds: [
        for (final id in ids is List ? ids : const [])
          if (id is String && id.isNotEmpty) id,
      ],
      strategy: AccountRotationStrategy.fromWire(json['strategy'] as String?),
    );
  }

  /// The attached accounts, in the order [AccountRotationStrategy.serial] drains
  /// them and [AccountRotationStrategy.roundRobin] cycles them.
  final List<String> accountIds;

  /// How to choose among [accountIds].
  final AccountRotationStrategy strategy;

  /// Whether this scope has anything to say.
  bool get isEmpty => accountIds.isEmpty;

  /// The persisted/RPC shape.
  Map<String, dynamic> toJson() => {
    'account_ids': accountIds,
    'strategy': strategy.wire,
  };

  /// Returns a copy with the given overrides.
  AccountPool copyWith({
    List<String>? accountIds,
    AccountRotationStrategy? strategy,
  }) => AccountPool(
    accountIds: accountIds ?? this.accountIds,
    strategy: strategy ?? this.strategy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountPool &&
          runtimeType == other.runtimeType &&
          strategy == other.strategy &&
          _listEquals(accountIds, other.accountIds);

  @override
  int get hashCode => Object.hash(strategy, Object.hashAll(accountIds));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// What the selector knows about one candidate account at dispatch time.
///
/// Deliberately not `ClaudeAccount`: the selector is pure and needs only the
/// four facts that decide the choice, so it can be exercised without a
/// filesystem, a keychain or a usage endpoint.
class AccountAvailability {
  /// Creates a [AccountAvailability].
  const AccountAvailability({
    required this.id,
    required this.signedIn,
    this.spent = false,
    this.availableAt,
  });

  /// The account id.
  final String id;

  /// Whether the account has a usable credential. A signed-out account is never
  /// chosen — running on it burns a turn to print "please run /login".
  final bool signedIn;

  /// Whether its plan windows are used up, or it is cooling off after a real
  /// rate-limit response.
  final bool spent;

  /// When [spent] is expected to clear (the window's reset, or the end of a
  /// cooldown). Null when unknown — an account with no reset time simply
  /// cannot contribute one to the refusal message.
  final DateTime? availableAt;
}

/// The outcome of choosing an account for one dispatch.
///
/// A sealed pair rather than a nullable id: "no account" has two very different
/// causes — nothing is attached (fall back to the server default) versus every
/// attached account is spent (refuse and say when one frees up) — and collapsing
/// them is how a rate-limited pool silently becomes "runs on whatever".
sealed class AccountChoice {
  const AccountChoice();
}

/// An account was chosen.
class AccountChosen extends AccountChoice {
  /// Creates a [AccountChosen].
  const AccountChosen({required this.accountId, required this.cursor});

  /// The account the run signs in as.
  final String accountId;

  /// The cursor to persist for the next dispatch. Meaningful only for
  /// [AccountRotationStrategy.roundRobin]; the others leave it unchanged.
  final int cursor;
}

/// The pool named accounts, but none can serve a run right now.
class AccountsAllSpent extends AccountChoice {
  /// Creates a [AccountsAllSpent].
  const AccountsAllSpent({required this.accountIds, this.earliestReset});

  /// The accounts that were considered, so the message can say how many.
  final List<String> accountIds;

  /// The soonest any of them frees up, when known.
  final DateTime? earliestReset;
}

/// The pool is not configured at this scope.
class AccountPoolUnset extends AccountChoice {
  /// Creates a [AccountPoolUnset].
  const AccountPoolUnset();
}

/// Chooses which account a dispatch runs on. Pure, so the rotation rules are
/// testable without a host.
// A namespace of pure functions — the rotation rules. Suppressed deliberately:
// giving it instance state is exactly what would make the rules untestable.
// ignore: avoid_classes_with_only_static_members
abstract final class AccountSelector {
  /// Picks an account from [pool] given each candidate's [availability] and the
  /// pool's persisted round-robin [cursor].
  ///
  /// Accounts named by the pool but no longer present in [availability] are
  /// skipped rather than failing the dispatch: a pool outlives the accounts
  /// listed in it, and refusing to run because a deleted id is still on the
  /// list would be a worse answer than using the ones that remain.
  static AccountChoice select({
    required AccountPool pool,
    required Map<String, AccountAvailability> availability,
    int cursor = 0,
  }) {
    final candidates = [
      for (final id in pool.accountIds)
        if (availability[id] != null) availability[id]!,
    ];
    if (candidates.isEmpty) {
      return const AccountPoolUnset();
    }
    final usable = [
      for (final c in candidates)
        if (c.signedIn && !c.spent) c,
    ];
    if (usable.isEmpty) {
      // A signed-OUT account is a configuration problem, not a quota one, and
      // it has no reset time to report — so the refusal is built only from the
      // accounts that are genuinely spent.
      final spent = [
        for (final c in candidates)
          if (c.signedIn && c.spent) c,
      ];
      DateTime? earliest;
      for (final c in spent) {
        final at = c.availableAt;
        if (at != null && (earliest == null || at.isBefore(earliest))) {
          earliest = at;
        }
      }
      return AccountsAllSpent(
        accountIds: [for (final c in candidates) c.id],
        earliestReset: earliest,
      );
    }

    switch (pool.strategy) {
      case AccountRotationStrategy.pinned:
      case AccountRotationStrategy.serial:
        // Both take the first usable account in the pool's own order. They
        // differ only in what the operator is promising: `pinned` says the
        // extras are standbys, `serial` says drain them in this order. The
        // headroom skip makes the mechanics identical, and saying so here is
        // cheaper than two code paths that must not drift.
        return AccountChosen(accountId: usable.first.id, cursor: cursor);
      case AccountRotationStrategy.roundRobin:
        // Advance over the FULL pool, not the usable subset, so a spent account
        // still consumes its turn in the cycle. Otherwise the remaining
        // accounts would silently re-balance and the rotation would stop being
        // reproducible from the cursor alone.
        final n = candidates.length;
        final start = n == 0 ? 0 : cursor % n;
        for (var step = 0; step < n; step++) {
          final index = (start + step) % n;
          final candidate = candidates[index];
          if (candidate.signedIn && !candidate.spent) {
            return AccountChosen(
              accountId: candidate.id,
              cursor: (index + 1) % n,
            );
          }
        }
        // Unreachable: `usable` was non-empty, so some candidate qualifies.
        return AccountChosen(accountId: usable.first.id, cursor: cursor);
    }
  }
}
