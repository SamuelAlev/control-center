/// The paired quality verdict of a skill change's campaign.
enum ImprovementVerdict {
  /// The change measured better than the current skill.
  superior,

  /// The change measured no worse than the current skill.
  nonInferior,

  /// The change measured worse than the current skill.
  inferior,

  /// The runs could not tell the two apart.
  inconclusive,
}

/// Wire names for [ImprovementVerdict].
extension ImprovementVerdictWire on ImprovementVerdict {
  /// The wire name.
  String get wire => switch (this) {
    ImprovementVerdict.superior => 'superior',
    ImprovementVerdict.nonInferior => 'non_inferior',
    ImprovementVerdict.inferior => 'inferior',
    ImprovementVerdict.inconclusive => 'inconclusive',
  };

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementVerdict? tryParse(String? raw) {
    for (final value in ImprovementVerdict.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The numbers of a skill change's campaign report, as the server sends them
/// beside the proposal (`evaluation`): how many paired runs ran, how many the
/// change and the current skill each solved, the verdict, regression counts,
/// and whether the plan ran in full. A client shows them; the server alone
/// decides whether the campaign passed.
class ImprovementEvaluationSummary {
  /// Creates a summary. Every count is zero or more.
  ImprovementEvaluationSummary({
    required this.pairedRuns,
    required this.candidateSolved,
    required this.baselineSolved,
    required this.verdict,
    required this.qualityLosses,
    required this.costRegressions,
    required this.harnessErrors,
    required this.coverageComplete,
    required this.planViolations,
  }) {
    for (final (name, value) in [
      ('pairedRuns', pairedRuns),
      ('candidateSolved', candidateSolved),
      ('baselineSolved', baselineSolved),
      ('qualityLosses', qualityLosses),
      ('costRegressions', costRegressions),
      ('harnessErrors', harnessErrors),
      ('planViolations', planViolations ?? 0),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
  }

  /// How many runs were paired (the change and the current skill on one
  /// task).
  final int pairedRuns;

  /// How many paired runs the change solved.
  final int candidateSolved;

  /// How many paired runs the current skill solved.
  final int baselineSolved;

  /// The paired verdict; null when the report names none or one this client
  /// does not know.
  final ImprovementVerdict? verdict;

  /// Tasks whose quality dropped with the change.
  final int qualityLosses;

  /// Tasks that cost more with the change.
  final int costRegressions;

  /// Runs of the change that hit a harness error.
  final int harnessErrors;

  /// Whether every planned run finished.
  final bool coverageComplete;

  /// How many times the campaign broke its plan; null when the report does
  /// not say.
  final int? planViolations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementEvaluationSummary &&
          pairedRuns == other.pairedRuns &&
          candidateSolved == other.candidateSolved &&
          baselineSolved == other.baselineSolved &&
          verdict == other.verdict &&
          qualityLosses == other.qualityLosses &&
          costRegressions == other.costRegressions &&
          harnessErrors == other.harnessErrors &&
          coverageComplete == other.coverageComplete &&
          planViolations == other.planViolations;

  @override
  int get hashCode => Object.hash(
    pairedRuns,
    candidateSolved,
    baselineSolved,
    verdict,
    qualityLosses,
    costRegressions,
    harnessErrors,
    coverageComplete,
    planViolations,
  );
}
