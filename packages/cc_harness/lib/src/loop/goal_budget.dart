/// Token counters as a provider reports them for one segment of a goal.
class GoalTokenUsage {
  /// Creates a [GoalTokenUsage].
  const GoalTokenUsage({
    this.input = 0,
    this.output = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
  });

  /// Fresh input tokens.
  final int input;

  /// Generated tokens.
  final int output;

  /// Tokens served from the provider's prompt cache.
  final int cacheRead;

  /// Tokens written INTO the prompt cache.
  final int cacheWrite;
}

/// Tokens a goal actually consumed between two usage readings.
///
/// **Counts `cacheWrite`, excludes `cacheRead`, and both halves matter.**
///
/// Cache READS are a re-sent prefix the goal already paid for once; charging
/// them again would make a long goal appear to spend its budget several times
/// over on work it is not doing.
///
/// Cache WRITES are the opposite: they are real, they are billed, and they are
/// large. Rotating an expiring cache or re-anchoring a changed system prompt
/// can write six figures of tokens in a single turn, and a budget blind to
/// them silently overshoots — which is exactly what a budget exists to prevent.
///
/// Clamped at zero per component because a provider that resets a counter
/// mid-run must not produce a negative delta that credits the goal tokens back.
int goalTokenDelta(GoalTokenUsage current, GoalTokenUsage baseline) {
  var total = 0;
  total += (current.input - baseline.input).clamp(0, 1 << 62);
  total += (current.output - baseline.output).clamp(0, 1 << 62);
  total += (current.cacheWrite - baseline.cacheWrite).clamp(0, 1 << 62);
  return total;
}

/// A goal's lifecycle state.
enum GoalBudgetState {
  /// Working, within budget.
  active,

  /// Out of budget. NOT the same as complete.
  budgetLimited,

  /// Verified complete.
  complete,
}

/// Tracks one goal's token and wall-clock spend against its budget.
class GoalBudget {
  /// Creates a [GoalBudget].
  ///
  /// A null [tokenBudget] is unbounded — the run is then bounded by its cost
  /// cap and the repetition guard instead.
  GoalBudget({
    this.tokenBudget,
    this.timeBudget,
    DateTime? startedAt,
    int tokensUsed = 0,
  }) : _startedAt = startedAt ?? DateTime.now(),
       _tokensUsed = tokensUsed;

  /// Token ceiling, or null for unbounded.
  final int? tokenBudget;

  /// Wall-clock ceiling, or null for unbounded.
  final Duration? timeBudget;

  final DateTime _startedAt;
  int _tokensUsed;
  bool _limitReported = false;

  /// Tokens consumed so far.
  int get tokensUsed => _tokensUsed;

  /// Tokens left, or null when unbounded.
  int? get tokensRemaining =>
      tokenBudget == null ? null : (tokenBudget! - _tokensUsed).clamp(0, tokenBudget!);

  /// Time consumed so far.
  Duration elapsed({DateTime? now}) =>
      (now ?? DateTime.now()).difference(_startedAt);

  /// Adds the delta between two usage readings.
  void record(GoalTokenUsage current, GoalTokenUsage baseline) {
    _tokensUsed += goalTokenDelta(current, baseline);
  }

  /// Adds a already-computed delta.
  void addTokens(int delta) {
    if (delta > 0) {
      _tokensUsed += delta;
    }
  }

  /// Whether the goal has run out of budget.
  bool isExhausted({DateTime? now}) {
    if (tokenBudget != null && _tokensUsed >= tokenBudget!) {
      return true;
    }
    final time = timeBudget;
    return time != null && elapsed(now: now) >= time;
  }

  /// Whether the one-shot wrap-up steer should fire now.
  ///
  /// Guarded so the goal is told ONCE. Repeating "you are out of budget" every
  /// turn spends the remaining budget saying so, and reads to the model as a
  /// system that has stopped listening.
  bool shouldReportLimit({DateTime? now}) {
    if (_limitReported || !isExhausted(now: now)) {
      return false;
    }
    _limitReported = true;
    return true;
  }

  /// A short budget line for a prompt or a status row.
  String describe({DateTime? now}) {
    final parts = <String>[];
    if (tokenBudget != null) {
      parts.add('$_tokensUsed / $tokenBudget tokens');
    } else if (_tokensUsed > 0) {
      parts.add('$_tokensUsed tokens');
    }
    final spent = elapsed(now: now);
    if (spent.inMinutes > 0) {
      parts.add('${spent.inMinutes} min');
    }
    return parts.isEmpty ? 'no spend recorded' : parts.join(' · ');
  }
}

/// The steer sent once when a goal hits its budget.
///
/// The load-bearing sentence is the last one. Left to itself a model reads
/// "you are out of budget" as "wrap up and declare victory", and a goal that
/// reports success because it ran out of money is worse than one that reports
/// honestly that it did not finish — the first is a lie the user acts on.
String goalBudgetLimitSteer({
  required String objective,
  required String budgetLine,
}) =>
    '''
The budget for this goal is spent ($budgetLine).

<objective>
$objective
</objective>

Do NOT start new substantive work. Wrap up this turn: summarize what is
actually done and verified, name what remains, and leave a clear next step.

Budget exhaustion is not completion. Do not declare the goal complete unless
the current state of the repository proves it is — if the work is unfinished,
say so plainly.''';

/// The audit a goal must pass before it may declare itself finished.
///
/// This is the single highest-value prompt in the whole port. The failure it
/// prevents is the expensive one: an autonomous loop that decides it is done,
/// reports success, and stops — while the thing it was asked to do does not
/// work. Every step exists because of a specific way that happens.
const String goalCompletionAudit = '''
Before declaring this goal complete, audit it against the CURRENT state of the
repository:

1. Restate the objective as concrete deliverables. What files, behaviours,
   tests or artifacts must exist for it to be true? Write them down.
2. Map each deliverable to the evidence that would prove it: a file's contents,
   a command's output, a test's pass status.
3. Inspect the actual current state. Read the files. Run the commands. Do NOT
   rely on your memory of earlier in this run — the repository may have changed
   since, including by you.
4. Match verification scope to claim scope. One unit test passing does not
   prove a feature works end to end.
5. Treat uncertainty as not-yet-done. Indirect evidence, partial coverage or
   "it looks right" without inspection all mean keep working.
6. Budget exhaustion is not completion. Never declare done because tokens are
   nearly out; if the budget is tight and the work is unfinished, say so and
   stop.

Declare completion only when every deliverable has direct, current-state
evidence. It is a load-bearing claim: it ends the loop and tells the user the
work is finished.''';

/// The hidden continuation sent to keep an autonomous goal working.
///
/// Framed as data, not instruction, and explicitly told not to narrate: a
/// continuation that says "continuing with the goal" every segment burns a turn
/// on saying nothing.
String goalContinuationSteer({
  required String objective,
  required String budgetLine,
}) =>
    '''
Continue working on the active goal.

<objective>
$objective
</objective>

Budget: $budgetLine

This is an autonomous continuation. The objective persists across segments —
never redefine success around a smaller or already-completed subset of it.

$goalCompletionAudit

If the work is not done, just keep working. Do not narrate that you are
continuing — act.''';
