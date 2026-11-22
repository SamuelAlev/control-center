import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';

/// The agent's evidence for one "Done means" item, as `complete_goal`
/// received it. A claim, not a proof.
class GoalClaimEvidence {
  /// Creates an evidence entry. Throws [ArgumentError] past the limits.
  GoalClaimEvidence({required this.criterion, required this.evidence}) {
    if (criterion.length > GoalContract.maxCriterionLength) {
      throw ArgumentError.value(
        criterion.length,
        'criterion',
        'must be at most ${GoalContract.maxCriterionLength} characters',
      );
    }
    if (evidence.length > maxEvidenceLength) {
      throw ArgumentError.value(
        evidence.length,
        'evidence',
        'must be at most $maxEvidenceLength characters',
      );
    }
  }

  /// The longest evidence text, in characters.
  static const int maxEvidenceLength = 2000;

  /// The criterion it is evidence for.
  final String criterion;

  /// What the agent says shows it (a command and its result, a file and
  /// line, a pull request).
  final String evidence;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'criterion': criterion,
    'evidence': evidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalClaimEvidence &&
          criterion == other.criterion &&
          evidence == other.evidence;

  @override
  int get hashCode => Object.hash(criterion, evidence);
}

/// What one goal check did when the server ran it.
class GoalCheckResult {
  /// Creates a result. Throws [ArgumentError] for an over-long tail.
  GoalCheckResult({
    required this.run,
    required this.where,
    this.exitCode,
    this.timedOut = false,
    this.outputTail = '',
    this.skippedUnchanged = false,
    this.broken = false,
  }) {
    if (outputTail.length > maxOutputTail) {
      throw ArgumentError.value(
        outputTail.length,
        'outputTail',
        'must be at most $maxOutputTail characters',
      );
    }
  }

  /// How much of a check's output is kept: its last 6,000 characters.
  static const int maxOutputTail = 6000;

  /// The command or environment task that ran.
  final String run;

  /// Where it ran.
  final GoalCheckLocation where;

  /// Its exit code; null when it did not run to an exit (timed out, could
  /// not start, or [skippedUnchanged]).
  final int? exitCode;

  /// Whether it hit its timeout.
  final bool timedOut;

  /// The last [maxOutputTail] characters of its output.
  final String outputTail;

  /// Whether it was not rerun because the worktree fingerprint equals the
  /// one recorded at the last failed check (the round still counts).
  final bool skippedUnchanged;

  /// Whether the check could not run as written: exit 126 or 127, a spawn
  /// failure, or an environment task that does not exist. A broken check is
  /// the contract's fault, not the work's; it may carry an [exitCode] or
  /// none.
  final bool broken;

  /// Whether the check passed: it ran, and exited 0 within its timeout.
  bool get passed => !broken && !timedOut && !skippedUnchanged && exitCode == 0;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'run': run,
    'in': where.wire,
    'exitCode': ?exitCode,
    if (timedOut) 'timedOut': true,
    'outputTail': outputTail,
    if (skippedUnchanged) 'skippedUnchanged': true,
    if (broken) 'broken': true,
  };

  /// Parses leniently: null for anything that is not a result.
  static GoalCheckResult? tryFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final run = json['run'];
    final where = GoalCheckLocationWire.tryParse(
      json['in'] is String ? json['in'] as String : null,
    );
    final tail = json['outputTail'];
    if (run is! String || where == null) {
      return null;
    }
    final text = tail is String ? tail : '';
    return GoalCheckResult(
      run: run,
      where: where,
      exitCode: JsonSafe.intOrNull(json['exitCode']),
      timedOut: json['timedOut'] == true,
      outputTail: text.length > maxOutputTail
          ? text.substring(text.length - maxOutputTail)
          : text,
      skippedUnchanged: json['skippedUnchanged'] == true,
      broken: json['broken'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalCheckResult &&
          run == other.run &&
          where == other.where &&
          exitCode == other.exitCode &&
          timedOut == other.timedOut &&
          outputTail == other.outputTail &&
          skippedUnchanged == other.skippedUnchanged &&
          broken == other.broken;

  @override
  int get hashCode => Object.hash(
    run,
    where,
    exitCode,
    timedOut,
    outputTail,
    skippedUnchanged,
    broken,
  );
}

/// The last verification of a goal (`agent_goal_runs.verification`): the
/// claim it verified, what the checks did, the reviewer's verdict, and the
/// worktree fingerprint it saw.
class GoalVerification {
  /// Creates a record. Throws [ArgumentError] for a round below 1 or an
  /// over-long summary.
  GoalVerification({
    required this.round,
    required this.claimSummary,
    List<GoalClaimEvidence> claimEvidence = const [],
    List<GoalCheckResult> checks = const [],
    this.verdict,
    this.reviewerAgentId,
    this.reviewRunId,
    this.reviewWakeId,
    this.reviewAsks = 0,
    this.fingerprint,
    this.lastFailedFingerprint,
    this.approvedByUserId,
    required DateTime at,
  }) : claimEvidence = List.unmodifiable(claimEvidence),
       checks = List.unmodifiable(checks),
       at = at.toUtc() {
    if (round < 1) {
      throw ArgumentError.value(round, 'round', 'must be at least 1');
    }
    if (reviewAsks < 0) {
      throw ArgumentError.value(
        reviewAsks,
        'reviewAsks',
        'must not be negative',
      );
    }
    if (claimSummary.length > maxSummaryLength) {
      throw ArgumentError.value(
        claimSummary.length,
        'claimSummary',
        'must be at most $maxSummaryLength characters',
      );
    }
  }

  /// The longest claim summary, in characters.
  static const int maxSummaryLength = 4000;

  /// The verification round this record is (1 for the first claim).
  final int round;

  /// The agent's summary of the claim.
  final String claimSummary;

  /// The agent's evidence, per criterion.
  final List<GoalClaimEvidence> claimEvidence;

  /// What each check did, in contract order.
  final List<GoalCheckResult> checks;

  /// The reviewer's verdict; null while the review has not answered, or
  /// when a check failed and no review ran.
  final GoalVerdict? verdict;

  /// The agent that reviewed (the space's checker, or the goal's own agent).
  final String? reviewerAgentId;

  /// The reviewer's run.
  final String? reviewRunId;

  /// The wake this verification's review comes from: its `goalReview` wake,
  /// or the `limitReset` wake that asks for it again after a usage limit.
  /// Only that wake starts this verification's review; any other review
  /// wake of the goal is stale.
  final String? reviewWakeId;

  /// How many times this verification's review was asked again after a run
  /// that gave no answer of its own (a transient failure, a run lost to a
  /// restart): at most [maxReviewAsks].
  final int reviewAsks;

  /// How many times a review is asked again before the claim cannot be
  /// verified.
  static const int maxReviewAsks = 1;

  /// The worktree fingerprint the checks ran against.
  final String? fingerprint;

  /// The worktree fingerprint at the last round whose checks failed, carried
  /// into the next claim: when the worktree still has it, the checks are not
  /// rerun ([GoalCheckResult.skippedUnchanged]) and the round still counts.
  final String? lastFailedFingerprint;

  /// The person who closed the goal as done (`agentGoalRuns
  /// .approveCompletion`) instead of a passing verification; null otherwise.
  final String? approvedByUserId;

  /// When the record was last written, in UTC.
  final DateTime at;

  /// Whether every check passed (true when there are none).
  bool get checksPassed => checks.every((check) => check.passed);

  /// Whether any check could not run as written ([GoalCheckResult.broken]).
  bool get checksBroken => checks.any((check) => check.broken);

  /// Whether the reviewer was the goal's own agent ("Verified by itself").
  bool reviewedBySelf(String goalAgentId) => reviewerAgentId == goalAgentId;

  /// The stored JSON object.
  Map<String, Object?> toJson() => {
    'round': round,
    'claimSummary': claimSummary,
    'claimEvidence': [for (final e in claimEvidence) e.toJson()],
    'checks': [for (final c in checks) c.toJson()],
    'verdict': ?verdict?.toJson(),
    'reviewerAgentId': ?reviewerAgentId,
    'reviewRunId': ?reviewRunId,
    'reviewWakeId': ?reviewWakeId,
    if (reviewAsks > 0) 'reviewAsks': reviewAsks,
    'fingerprint': ?fingerprint,
    'lastFailedFingerprint': ?lastFailedFingerprint,
    'approvedByUserId': ?approvedByUserId,
    'at': at.toIso8601String(),
  };

  /// [toJson] encoded, as the column stores it.
  String encode() => jsonEncode(toJson());

  /// Rebuilds leniently: null for anything without a round and a time;
  /// malformed entries inside are dropped.
  static GoalVerification? tryFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final round = JsonSafe.intOrNull(json['round']);
    final at = JsonSafe.dateOrNull(json['at']);
    if (round == null || round < 1 || at == null) {
      return null;
    }
    final summary = json['claimSummary'];
    final text = summary is String ? summary : '';
    final evidence = json['claimEvidence'];
    final checks = json['checks'];
    try {
      return GoalVerification(
        round: round,
        claimSummary: text.length > maxSummaryLength
            ? text.substring(0, maxSummaryLength)
            : text,
        claimEvidence: [
          if (evidence is List)
            for (final e in evidence)
              if (e is Map &&
                  e['criterion'] is String &&
                  e['evidence'] is String)
                ?_evidenceOrNull(
                  e['criterion'] as String,
                  e['evidence'] as String,
                ),
        ],
        checks: [
          if (checks is List)
            for (final c in checks) ?GoalCheckResult.tryFromJson(c),
        ],
        verdict: GoalVerdict.tryFromJson(json['verdict']),
        reviewerAgentId: JsonSafe.stringOrNull(json['reviewerAgentId']),
        reviewRunId: JsonSafe.stringOrNull(json['reviewRunId']),
        reviewWakeId: JsonSafe.stringOrNull(json['reviewWakeId']),
        reviewAsks: JsonSafe.intOrNull(json['reviewAsks']) ?? 0,
        fingerprint: JsonSafe.stringOrNull(json['fingerprint']),
        lastFailedFingerprint: JsonSafe.stringOrNull(
          json['lastFailedFingerprint'],
        ),
        approvedByUserId: JsonSafe.stringOrNull(json['approvedByUserId']),
        at: at,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Decodes the stored column; null for null, empty or malformed. Never
  /// throws.
  static GoalVerification? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return tryFromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  static GoalClaimEvidence? _evidenceOrNull(String criterion, String text) {
    try {
      return GoalClaimEvidence(criterion: criterion, evidence: text);
    } on ArgumentError {
      return null;
    }
  }

  /// A copy with the given fields replaced.
  GoalVerification copyWith({
    int? round,
    String? claimSummary,
    List<GoalClaimEvidence>? claimEvidence,
    List<GoalCheckResult>? checks,
    GoalVerdict? verdict,
    bool removeVerdict = false,
    String? reviewerAgentId,
    bool removeReviewerAgentId = false,
    String? reviewRunId,
    bool removeReviewRunId = false,
    String? reviewWakeId,
    bool removeReviewWakeId = false,
    int? reviewAsks,
    String? fingerprint,
    String? lastFailedFingerprint,
    bool removeLastFailedFingerprint = false,
    String? approvedByUserId,
    DateTime? at,
  }) => GoalVerification(
    round: round ?? this.round,
    claimSummary: claimSummary ?? this.claimSummary,
    claimEvidence: claimEvidence ?? this.claimEvidence,
    checks: checks ?? this.checks,
    verdict: removeVerdict ? null : (verdict ?? this.verdict),
    reviewerAgentId: removeReviewerAgentId
        ? null
        : (reviewerAgentId ?? this.reviewerAgentId),
    reviewRunId: removeReviewRunId ? null : (reviewRunId ?? this.reviewRunId),
    reviewWakeId: removeReviewWakeId
        ? null
        : (reviewWakeId ?? this.reviewWakeId),
    reviewAsks: reviewAsks ?? this.reviewAsks,
    fingerprint: fingerprint ?? this.fingerprint,
    lastFailedFingerprint: removeLastFailedFingerprint
        ? null
        : (lastFailedFingerprint ?? this.lastFailedFingerprint),
    approvedByUserId: approvedByUserId ?? this.approvedByUserId,
    at: at ?? this.at,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalVerification &&
          round == other.round &&
          claimSummary == other.claimSummary &&
          JsonSafe.equals(claimEvidence, other.claimEvidence) &&
          JsonSafe.equals(checks, other.checks) &&
          verdict == other.verdict &&
          reviewerAgentId == other.reviewerAgentId &&
          reviewRunId == other.reviewRunId &&
          reviewWakeId == other.reviewWakeId &&
          reviewAsks == other.reviewAsks &&
          fingerprint == other.fingerprint &&
          lastFailedFingerprint == other.lastFailedFingerprint &&
          approvedByUserId == other.approvedByUserId &&
          at == other.at;

  @override
  int get hashCode => Object.hash(
    round,
    claimSummary,
    Object.hashAll(claimEvidence),
    Object.hashAll(checks),
    verdict,
    reviewerAgentId,
    reviewRunId,
    reviewWakeId,
    reviewAsks,
    fingerprint,
    lastFailedFingerprint,
    approvedByUserId,
    at,
  );

  @override
  String toString() => 'GoalVerification(${toJson()})';
}
