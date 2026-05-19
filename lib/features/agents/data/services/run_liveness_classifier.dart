/// Classifies the liveness of an agent run based on observable signals.
enum RunLivenessClass {
  /// Agent produced productive output (file changes, tool calls, comments).
  productive('productive'),
  /// Agent completed work with commits and file changes.
  completed('completed'),
  /// Agent reported a blocker preventing progress.
  blocked('blocked'),
  /// Agent produced no observable output.
  empty('empty'),
  /// Agent is repeating commands without making progress.
  looping('looping'),
  /// Agent run terminated with errors.
  failed('failed');

  const RunLivenessClass(this.label);

  /// Human-readable label for this liveness class.
  final String label;

  /// Parses [value] (case-insensitive label) into a [RunLivenessClass].
  /// Returns [RunLivenessClass.empty] when [value] is null or unrecognised.
  static RunLivenessClass tryParse(String? value) {
    if (value == null) {
      return RunLivenessClass.empty;
    }
    return RunLivenessClass.values.where(
      (c) => c.label == value.toLowerCase(),
    ).firstOrNull ?? RunLivenessClass.empty;
  }
}

/// Observable signals collected during an agent run used to determine liveness.
class RunLivenessEvidence {
  /// Creates a [RunLivenessEvidence] with zero defaults for all fields.
  const RunLivenessEvidence({
    this.filesChanged = 0,
    this.commitsMade = 0,
    this.commentsCreated = 0,
    this.toolCallsExecuted = 0,
    this.uniqueCommands = 0,
    this.totalCommands = 0,
    this.exitCode = 0,
    this.thinkingBlocks = 0,
    this.errorMessages = 0,
  });

  /// Number of files changed during the run.
  final int filesChanged;
  /// Number of commits made.
  final int commitsMade;
  /// Number of comments created.
  final int commentsCreated;
  /// Number of tool calls executed.
  final int toolCallsExecuted;
  /// Number of unique commands issued.
  final int uniqueCommands;
  /// Total number of commands issued.
  final int totalCommands;
  /// Process exit code (0 for success).
  final int exitCode;
  /// Number of thinking blocks observed.
  final int thinkingBlocks;
  /// Number of error messages observed.
  final int errorMessages;
}

/// Classifies an agent run as productive, completed, blocked, empty, looping,
/// or failed based on [RunLivenessEvidence].
class RunLivenessClassifier {
  RunLivenessClassifier._();
  static const int _loopThreshold = 3;

  /// Classifies [evidence] into a [RunLivenessClass] using heuristic rules.
  static RunLivenessClass classify(RunLivenessEvidence evidence) {
    if (evidence.exitCode != 0 && evidence.errorMessages > 0) {
      return RunLivenessClass.failed;
    }

    if (evidence.totalCommands >= _loopThreshold &&
        evidence.uniqueCommands <= 2 &&
        evidence.filesChanged == 0 &&
        evidence.commitsMade == 0) {
      return RunLivenessClass.looping;
    }

    if (evidence.exitCode != 0) {
      return RunLivenessClass.failed;
    }

    final hasProductiveOutput = evidence.filesChanged > 0 ||
        evidence.commitsMade > 0 ||
        evidence.commentsCreated > 0 ||
        evidence.toolCallsExecuted > 0;

    if (hasProductiveOutput) {
      if (evidence.commitsMade > 0 && evidence.filesChanged > 0) {
        return RunLivenessClass.completed;
      }
      return RunLivenessClass.productive;
    }

    if (evidence.thinkingBlocks > 0 && evidence.totalCommands == 0) {
      return RunLivenessClass.empty;
    }

    return RunLivenessClass.empty;
  }

  /// Returns a human-readable description for the given [RunLivenessClass].
  static String description(RunLivenessClass cls) => switch (cls) {
        RunLivenessClass.productive =>
          'Agent made productive changes (files, tool calls, comments).',
        RunLivenessClass.completed =>
          'Agent completed work with commits and file changes.',
        RunLivenessClass.blocked =>
          'Agent reported a blocker preventing progress.',
        RunLivenessClass.empty =>
          'Agent produced no observable output.',
        RunLivenessClass.looping =>
          'Agent appears to be repeating commands without making progress.',
        RunLivenessClass.failed =>
          'Agent run failed with errors.',
      };
}
