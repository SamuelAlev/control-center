// Per-turn token budget directives and live tracking.
//
// A user can embed a budget directive in a turn's prompt to cap how much
// output the agent is expected to produce in that turn. The directive is a
// `+<number>[k|m][!]` token, e.g. `+500k` (soft, 500 000 tokens), `+500k!`
// (hard, 500 000 tokens), or `+1.5m` (soft, 1 500 000 tokens). A soft budget
// only steers (a one-shot advisory nudge once crossed); a hard budget (`!`)
// is enforced — once exceeded the turn is over budget.

/// A parsed per-turn token budget directive.
class TurnBudget {
  /// Creates a budget capping the turn at [total] output tokens.
  ///
  /// When [hard] is `true` the budget is enforced (exceeding [total] is an
  /// error condition); otherwise it is advisory and only steers once crossed.
  const TurnBudget(this.total, {this.hard = false});

  /// The output-token ceiling for the turn.
  final int total;

  /// Whether the budget is enforced (`true`, the `!` marker) or advisory.
  final bool hard;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnBudget && total == other.total && hard == other.hard;

  @override
  int get hashCode => Object.hash(total, hard);

  @override
  String toString() => 'TurnBudget(total: $total, hard: $hard)';
}

/// Matches a `+<number>[k|m][!]` budget directive anywhere in a string.
///
/// Group 1 is the numeric value (optionally fractional), group 2 the optional
/// unit suffix (`k`/`m`, case-insensitive) and group 3 the optional hard
/// marker (`!`). The directive must be bounded by whitespace or string edges so
/// it is not matched inside a larger token.
final RegExp _turnBudgetPattern = RegExp(
  r'(?:^|\s)\+(\d+(?:\.\d+)?)([km])?(!)?(?=\s|$)',
  caseSensitive: false,
);

/// Parses the first turn-budget directive found in [text].
///
/// Returns `null` when [text] contains no directive, or when the parsed value
/// is not a finite positive number (e.g. `+0`). The value is scaled by its
/// unit (`k` → 1000, `m` → 1 000 000, none → 1) and rounded to the nearest
/// integer token count. The `!` marker produces a hard budget.
TurnBudget? parseTurnBudget(String text) {
  final match = _turnBudgetPattern.firstMatch(text);
  if (match == null) {
    return null;
  }

  final value = double.tryParse(match.group(1)!);
  if (value == null || !value.isFinite || value <= 0) {
    return null;
  }

  final unit = match.group(2)?.toLowerCase();
  final multiplier = switch (unit) {
    'k' => 1000,
    'm' => 1000000,
    _ => 1,
  };

  final total = (value * multiplier).round();
  final hard = match.group(3) == '!';
  return TurnBudget(total, hard: hard);
}

/// The action a [TurnBudgetTracker] recommends after recording output.
enum TurnBudgetDecision {
  /// No action — within budget, or already-steered soft budget.
  none,

  /// First crossing of a soft budget: emit a one-shot advisory steer.
  steer,

  /// A hard budget's ceiling has been reached or passed.
  exceeded,
}

/// Accumulates output tokens against a [TurnBudget] and decides when to act.
///
/// Feed observed output-token deltas through [record]; it returns the action
/// to take. A hard budget reports [TurnBudgetDecision.exceeded] on every call
/// once the ceiling is reached. A soft budget reports
/// [TurnBudgetDecision.steer] exactly once (the first crossing) and
/// [TurnBudgetDecision.none] thereafter.
class TurnBudgetTracker {
  /// Creates a tracker enforcing [budget].
  TurnBudgetTracker(this.budget);

  /// The budget being tracked.
  final TurnBudget budget;

  int _outputTokens = 0;
  bool _steered = false;

  /// Total output tokens recorded so far this turn.
  int get outputTokens => _outputTokens;

  /// Fraction of the budget consumed (`outputTokens / total`).
  ///
  /// Returns `0` when the budget total is non-positive to avoid division by
  /// zero.
  double get fraction => budget.total <= 0 ? 0 : _outputTokens / budget.total;

  /// Records [outputTokensDelta] additional output tokens and returns the
  /// recommended action.
  ///
  /// Negative deltas are ignored (clamped to zero) so accounting can only move
  /// forward.
  TurnBudgetDecision record(int outputTokensDelta) {
    if (outputTokensDelta > 0) {
      _outputTokens += outputTokensDelta;
    }

    if (budget.total <= 0 || _outputTokens < budget.total) {
      return TurnBudgetDecision.none;
    }

    if (budget.hard) {
      return TurnBudgetDecision.exceeded;
    }

    if (_steered) {
      return TurnBudgetDecision.none;
    }
    _steered = true;
    return TurnBudgetDecision.steer;
  }
}
