import 'dart:math' as math;

/// Lifecycle state of a [Goal].
///
/// A goal is pursued while [active], can be temporarily suspended ([paused]), is forced
/// into a wrap-up posture once its token budget is spent ([budgetLimited]),
/// reaches [complete] when the objective is met, or is [dropped] when abandoned.
enum GoalStatus {
  /// The goal is being actively pursued and consuming budget.
  active,

  /// The goal is temporarily suspended; no work is attributed to it.
  paused,

  /// The goal's token budget is exhausted; the model is steered to wrap up.
  budgetLimited,

  /// The goal's objective has been met.
  complete,

  /// The goal was abandoned before completion.
  dropped,
}

/// An immutable, persistence-free domain value object describing a single
/// budgeted objective for an agent to pursue.
///
/// A [Goal] carries an optional [tokenBudget] and the running [tokensUsed] /
/// [timeUsedSeconds] tallies accumulated by [GoalBudgetTracker.applyTurn]. It
/// owns no persistence concerns — callers stamp [updatedAt] and persist the
/// returned copies themselves.
class Goal {
  /// Creates a [Goal].
  const Goal({
    required this.id,
    required this.workspaceId,
    required this.objective,
    this.status = GoalStatus.active,
    this.tokenBudget,
    this.tokensUsed = 0,
    this.timeUsedSeconds = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique goal identifier.
  final String id;

  /// Workspace this goal belongs to.
  final String workspaceId;

  /// Human-readable objective the agent is pursuing.
  final String objective;

  /// Current lifecycle state.
  final GoalStatus status;

  /// Optional ceiling on tokens that may be spent pursuing this goal. Null
  /// means the goal is unbounded — it never flips to [GoalStatus.budgetLimited]
  /// and never triggers a steer notice.
  final int? tokenBudget;

  /// Tokens charged to this goal so far (input + output + cache-write; see
  /// [goalTokenDelta]).
  final int tokensUsed;

  /// Wall-clock seconds spent pursuing this goal so far.
  final int timeUsedSeconds;

  /// When the goal was created.
  final DateTime createdAt;

  /// When the goal was last mutated.
  final DateTime updatedAt;

  /// Fraction of the budget consumed (`tokensUsed / tokenBudget`), or null when
  /// the goal has no [tokenBudget]. Returns 0 for a zero budget to avoid a
  /// divide-by-zero (a zero-budget goal is treated as having no headroom).
  double? get budgetFraction {
    final budget = tokenBudget;
    if (budget == null) {
      return null;
    }
    if (budget <= 0) {
      return tokensUsed > 0 ? double.infinity : 0;
    }
    return tokensUsed / budget;
  }

  /// Tokens still available under the budget, clamped at 0, or null when the
  /// goal has no [tokenBudget].
  int? get remainingTokens {
    final budget = tokenBudget;
    if (budget == null) {
      return null;
    }
    return math.max<int>(0, budget - tokensUsed);
  }

  /// Returns a copy of this goal with the given fields replaced.
  Goal copyWith({
    String? id,
    String? workspaceId,
    String? objective,
    GoalStatus? status,
    int? tokenBudget,
    int? tokensUsed,
    int? timeUsedSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objective: objective ?? this.objective,
      status: status ?? this.status,
      tokenBudget: tokenBudget ?? this.tokenBudget,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      timeUsedSeconds: timeUsedSeconds ?? this.timeUsedSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          objective == other.objective &&
          status == other.status &&
          tokenBudget == other.tokenBudget &&
          tokensUsed == other.tokensUsed &&
          timeUsedSeconds == other.timeUsedSeconds &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    objective,
    status,
    tokenBudget,
    tokensUsed,
    timeUsedSeconds,
    createdAt,
    updatedAt,
  );
}

/// Computes the tokens to charge to a goal for one turn.
///
/// Sums input, output and cache-*write* tokens, each clamped at 0 so negative
/// inputs never credit the budget. Cache-*read* tokens are deliberately
/// excluded: a cache read replays a previously-built prefix, so it is not new
/// work attributable to the goal's budget.
int goalTokenDelta({
  required int input,
  required int output,
  required int cacheWrite,
}) =>
    math.max<int>(0, input) +
    math.max<int>(0, output) +
    math.max<int>(0, cacheWrite);

/// The outcome of applying one turn's usage to a [Goal].
class GoalUpdate {
  /// Creates a [GoalUpdate].
  const GoalUpdate({
    required this.goal,
    required this.shouldSteer,
    required this.budgetExhausted,
  });

  /// The goal after charging the turn (a copy of the input goal).
  final Goal goal;

  /// True when the model should be nudged to wrap up: either the goal has
  /// crossed the steer threshold (but still has headroom) or its budget is now
  /// fully exhausted.
  final bool shouldSteer;

  /// True when the goal's budget is fully spent and it flipped to
  /// [GoalStatus.budgetLimited].
  final bool budgetExhausted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalUpdate &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          shouldSteer == other.shouldSteer &&
          budgetExhausted == other.budgetExhausted;

  @override
  int get hashCode => Object.hash(goal, shouldSteer, budgetExhausted);
}

/// Charges agent turns against a [Goal]'s token budget and decides when to
/// steer the model toward wrapping up.
///
/// Pure and stateless: [applyTurn] returns a new [GoalUpdate] wrapping a copied
/// goal; the tracker never mutates its input.
class GoalBudgetTracker {
  /// Creates a [GoalBudgetTracker].
  ///
  /// [steerThresholdFraction] is the fraction of the budget at or above which
  /// the model is nudged to wrap up (default 0.88 — 88%).
  const GoalBudgetTracker({this.steerThresholdFraction = 0.88});

  /// Fraction of budget consumed at which to steer the model to wrap up.
  final double steerThresholdFraction;

  /// Charges one turn's usage to [goal] and returns the resulting update.
  ///
  /// The returned goal has [Goal.tokensUsed] increased by
  /// [goalTokenDelta] and [Goal.timeUsedSeconds] increased by
  /// [wallClockSecondsDelta]. If the goal is [GoalStatus.active], has a
  /// [Goal.tokenBudget] and the new usage meets or exceeds that budget, its
  /// status flips to [GoalStatus.budgetLimited]. [Goal.updatedAt] is left
  /// unchanged for the caller to stamp.
  GoalUpdate applyTurn(
    Goal goal, {
    required int input,
    required int output,
    required int cacheWrite,
    int wallClockSecondsDelta = 0,
  }) {
    final delta = goalTokenDelta(
      input: input,
      output: output,
      cacheWrite: cacheWrite,
    );
    final newUsed = goal.tokensUsed + delta;
    final newTime =
        goal.timeUsedSeconds + math.max<int>(0, wallClockSecondsDelta);
    final budget = goal.tokenBudget;

    final exhausted =
        budget != null && goal.status == GoalStatus.active && newUsed >= budget;

    final newStatus = exhausted ? GoalStatus.budgetLimited : goal.status;

    final newGoal = goal.copyWith(
      status: newStatus,
      tokensUsed: newUsed,
      timeUsedSeconds: newTime,
    );

    final fraction = newGoal.budgetFraction;
    final overThreshold =
        newGoal.status == GoalStatus.active &&
        budget != null &&
        fraction != null &&
        fraction >= steerThresholdFraction;

    return GoalUpdate(
      goal: newGoal,
      shouldSteer: exhausted || overThreshold,
      budgetExhausted: exhausted,
    );
  }
}

/// Builds the wrap-up notice injected into the model's context when a [Goal]
/// crosses its steer threshold or exhausts its budget.
///
/// For unbounded goals (no [Goal.tokenBudget]) the notice omits budget figures.
String goalSteerNotice(Goal goal) {
  final budget = goal.tokenBudget;
  if (budget == null) {
    return '[goal budget] You are pursuing objective "${goal.objective}". '
        'Wrap up: finish the current step and report your result.';
  }
  final fraction = goal.budgetFraction ?? 0;
  final percent = (fraction * 100).round();
  return '[goal budget] You have used ${goal.tokensUsed} of $budget tokens '
      '($percent%) on objective "${goal.objective}". '
      'Wrap up: finish the current step and report your result.';
}
