enum RunLivenessClass {
  productive('productive'),
  completed('completed'),
  blocked('blocked'),
  empty('empty'),
  looping('looping'),
  failed('failed');

  const RunLivenessClass(this.label);

  final String label;

  static RunLivenessClass tryParse(String? value) {
    if (value == null) {
      return RunLivenessClass.empty;
    }
    return RunLivenessClass.values.where(
      (c) => c.label == value.toLowerCase(),
    ).firstOrNull ?? RunLivenessClass.empty;
  }
}

class RunLivenessEvidence {
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

  final int filesChanged;
  final int commitsMade;
  final int commentsCreated;
  final int toolCallsExecuted;
  final int uniqueCommands;
  final int totalCommands;
  final int exitCode;
  final int thinkingBlocks;
  final int errorMessages;
}

class RunLivenessClassifier {
  RunLivenessClassifier._();
  static const int _loopThreshold = 3;

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
