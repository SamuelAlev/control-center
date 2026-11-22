/// What an attempt's completion claim is worth: the goal campaign's one
/// setting.
///
/// The attempt runs a goal: the agent works under the goal block, claims with
/// `complete_goal`, and the arm decides what the claim does.
enum GoalVerificationMode {
  /// The claim is the completion: the product before goal verification,
  /// where the agent's claim ended the goal.
  claimOnly('claim_only'),

  /// The product's verification decides: the contract's checks
  /// (`GoalCheckRunner`), then the read-only review run (`GoalVerifier`); a
  /// failed round goes back to the agent with the findings, up to the
  /// product's verification rounds.
  checksReview('checks_review');

  const GoalVerificationMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string; throws [ArgumentError] for any other value, so a
  /// misspelt plan is refused rather than run as a different arm.
  static GoalVerificationMode fromWire(String raw) => values.firstWhere(
    (mode) => mode.wire == raw,
    orElse: () => throw ArgumentError.value(raw, 'goalVerification'),
  );
}

/// Whether an attempt's run has the `repl` script surface.
///
/// A run gets `repl` when the server's script runner passed its self-test,
/// and runs without it when no runner is available: both are states a real
/// run can be in. Nothing switches the eight code mode additions off on
/// their own; they are part of `repl`.
enum CodeModeSurface {
  /// `repl` resident, the direct tools beside it, every other tool a script
  /// may call behind it.
  repl('repl'),

  /// No `repl`: the surface of a server without a runner.
  withoutRepl('without_repl');

  const CodeModeSurface(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string; throws [ArgumentError] for any other value.
  static CodeModeSurface fromWire(String raw) => values.firstWhere(
    (mode) => mode.wire == raw,
    orElse: () => throw ArgumentError.value(raw, 'codeMode'),
  );
}
