/// A recommended autonomy ceiling, derived from measured reliability (PRD 21
/// §7 → the PRD 16 §12 graduated-autonomy dial).
enum RecommendedAutonomy {
  /// Not enough evidence, or poor reliability: observe only.
  observeOnly('observe_only'),

  /// Reliable enough to act, but with human approval on effects.
  actWithApproval('act_with_approval'),

  /// Demonstrated reliability high enough to act freely.
  actFreely('act_freely');

  const RecommendedAutonomy(this.wire);

  /// Stable wire string.
  final String wire;
}

/// The evidence a reliability score is computed from (PRD 21 §7). All fields
/// are already-captured analytics — eval pass-rates plus production outcomes.
class ReliabilityEvidence {
  /// Creates a [ReliabilityEvidence].
  const ReliabilityEvidence({
    this.gradedRuns = 0,
    this.gradedPassRate = 0,
    this.productionRuns = 0,
    this.productionSuccessRate = 0,
    this.sandboxViolations = 0,
    this.doomLoopIncidents = 0,
    this.humanFeedbackPositive = 0,
    this.humanFeedbackNegative = 0,
  });

  /// Number of graded eval runs.
  final int gradedRuns;

  /// Eval pass-rate `[0, 1]`.
  final double gradedPassRate;

  /// Number of production (non-eval) runs.
  final int productionRuns;

  /// Production success rate `[0, 1]`.
  final double productionSuccessRate;

  /// Total sandbox violations across the window.
  final int sandboxViolations;

  /// Doom-loop incidents across the window.
  final int doomLoopIncidents;

  /// Positive human feedback count.
  final int humanFeedbackPositive;

  /// Negative human feedback count.
  final int humanFeedbackNegative;

  /// Total graded + production runs (the evidence volume).
  int get totalRuns => gradedRuns + productionRuns;
}

/// A computed reliability score with its rationale (PRD 21 §7).
class ReliabilityScore {
  /// Creates a [ReliabilityScore].
  const ReliabilityScore({
    required this.score,
    required this.recommended,
    required this.rationale,
    required this.evidence,
  });

  /// Computes a reliability score + autonomy recommendation from [evidence].
  ///
  /// Deterministic and pure. The score blends eval pass-rate and production
  /// success weighted by volume, penalized by sandbox violations, doom-loops,
  /// and negative feedback. The recommendation requires *both* a high score
  /// AND a minimum evidence volume — an agent with no history is never
  /// recommended for act-freely (spec: the dial cites *why*).
  factory ReliabilityScore.compute(
    ReliabilityEvidence evidence, {
    int minRunsForApproval = 20,
    int minRunsForFreely = 100,
    double approvalThreshold = 0.85,
    double freelyThreshold = 0.95,
  }) {
    final rationale = <String>[];
    final total = evidence.totalRuns;

    // Weighted quality: eval + production, by volume. No runs → 0.
    final weightedRuns = evidence.gradedRuns + evidence.productionRuns;
    var quality = 0.0;
    if (weightedRuns > 0) {
      quality =
          (evidence.gradedPassRate * evidence.gradedRuns +
              evidence.productionSuccessRate * evidence.productionRuns) /
          weightedRuns;
    }

    // Penalties (bounded).
    final violationPenalty = total == 0
        ? 0.0
        : (evidence.sandboxViolations / total).clamp(0.0, 0.5);
    final doomPenalty = total == 0
        ? 0.0
        : (evidence.doomLoopIncidents / total).clamp(0.0, 0.3);
    final feedbackTotal =
        evidence.humanFeedbackPositive + evidence.humanFeedbackNegative;
    final feedbackPenalty = feedbackTotal == 0
        ? 0.0
        : (evidence.humanFeedbackNegative / feedbackTotal * 0.2).clamp(
            0.0,
            0.2,
          );

    final score = (quality - violationPenalty - doomPenalty - feedbackPenalty)
        .clamp(0.0, 1.0);

    rationale.add(
      total == 0
          ? 'No graded or production history yet.'
          : '${(quality * 100).round()}% quality over $total run(s) '
                '(${evidence.gradedRuns} graded, ${evidence.productionRuns} prod).',
    );
    if (evidence.sandboxViolations > 0) {
      rationale.add('${evidence.sandboxViolations} sandbox violation(s).');
    }
    if (evidence.doomLoopIncidents > 0) {
      rationale.add('${evidence.doomLoopIncidents} doom-loop incident(s).');
    }

    RecommendedAutonomy recommended;
    if (total >= minRunsForFreely &&
        score >= freelyThreshold &&
        evidence.sandboxViolations == 0) {
      recommended = RecommendedAutonomy.actFreely;
      rationale.add(
        'act-freely: ${(score * 100).round()}% over $total graded run(s), '
        '0 sandbox violations.',
      );
    } else if (total >= minRunsForApproval && score >= approvalThreshold) {
      recommended = RecommendedAutonomy.actWithApproval;
      rationale.add(
        'act-with-approval: reliable but evidence/threshold below '
        'the act-freely bar.',
      );
    } else {
      recommended = RecommendedAutonomy.observeOnly;
      rationale.add(
        total < minRunsForApproval
            ? 'observe-only: not enough evidence yet ($total run(s)).'
            : 'observe-only: reliability below the approval bar.',
      );
    }

    return ReliabilityScore(
      score: score,
      recommended: recommended,
      rationale: rationale,
      evidence: evidence,
    );
  }

  /// The reliability score `[0, 1]`.
  final double score;

  /// The recommended autonomy ceiling.
  final RecommendedAutonomy recommended;

  /// The human-readable evidence lines (shown on the autonomy dial).
  final List<String> rationale;

  /// The evidence the score was computed from.
  final ReliabilityEvidence evidence;

  /// Whether an agent may be set to [target] given this score (the dial gate):
  /// act-freely requires an act-freely recommendation.
  bool permits(RecommendedAutonomy target) {
    switch (target) {
      case RecommendedAutonomy.observeOnly:
        return true;
      case RecommendedAutonomy.actWithApproval:
        return recommended != RecommendedAutonomy.observeOnly;
      case RecommendedAutonomy.actFreely:
        return recommended == RecommendedAutonomy.actFreely;
    }
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'score': score,
    'recommended': recommended.wire,
    'rationale': rationale,
  };
}
