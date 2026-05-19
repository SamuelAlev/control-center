// The multi-axis review taxonomy (PRD 18 §7): each PR is reviewed along a set
// of independent, individually-gateable axes. Some axes are token-driven
// (reviewer agents), some are deterministic computation (no tokens at all).
//
// ignore_for_file: sort_constructors_first

/// One review axis — a specialized pass with its own findings and gate.
///
/// Token axes ([correctness], [security], [testGap]) run reviewer agents and
/// carry a per-PR budget; deterministic axes ([performance], [visual],
/// [apiContract]) run as pure computation with no token cost. See
/// [isDeterministic].
enum ReviewAxis {
  /// Bugs, regressions, logic errors. Token-driven.
  correctness,

  /// Security vulnerabilities, injection, secret leakage. Token-driven.
  security,

  /// Missing or inadequate test coverage for the change. Token-driven.
  testGap,

  /// Benchmark regressions over a threshold. Deterministic (runs benchmarks).
  performance,

  /// UI component before/after pixel regressions. Deterministic (golden
  /// harness).
  visual,

  /// OpenAPI/GraphQL contract changes with breaking-change classification.
  /// Deterministic (spec diff).
  apiContract;

  /// The stable wire/storage name.
  String get wireName {
    switch (this) {
      case ReviewAxis.correctness:
        return 'correctness';
      case ReviewAxis.security:
        return 'security';
      case ReviewAxis.testGap:
        return 'test_gap';
      case ReviewAxis.performance:
        return 'performance';
      case ReviewAxis.visual:
        return 'visual';
      case ReviewAxis.apiContract:
        return 'api_contract';
    }
  }

  /// Whether this axis is pure computation (no LLM tokens spent). Deterministic
  /// axes never draw on the per-PR review token budget.
  bool get isDeterministic {
    switch (this) {
      case ReviewAxis.performance:
      case ReviewAxis.visual:
      case ReviewAxis.apiContract:
        return true;
      case ReviewAxis.correctness:
      case ReviewAxis.security:
      case ReviewAxis.testGap:
        return false;
    }
  }

  /// Parses a stored/wire name, or null when unrecognized.
  static ReviewAxis? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final a in ReviewAxis.values) {
      if (a.wireName == name || a.name == name) {
        return a;
      }
    }
    return null;
  }
}

/// The result state of a single review axis.
///
/// The distinction between [fail], [partial] and [unavailable] is
/// load-bearing for honesty (PRD 18 adversarial notes): absence of evidence
/// must never convert to a green gate. A gated axis that is [unavailable] or
/// [partial] holds the overall verdict rather than passing it.
enum ReviewAxisVerdict {
  /// The axis ran and found nothing that blocks.
  pass,

  /// The axis ran and found non-blocking concerns.
  warn,

  /// The axis ran and found a blocking problem.
  fail,

  /// The axis ran but could not complete (e.g. token budget exhausted
  /// mid-pass). Results are incomplete; never treat as a pass.
  partial,

  /// The axis could not run at all (e.g. no Flutter SDK for [ReviewAxis.visual],
  /// no spec files for [ReviewAxis.apiContract], repo not indexed). Reported
  /// cleanly, never silently skipped.
  unavailable;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [unavailable].
  static ReviewAxisVerdict fromName(String? name) =>
      ReviewAxisVerdict.values.firstWhere(
        (v) => v.name == name,
        orElse: () => ReviewAxisVerdict.unavailable,
      );

  /// Whether this state clears a gate. Only [pass] and [warn] clear; [fail],
  /// [partial] and [unavailable] all hold.
  bool get clearsGate =>
      this == ReviewAxisVerdict.pass || this == ReviewAxisVerdict.warn;
}

/// The outcome of running one review axis over a PR.
///
/// Persisted in `review_axis_results` and aggregated by
/// `ReviewAxisAggregator` into the overall `ReviewVerdict`. When [gated] is
/// true, a non-[ReviewAxisVerdict.clearsGate] result blocks the merge gate.
class ReviewAxisResult {
  /// Creates a [ReviewAxisResult].
  const ReviewAxisResult({
    required this.axis,
    required this.verdict,
    required this.findingsCount,
    required this.gated,
    required this.confidence,
    this.note = '',
  }) : assert(
         confidence >= 0.0 && confidence <= 1.0,
         'confidence must be in [0, 1]',
       ),
       assert(findingsCount >= 0, 'findingsCount must be non-negative');

  /// Which axis this result is for.
  final ReviewAxis axis;

  /// The axis verdict.
  final ReviewAxisVerdict verdict;

  /// Number of findings this axis produced.
  final int findingsCount;

  /// Whether this axis participates in the merge gate. A gated axis that does
  /// not [ReviewAxisVerdict.clearsGate] blocks the overall verdict.
  final bool gated;

  /// Confidence in the axis result itself, clamped to `[0, 1]`.
  final double confidence;

  /// Human-readable qualifier, e.g. `"partial — budget exhausted"` or
  /// `"unavailable — no Flutter SDK on host"`. Empty when unremarkable.
  final String note;

  /// Whether this axis blocks the merge (gated and not clearing).
  bool get blocks => gated && !verdict.clearsGate;

  /// Builds from a stored map.
  factory ReviewAxisResult.fromJson(Map<String, dynamic> json) =>
      ReviewAxisResult(
        axis:
            ReviewAxis.fromName(json['axis'] as String?) ??
            ReviewAxis.correctness,
        verdict: ReviewAxisVerdict.fromName(json['verdict'] as String?),
        findingsCount: (json['findingsCount'] as num?)?.toInt() ?? 0,
        gated: json['gated'] as bool? ?? false,
        confidence: ((json['confidence'] as num?)?.toDouble() ?? 1.0).clamp(
          0.0,
          1.0,
        ),
        note: json['note'] as String? ?? '',
      );

  /// Serializes to a stored map.
  Map<String, dynamic> toJson() => {
    'axis': axis.wireName,
    'verdict': verdict.wireName,
    'findingsCount': findingsCount,
    'gated': gated,
    'confidence': confidence,
    if (note.isNotEmpty) 'note': note,
  };

  /// Returns an edited copy.
  ReviewAxisResult copyWith({
    ReviewAxisVerdict? verdict,
    int? findingsCount,
    bool? gated,
    double? confidence,
    String? note,
  }) => ReviewAxisResult(
    axis: axis,
    verdict: verdict ?? this.verdict,
    findingsCount: findingsCount ?? this.findingsCount,
    gated: gated ?? this.gated,
    confidence: confidence ?? this.confidence,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewAxisResult &&
          runtimeType == other.runtimeType &&
          axis == other.axis &&
          verdict == other.verdict &&
          findingsCount == other.findingsCount &&
          gated == other.gated &&
          confidence == other.confidence &&
          note == other.note;

  @override
  int get hashCode =>
      Object.hash(axis, verdict, findingsCount, gated, confidence, note);
}
