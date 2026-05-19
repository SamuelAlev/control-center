import 'package:cc_domain/features/model_routing/domain/entities/credential_account.dart';
import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';
import 'package:collection/collection.dart';

/// The two windows a ranking strategy compares: a short [primary] (e.g. 5h) and
/// a longer [secondary] (e.g. 7d). Either may be null when unavailable.
class RankingWindows {
  /// Creates a [RankingWindows].
  const RankingWindows({this.primary, this.secondary});

  /// Short window.
  final UsageLimit? primary;

  /// Long window.
  final UsageLimit? secondary;
}

/// Per-provider rules for ranking credentials.
abstract class CredentialRankingStrategy {
  /// Const base constructor.
  const CredentialRankingStrategy();

  /// Default window durations (ms) used when a window omits its own duration.
  ({int primaryMs, int secondaryMs}) get windowDefaults;

  /// Selects the primary/secondary windows from a report for [modelId].
  RankingWindows findWindowLimits(UsageReport report, {String? modelId});

  /// The limits that decide exhaustion for [modelId] (defaults to all limits).
  List<UsageLimit> scopeLimits(UsageReport report, {String? modelId}) =>
      report.limits;

  /// A model-family scope key for block-all-or-nothing, if any.
  String? blockScope({String? modelId}) => null;

  /// Whether a primary window grants a priority boost (e.g. a Pro plan).
  bool hasPriorityBoost(UsageLimit? primary) => false;
}

/// A generic strategy: primary = shortest-duration window, secondary =
/// longest. Exhaustion is decided across all limits. Suitable for most
/// providers and as the default.
class DefaultCredentialRankingStrategy extends CredentialRankingStrategy {
  /// Creates a [DefaultCredentialRankingStrategy].
  const DefaultCredentialRankingStrategy();

  @override
  ({int primaryMs, int secondaryMs}) get windowDefaults => (
    primaryMs: const Duration(hours: 5).inMilliseconds,
    secondaryMs: const Duration(days: 7).inMilliseconds,
  );

  @override
  RankingWindows findWindowLimits(UsageReport report, {String? modelId}) {
    final windowed = report.limits.where((l) => l.window != null).toList();
    if (windowed.isEmpty) {
      final any = report.limits.isEmpty ? null : report.limits.first;
      return RankingWindows(primary: any, secondary: any);
    }
    windowed.sort(
      (a, b) => (a.window!.durationMs ?? 1 << 62).compareTo(
        b.window!.durationMs ?? 1 << 62,
      ),
    );
    return RankingWindows(primary: windowed.first, secondary: windowed.last);
  }
}

/// One credential's computed rank metrics.
class RankedCredential {
  /// Creates a [RankedCredential].
  const RankedCredential({
    required this.account,
    required this.blocked,
    required this.primaryUsed,
    required this.secondaryUsed,
    required this.primaryDrain,
    required this.secondaryDrain,
    required this.priorityBoost,
    this.blockedUntil,
  });

  /// The account.
  final CredentialAccount account;

  /// Whether the credential is currently blocked.
  final bool blocked;

  /// When the block lifts (if blocked).
  final DateTime? blockedUntil;

  /// Normalized primary-window used fraction [0..1].
  final double primaryUsed;

  /// Normalized secondary-window used fraction [0..1].
  final double secondaryUsed;

  /// Primary-window drain rate (used-fraction per hour).
  final double primaryDrain;

  /// Secondary-window drain rate (used-fraction per hour).
  final double secondaryDrain;

  /// Whether the credential has a priority boost.
  final bool priorityBoost;
}

/// The result of ranking: the ordered accounts plus any new block states
/// discovered (exhausted windows) for the caller to persist.
class CredentialRankingResult {
  /// Creates a [CredentialRankingResult].
  const CredentialRankingResult({required this.ordered, required this.blocks});

  /// Accounts best-first (the head is the credential to use).
  final List<CredentialAccount> ordered;

  /// Block states discovered during ranking (to persist / merge).
  final List<AccountBlockState> blocks;

  /// The best credential, or null if there were none.
  CredentialAccount? get best => ordered.isEmpty ? null : ordered.first;
}

/// Ranks multiple credentials for a provider by remaining usage headroom for
/// the requested model — the head of the result is the credential with the most
/// room.
class CredentialRanker {
  /// Creates a ranker with a [strategy].
  const CredentialRanker({
    this.strategy = const DefaultCredentialRankingStrategy(),
  });

  /// The provider-specific ranking rules.
  final CredentialRankingStrategy strategy;

  static const double _defaultFraction = 0.5;

  /// Ranks [accounts] using their [reports] (keyed by account id). Accounts
  /// already blocked at [now] (in [existingBlocks]) sort last; an account whose
  /// scoped limits are exhausted is freshly blocked until its window resets.
  CredentialRankingResult rank(
    List<CredentialAccount> accounts, {
    required Map<String, UsageReport> reports,
    required DateTime now,
    String? modelId,
    String? sessionId,
    List<AccountBlockState> existingBlocks = const [],
  }) {
    final blocks = <AccountBlockState>[];
    final scope = strategy.blockScope(modelId: modelId);

    final ranked = <RankedCredential>[];
    for (final account in accounts) {
      // Already-blocked?
      final existing = existingBlocks.firstWhereOrNull(
        (b) =>
            b.accountId == account.id && b.scope == scope && b.isActiveAt(now),
      );
      var blocked = existing != null;
      DateTime? blockedUntil = existing?.blockedUntil;

      final report = reports[account.id];
      if (!blocked && report != null) {
        final scoped = strategy.scopeLimits(report, modelId: modelId);
        if (UsageMath.anyExhausted(scoped)) {
          blocked = true;
          blockedUntil =
              UsageMath.earliestReset(scoped) ??
              now.add(const Duration(minutes: 1));
          blocks.add(
            AccountBlockState(
              accountId: account.id,
              blockedUntil: blockedUntil,
              scope: scope,
            ),
          );
        }
      }

      final windows = report == null
          ? const RankingWindows()
          : strategy.findWindowLimits(report, modelId: modelId);
      final primary = windows.primary;
      final secondary = windows.secondary ?? primary;

      ranked.add(
        RankedCredential(
          account: account,
          blocked: blocked,
          blockedUntil: blockedUntil,
          primaryUsed: _fraction(primary),
          secondaryUsed: _fraction(secondary),
          primaryDrain: _drain(primary, now, strategy.windowDefaults.primaryMs),
          secondaryDrain: _drain(
            secondary,
            now,
            strategy.windowDefaults.secondaryMs,
          ),
          priorityBoost:
              account.priorityBoost || strategy.hasPriorityBoost(primary),
        ),
      );
    }

    ranked.sort(_compare);

    // Session-stable selection among a leading tie (deterministic).
    _applySessionStability(ranked, sessionId);

    return CredentialRankingResult(
      ordered: [for (final r in ranked) r.account],
      blocks: blocks,
    );
  }

  /// Whether the current healthy [preferred] credential can be reused without a
  /// full re-rank (preserving the prompt cache). True when it is not blocked and
  /// its scoped limits are not exhausted.
  bool canReusePreferred(
    CredentialAccount preferred, {
    UsageReport? report,
    required DateTime now,
    String? modelId,
    List<AccountBlockState> existingBlocks = const [],
  }) {
    final scope = strategy.blockScope(modelId: modelId);
    final blocked = existingBlocks.any(
      (b) =>
          b.accountId == preferred.id && b.scope == scope && b.isActiveAt(now),
    );
    if (blocked) {
      return false;
    }
    if (report == null) {
      return true; // no fresh signal → keep the warm credential
    }
    final scoped = strategy.scopeLimits(report, modelId: modelId);
    return !UsageMath.anyExhausted(scoped);
  }

  int _compare(RankedCredential a, RankedCredential b) {
    // 1) unblocked before blocked
    if (a.blocked != b.blocked) {
      return a.blocked ? 1 : -1;
    }
    // 2) both blocked: earlier unblock first. An unknown unblock time sorts
    //    last (treated as +∞), matching the POSITIVE_INFINITY handling.
    if (a.blocked && b.blocked) {
      const farFuture = 1 << 62;
      final ua = a.blockedUntil?.millisecondsSinceEpoch ?? farFuture;
      final ub = b.blockedUntil?.millisecondsSinceEpoch ?? farFuture;
      final cmp = ua.compareTo(ub);
      if (cmp != 0) {
        return cmp;
      }
    }
    // 3) priority boost first
    if (a.priorityBoost != b.priorityBoost) {
      return a.priorityBoost ? -1 : 1;
    }
    // 4) lowest secondary drain
    var cmp = a.secondaryDrain.compareTo(b.secondaryDrain);
    if (cmp != 0) {
      return cmp;
    }
    // 5) lowest secondary used
    cmp = a.secondaryUsed.compareTo(b.secondaryUsed);
    if (cmp != 0) {
      return cmp;
    }
    // 6) lowest primary drain
    cmp = a.primaryDrain.compareTo(b.primaryDrain);
    if (cmp != 0) {
      return cmp;
    }
    // 7) lowest primary used
    cmp = a.primaryUsed.compareTo(b.primaryUsed);
    if (cmp != 0) {
      return cmp;
    }
    // 8) original order
    return a.account.order.compareTo(b.account.order);
  }

  void _applySessionStability(
    List<RankedCredential> ranked,
    String? sessionId,
  ) {
    if (sessionId == null || ranked.length < 2) {
      return;
    }
    // Collect the leading tie (same metrics as the head, all unblocked).
    final head = ranked.first;
    if (head.blocked) {
      return;
    }
    final tie = <int>[0];
    for (var i = 1; i < ranked.length; i++) {
      final r = ranked[i];
      if (!r.blocked &&
          r.secondaryDrain == head.secondaryDrain &&
          r.secondaryUsed == head.secondaryUsed &&
          r.primaryDrain == head.primaryDrain &&
          r.primaryUsed == head.primaryUsed &&
          r.priorityBoost == head.priorityBoost) {
        tie.add(i);
      } else {
        break;
      }
    }
    if (tie.length < 2) {
      return;
    }
    final pick = tie[_hash(sessionId) % tie.length];
    if (pick != 0) {
      final chosen = ranked.removeAt(pick);
      ranked.insert(0, chosen);
    }
  }

  double _fraction(UsageLimit? limit) {
    if (limit == null) {
      return _defaultFraction;
    }
    return UsageMath.usedFraction(limit) ?? _defaultFraction;
  }

  double _drain(UsageLimit? limit, DateTime now, int defaultWindowMs) {
    // Used fraction, defaulting to 0.5 when there is no signal (mirrors
    // normalizeUsageFraction → a no-data window reads as neutral
    // pressure, not zero, so it doesn't masquerade as the freshest credential).
    final used = _fraction(limit);
    final window = limit?.window;
    final resetsAt = window?.resetsAt;
    // Without a reset time we can't place ourselves in the window, so fall back
    // to the raw used fraction as the rate proxy (matching the reference).
    if (resetsAt == null) {
      return used;
    }
    final durationMs = window?.durationMs ?? defaultWindowMs;
    final remainingMs =
        resetsAt.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    final elapsedMs = (durationMs - remainingMs).toDouble();
    final elapsedHours = (elapsedMs / 3600000).clamp(0.01, double.infinity);
    return used / elapsedHours;
  }

  /// FNV-1a 32-bit hash, for deterministic session-stable selection.
  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }
}
