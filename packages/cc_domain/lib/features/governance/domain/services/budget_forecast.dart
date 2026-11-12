/// A single recorded spend event — a run's estimated cost at a point in time.
/// Decouples the forecast maths from the `AgentRunLog` entity so it is a pure,
/// trivially-testable function.
class SpendPoint {
  /// Creates a spend point.
  const SpendPoint({required this.at, required this.costMicros});

  /// When the spend occurred (the run's start time).
  final DateTime at;

  /// The estimated cost in micro-dollars.
  final int costMicros;
}

/// A month-end spend projection for one budget scope (agent or workspace).
class BudgetForecast {
  /// Creates a [BudgetForecast].
  const BudgetForecast({
    required this.spentMicros,
    required this.budgetMicros,
    required this.dailyBurnMicros,
    required this.projectedMonthEndMicros,
    required this.willExceed,
    this.projectedExhaustion,
  });

  /// Micro-dollars spent so far in the current calendar month.
  final int spentMicros;

  /// The budget ceiling (0 = unlimited → [willExceed] is always false).
  final int budgetMicros;

  /// Average spend per day over the look-back window (micro-dollars/day).
  final double dailyBurnMicros;

  /// Projected total spend by month-end at the current burn rate.
  final int projectedMonthEndMicros;

  /// Whether the projection exceeds a (non-zero) budget.
  final bool willExceed;

  /// When cumulative spend is projected to reach the budget ceiling, or null
  /// when there is no ceiling / no burn / it is already reached in the past.
  /// Useful to warn "you'll hit your budget on the 23rd" before the hard-stop.
  final DateTime? projectedExhaustion;

  /// Remaining headroom before the ceiling (negative once over).
  int get remainingMicros => budgetMicros - spentMicros;
}

/// Projects month-end spend for a budget scope from its recent burn rate
/// (FINDINGS §16.1). Pure: pass the scope's [spend] events, the reference
/// instant [now] and the [budgetMicros] ceiling.
///
/// - "Spent this month" sums spend since the 1st (in [now]'s calendar).
/// - Burn rate = spend in the last [lookbackDays] days ÷ [lookbackDays].
/// - Projection = spent-this-month + burn × days-remaining-in-month.
/// - Exhaustion date = now + (headroom ÷ burn), reported whenever there is a
///   ceiling and a positive burn (past/immediate when already over).
BudgetForecast forecastBudget({
  required List<SpendPoint> spend,
  required DateTime now,
  required int budgetMicros,
  int lookbackDays = 7,
}) {
  if (lookbackDays <= 0) {
    throw ArgumentError.value(lookbackDays, 'lookbackDays', 'must be positive');
  }

  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonthStart = DateTime(now.year, now.month + 1, 1);
  final daysInMonth = nextMonthStart.difference(monthStart).inDays;
  // Whole days remaining after today (0 on the last day of the month).
  final daysRemaining = (daysInMonth - now.day).clamp(0, daysInMonth);

  final lookbackStart = now.subtract(Duration(days: lookbackDays));

  var spentThisMonth = 0;
  var recentSpend = 0;
  for (final p in spend) {
    if (!p.at.isBefore(monthStart)) {
      spentThisMonth += p.costMicros;
    }
    // Window is (now - lookbackDays, now] — strict at the far edge so N
    // consecutive daily points give exactly N days of burn, not N+1.
    if (p.at.isAfter(lookbackStart) && !p.at.isAfter(now)) {
      recentSpend += p.costMicros;
    }
  }

  final dailyBurn = recentSpend / lookbackDays;
  final projected = spentThisMonth + (dailyBurn * daysRemaining).round();
  final willExceed = budgetMicros > 0 && projected > budgetMicros;

  DateTime? exhaustion;
  if (budgetMicros > 0) {
    final headroom = budgetMicros - spentThisMonth;
    if (headroom <= 0) {
      // Already at/over the ceiling.
      exhaustion = now;
    } else if (dailyBurn > 0) {
      final daysToExhaust = headroom / dailyBurn;
      exhaustion = now.add(
        Duration(seconds: (daysToExhaust * Duration.secondsPerDay).round()),
      );
    }
  }

  return BudgetForecast(
    spentMicros: spentThisMonth,
    budgetMicros: budgetMicros,
    dailyBurnMicros: dailyBurn,
    projectedMonthEndMicros: projected,
    willExceed: willExceed,
    projectedExhaustion: exhaustion,
  );
}
