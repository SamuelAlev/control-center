/// The observable signals of one eval repetition, graded by `EvalGrader`s
/// (PRD 21 §5).
///
/// Populated by the eval runner after executing the task: intrinsic signals
/// (outcome, cost, turns, tool profile, sandbox violations, files touched) plus
/// named boolean/derived [signals] the runner computed (e.g. `testsPassed`,
/// `planValid`, `diffApplied`, `lintsClean`). Graders are pure functions over
/// this value, so the whole grading layer is deterministic and testable.
class EvalOutcome {
  /// Creates an [EvalOutcome].
  const EvalOutcome({
    required this.completed,
    this.costCents = 0,
    this.turnCount = 0,
    this.toolCalls = const [],
    this.sandboxViolations = 0,
    this.filesTouched = const [],
    this.durationMs = 0,
    this.signals = const {},
    this.error,
  });

  /// Whether the run reached a clean terminal state (no error).
  final bool completed;

  /// Metered cost in cents.
  final int costCents;

  /// Number of agent turns.
  final int turnCount;

  /// Tool names invoked, in order (the tool-call profile).
  final List<String> toolCalls;

  /// Count of sandbox-policy violations observed.
  final int sandboxViolations;

  /// Repo-relative paths the run touched.
  final List<String> filesTouched;

  /// Wall-clock duration in milliseconds.
  final int durationMs;

  /// Named signals the runner computed (bool or scalar), keyed by name.
  final Map<String, Object> signals;

  /// Failure detail when [completed] is false.
  final String? error;

  /// Reads a boolean signal (missing → false).
  bool signalBool(String key) => signals[key] == true;

  /// Serializes to JSON (for the scorecard's per-rep detail).
  Map<String, dynamic> toJson() => {
    'completed': completed,
    'costCents': costCents,
    'turnCount': turnCount,
    'toolCalls': toolCalls,
    'sandboxViolations': sandboxViolations,
    'filesTouched': filesTouched,
    'durationMs': durationMs,
    'signals': signals,
    if (error != null) 'error': error,
  };
}

/// The [EvalOutcome.signals] key meaning "this run delivered its plan".
///
/// Declared as a constant so the grader that reads it and the executor that
/// writes it cannot drift — a signal key that only exists as two string
/// literals silently grades nothing when one of them is edited.
///
/// Its value is the negation of the run's completion contract going unmet: a
/// plan-mode run that ends `contractUnmet` never called `submit_plan`.
const String evalSignalPlanSubmitted = 'planSubmitted';
