/// How the product's verification of a goal attempt's last claim ended.
enum GoalVerificationResult {
  /// Nothing was verified: no claim, or the arm takes the claim as the
  /// completion (`claim_only`).
  notRun('not_run'),

  /// The checks passed and the review passed: the goal completed.
  passed('passed'),

  /// The last claim failed and the verification rounds were used up
  /// (`verification_failed`).
  failedRounds('failed_rounds'),

  /// The reviewer could not tell, or gave no usable answer
  /// (`cannot_verify`).
  cannotVerify('cannot_verify'),

  /// A check could not run as written (`check_broken`): the contract's
  /// fault, a person's to fix.
  checkBroken('check_broken'),

  /// The checks needed a sandbox (`sandbox_unavailable`).
  sandboxUnavailable('sandbox_unavailable'),

  /// The verification stopped for any other reason a person would decide
  /// (the hold detail says which), or the attempt ended while a claim was
  /// still being verified.
  stopped('stopped');

  const GoalVerificationResult(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string; an unknown or absent value reads as [stopped].
  static GoalVerificationResult fromWire(String? raw) =>
      values.firstWhere((value) => value.wire == raw, orElse: () => stopped);
}

/// What a goal attempt came to: whether the agent claimed, whether its arm
/// accepted a claim as the completion, and what verification found.
///
/// A false completion is an accepted completion whose hidden authoritative
/// check fails; the attempt's verification results carry that check.
class EvaluationGoalOutcome {
  /// Creates an outcome. Throws [ArgumentError] for a negative count, an
  /// accepted completion without a claim, or a verification without one.
  EvaluationGoalOutcome({
    required this.claims,
    required this.accepted,
    required this.verification,
    required this.rounds,
    required this.segments,
    this.holdDetail,
  }) {
    if (claims < 0 || rounds < 0 || segments < 0) {
      throw ArgumentError('goal outcome counts must not be negative');
    }
    if ((accepted || verification != GoalVerificationResult.notRun) &&
        claims == 0) {
      throw ArgumentError('a goal with no claim accepts and verifies nothing');
    }
  }

  /// Parses from JSON.
  factory EvaluationGoalOutcome.fromJson(Map<String, dynamic> json) =>
      EvaluationGoalOutcome(
        claims: (json['claims'] as num?)?.toInt() ?? 0,
        accepted: json['accepted'] as bool? ?? false,
        verification: GoalVerificationResult.fromWire(
          json['verification'] as String?,
        ),
        rounds: (json['rounds'] as num?)?.toInt() ?? 0,
        segments: (json['segments'] as num?)?.toInt() ?? 0,
        holdDetail: json['holdDetail'] as String?,
      );

  /// How many completion claims the agent recorded.
  final int claims;

  /// Whether the arm took a claim as the goal's completion.
  final bool accepted;

  /// How the product's verification of the last claim ended.
  final GoalVerificationResult verification;

  /// The verification rounds that failed (the goal's
  /// `verificationRounds`).
  final int rounds;

  /// The worker segments the attempt ran.
  final int segments;

  /// The goal's hold detail when verification stopped for a person.
  final String? holdDetail;

  /// Whether the agent claimed at all.
  bool get claimed => claims > 0;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'claims': claims,
    'accepted': accepted,
    'verification': verification.wire,
    'rounds': rounds,
    'segments': segments,
    if (holdDetail != null) 'holdDetail': holdDetail,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationGoalOutcome &&
          claims == other.claims &&
          accepted == other.accepted &&
          verification == other.verification &&
          rounds == other.rounds &&
          segments == other.segments &&
          holdDetail == other.holdDetail;

  @override
  int get hashCode =>
      Object.hash(claims, accepted, verification, rounds, segments, holdDetail);
}
