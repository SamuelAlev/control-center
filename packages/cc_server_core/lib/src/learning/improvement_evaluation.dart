import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';

/// What a skill proposal's campaign measured, read from its report: the
/// numbers a person judges the change by, and the rule that makes it pass.
///
/// A skill change passes ("no regression observed", never "improved") when
/// its campaign completed with complete coverage and no plan violation, at
/// least one task block was usable, the candidate's quality verdict is not
/// `inferior`, the candidate's observed task-mean difference is at least 0
/// (agent-stopped attempts already count as failures in it), and it shows no
/// harness fault the baseline did not.
///
/// The skill plan is a regression screen (`minTasks: 3`): `inferior` rests on
/// the exact sign-flip p alone, so a loss on every one of 5 or more tasks
/// fails, and below 5 tasks no inferior verdict is possible. An
/// `inconclusive` verdict passes on the observed difference; per-task quality
/// losses and cost regressions are counted and shown, not failing by
/// themselves. The report's own `recommendation` answers another question
/// (move a default to another arm) and is not read.
final class ImprovementEvaluation {
  /// Creates the summary.
  const ImprovementEvaluation({
    required this.coverageComplete,
    required this.planViolations,
    required this.pairs,
    required this.candidateSolved,
    required this.baselineSolved,
    required this.candidateOnlyWins,
    required this.baselineOnlyWins,
    required this.verdict,
    required this.regressions,
    required this.candidateHarnessErrors,
    required this.tasks,
    required this.observedDelta,
    required this.lowerBound,
  });

  /// The summary of [report] (a campaign's projected report), or null when
  /// it has no paired verdict to read.
  static ImprovementEvaluation? fromReport(Map<String, dynamic>? report) {
    if (report == null) {
      return null;
    }
    final verdicts = report['verdicts'];
    final verdict = verdicts is List && verdicts.isNotEmpty
        ? verdicts.first
        : null;
    if (verdict is! Map) {
      return null;
    }
    int count(Object? value) => value is num ? value.toInt() : 0;
    double? real(Object? value) => value is num ? value.toDouble() : null;
    final treatmentArm = verdict['treatmentArmId'];
    final regressions = <String, int>{};
    final listed = report['regressions'];
    if (listed is List) {
      for (final r in listed) {
        if (r is! Map) {
          continue;
        }
        final arm = r['treatmentArmId'];
        final kind = r['kind'];
        if (kind is String && (treatmentArm == null || arm == treatmentArm)) {
          regressions[kind] = (regressions[kind] ?? 0) + 1;
        }
      }
    }
    // What the page counts as runs that hit a harness error: the
    // candidate arm's attempts the harness faulted on, summed over tasks.
    var candidateHarnessErrors = 0;
    final outcomes = report['taskOutcomes'];
    if (outcomes is List) {
      for (final o in outcomes) {
        if (o is Map && (treatmentArm == null || o['armId'] == treatmentArm)) {
          candidateHarnessErrors += count(o['harnessErrors']);
        }
      }
    }
    final violations = report['planViolations'];
    final bothPass = count(verdict['bothPass']);
    final candidateOnly = count(verdict['treatmentOnlyWins']);
    final baselineOnly = count(verdict['baselineOnlyWins']);
    return ImprovementEvaluation(
      coverageComplete: report['coverageComplete'] == true,
      // Absent is not "none": a report that lost the list does not pass.
      planViolations: violations is List ? violations.length : null,
      pairs: count(verdict['pairs']),
      candidateSolved: bothPass + candidateOnly,
      baselineSolved: bothPass + baselineOnly,
      candidateOnlyWins: candidateOnly,
      baselineOnlyWins: baselineOnly,
      verdict: verdict['verdict'] is String
          ? verdict['verdict'] as String
          : null,
      regressions: regressions,
      candidateHarnessErrors: candidateHarnessErrors,
      tasks: count(verdict['effectiveTaskCount']),
      observedDelta: real(verdict['observedDelta']),
      lowerBound: real(verdict['lowerBound']),
    );
  }

  /// Whether every planned attempt ran.
  final bool coverageComplete;

  /// How many plan violations the report lists; null when it lists none
  /// because the list is missing.
  final int? planViolations;

  /// Scored repetition pairs in the used task blocks.
  final int pairs;

  /// Task blocks the verdict used (both arms scored every repetition).
  final int tasks;

  /// The candidate's mean per-task difference in verified success (positive
  /// is better); null when the report lacks it, which does not pass.
  final double? observedDelta;

  /// The one-sided lower bound on that difference: how much worse the
  /// change could be.
  final double? lowerBound;

  /// Pairs the candidate solved.
  final int candidateSolved;

  /// Pairs the baseline solved.
  final int baselineSolved;

  /// Pairs only the candidate solved.
  final int candidateOnlyWins;

  /// Pairs only the baseline solved.
  final int baselineOnlyWins;

  /// The quality verdict's wire name (`superior`, `non_inferior`,
  /// `inferior`, `inconclusive`), or null.
  final String? verdict;

  /// The candidate's per-task regressions, counted by kind's wire name
  /// (`quality_loss`, `cost_regression`, `harness_error`).
  final Map<String, int> regressions;

  /// The candidate's attempts that ended in a harness error, summed over
  /// the report's tasks (`taskOutcomes` of the treatment arm). Shown; the
  /// pass rule reads the per-task [regressions] instead.
  final int candidateHarnessErrors;

  /// Whether the change passes (see the class doc).
  bool get passes =>
      coverageComplete &&
      planViolations == 0 &&
      tasks > 0 &&
      verdict != null &&
      verdict != 'inferior' &&
      // A mean of k-ths can carry rounding noise around zero.
      (observedDelta ?? double.negativeInfinity) >= -1e-9 &&
      (regressions['harness_error'] ?? 0) == 0;

  /// The proposal's `evaluation` wire object. `regressions.harness_error`
  /// is [candidateHarnessErrors] (runs of the change), the number the
  /// client prints as runs that hit a harness error.
  Map<String, dynamic> toWire() => {
    'paired_runs': pairs,
    'candidate_solved': candidateSolved,
    'baseline_solved': baselineSolved,
    'verdict': ?verdict,
    'regressions': {
      for (final kind in const ['quality_loss', 'cost_regression'])
        kind: regressions[kind] ?? 0,
      'harness_error': candidateHarnessErrors,
    },
    'coverage_complete': coverageComplete,
    'plan_violations': ?planViolations,
  };

  /// A campaign's state for a proposal: running until it ends; `passed`
  /// only when it completed and its report [passes]; `failed` otherwise.
  static ImprovementCampaignState outcomeOf(SkillEvaluationCampaign campaign) =>
      switch (campaign.status) {
        SkillEvaluationCampaignStatus.queued ||
        SkillEvaluationCampaignStatus.running ||
        SkillEvaluationCampaignStatus.cancelling =>
          ImprovementCampaignState.running,
        SkillEvaluationCampaignStatus.completed =>
          (fromReport(campaign.report)?.passes ?? false)
              ? ImprovementCampaignState.passed
              : ImprovementCampaignState.failed,
        SkillEvaluationCampaignStatus.cancelled ||
        SkillEvaluationCampaignStatus.failed ||
        SkillEvaluationCampaignStatus.interrupted =>
          ImprovementCampaignState.failed,
      };
}
