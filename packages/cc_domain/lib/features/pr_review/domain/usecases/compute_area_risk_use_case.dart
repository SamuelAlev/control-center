// Per-area review risk/effort scoring (PRD 18 §6), deterministic and
// explainable.
//
// A single opaque "risk: 7/10" is not actionable and not trusted. This returns
// the FACTORS that produced the number, so the reviewer can see that the score
// is high because the area touches `payment/` and breaks two API contracts —
// not because a model felt uneasy.
//
// Pure arithmetic: no LLM, no I/O. Every input is something another
// deterministic pass already computed.

import 'package:cc_domain/features/pr_review/domain/value_objects/change_path_heuristics.dart';

/// Coarse risk band for badge rendering.
enum AreaRiskLevel {
  /// Routine change.
  low,

  /// Worth a careful pass.
  moderate,

  /// Read this area first.
  high;

  /// The stable wire name.
  String get wireName => name;
}

/// Stable identifiers for risk factors. The UI maps these to localized labels,
/// so the domain never carries display text.
abstract final class AreaRiskFactorIds {
  /// Lines changed in the area.
  static const linesChanged = 'linesChanged';

  /// Number of files in the area.
  static const fileCount = 'fileCount';

  /// Transitive dependents of the area's symbols.
  static const impact = 'impact';

  /// Blocking-priority findings in the area.
  static const blockingFindings = 'blockingFindings';

  /// Files on a critical path (auth, payment, migration, …).
  static const criticalPath = 'criticalPath';

  /// Breaking API-contract changes.
  static const contractBreaking = 'contractBreaking';

  /// Visual regression magnitude.
  static const visualChange = 'visualChange';

  /// Added/removed/upgraded dependencies.
  static const dependencyChurn = 'dependencyChurn';

  /// Known-zero covering tests.
  static const noCoveringTests = 'noCoveringTests';
}

/// The inputs to [ComputeAreaRiskUseCase].
class AreaRiskInput {
  /// Creates an [AreaRiskInput].
  const AreaRiskInput({
    this.locChanged = 0,
    this.fileCount = 0,
    this.impactScore = 0,
    this.p0Count = 0,
    this.p1Count = 0,
    this.filePaths = const [],
    this.contractBreakingCount = 0,
    this.visualChangedPercentMax = 0,
    this.dependencyChurn = 0,
    this.coveringTestCount,
  });

  /// Added + removed lines across the area's files.
  final int locChanged;

  /// Files in the area.
  final int fileCount;

  /// The cohort's impact weight (transitively affected symbols).
  final int impactScore;

  /// P0 findings routed into the area.
  final int p0Count;

  /// P1 findings routed into the area.
  final int p1Count;

  /// The area's files, used for the critical-path factor.
  final List<String> filePaths;

  /// Breaking API-contract changes in the area's spec files.
  final int contractBreakingCount;

  /// Largest visual diff percentage among the area's components, 0..100.
  final double visualChangedPercentMax;

  /// Added + removed + upgraded dependency count for the area's lockfiles.
  final int dependencyChurn;

  /// Test files covering the area's symbols.
  ///
  /// **Null means unknown** (repo not indexed), which contributes nothing in
  /// either direction. Zero means known-zero, which is a real risk signal. The
  /// two must never collapse: "we could not tell" is not "there are no tests".
  final int? coveringTestCount;
}

/// One named contribution to an area's risk score.
class AreaRiskFactor {
  /// Creates an [AreaRiskFactor].
  const AreaRiskFactor({
    required this.id,
    required this.value,
    required this.contribution,
  });

  /// One of [AreaRiskFactorIds].
  final String id;

  /// The raw measured value behind the contribution (shown next to the label).
  final num value;

  /// Points this factor added to the score.
  final int contribution;
}

/// An area's risk score with its full derivation.
class AreaRisk {
  /// Creates an [AreaRisk].
  const AreaRisk({
    required this.score,
    required this.level,
    required this.factors,
  });

  /// 0..100 composite score.
  final int score;

  /// The band [score] falls in.
  final AreaRiskLevel level;

  /// The contributing factors, largest contribution first. Only factors that
  /// actually contributed are present.
  final List<AreaRiskFactor> factors;

  /// Whether nothing measurable contributed.
  bool get isEmpty => factors.isEmpty;
}

/// Computes an area's deterministic risk/effort score.
class ComputeAreaRiskUseCase {
  /// Creates a [ComputeAreaRiskUseCase].
  const ComputeAreaRiskUseCase();

  // Weights are documented rather than tuned: each cap is the point past which
  // more of the same signal stops changing how carefully a human should read.
  static const _locCap = 20;
  static const _fileCap = 10;
  static const _impactCap = 15;
  static const _findingCap = 25;
  static const _criticalCap = 15;
  static const _contractCap = 15;
  static const _visualCap = 10;
  static const _depCap = 10;
  static const _noTestsPoints = 10;

  /// Scores [input].
  AreaRisk execute(AreaRiskInput input) {
    final factors = <AreaRiskFactor>[];

    void add(String id, num value, int contribution) {
      if (contribution <= 0 || value <= 0) {
        return;
      }
      factors.add(
        AreaRiskFactor(id: id, value: value, contribution: contribution),
      );
    }

    // Size: 200 changed lines saturates. A 2000-line area is not 10x riskier
    // to read than a 200-line one — it is just long.
    add(
      AreaRiskFactorIds.linesChanged,
      input.locChanged,
      _scaled(input.locChanged, 200, _locCap),
    );
    add(
      AreaRiskFactorIds.fileCount,
      input.fileCount,
      _scaled(input.fileCount, 12, _fileCap),
    );
    add(
      AreaRiskFactorIds.impact,
      input.impactScore,
      _scaled(input.impactScore, 40, _impactCap),
    );

    // Findings: a P0 is worth far more than a P1.
    final findingPoints = (input.p0Count * 12 + input.p1Count * 5).clamp(
      0,
      _findingCap,
    );
    add(
      AreaRiskFactorIds.blockingFindings,
      input.p0Count + input.p1Count,
      findingPoints,
    );

    final criticalHits = input.filePaths.where(isCriticalPath).length;
    add(
      AreaRiskFactorIds.criticalPath,
      criticalHits,
      _scaled(criticalHits, 3, _criticalCap),
    );

    add(
      AreaRiskFactorIds.contractBreaking,
      input.contractBreakingCount,
      _scaled(input.contractBreakingCount, 2, _contractCap),
    );
    add(
      AreaRiskFactorIds.visualChange,
      input.visualChangedPercentMax,
      _scaled(input.visualChangedPercentMax.round(), 25, _visualCap),
    );
    add(
      AreaRiskFactorIds.dependencyChurn,
      input.dependencyChurn,
      _scaled(input.dependencyChurn, 15, _depCap),
    );

    // Known-zero coverage only. `null` (unknown) contributes nothing — absence
    // of evidence must not move the score in either direction.
    final covering = input.coveringTestCount;
    if (covering != null && covering == 0 && input.locChanged > 0) {
      factors.add(
        const AreaRiskFactor(
          id: AreaRiskFactorIds.noCoveringTests,
          value: 0,
          contribution: _noTestsPoints,
        ),
      );
    }

    final score = factors
        .fold<int>(0, (sum, f) => sum + f.contribution)
        .clamp(0, 100);
    factors.sort((a, b) => b.contribution.compareTo(a.contribution));

    return AreaRisk(score: score, level: _levelFor(score), factors: factors);
  }

  /// Linear ramp of [value] toward [saturation], capped at [cap] points.
  int _scaled(num value, num saturation, int cap) {
    if (value <= 0) {
      return 0;
    }
    final ratio = value / saturation;
    final points = (ratio * cap).round();
    return points.clamp(0, cap);
  }

  AreaRiskLevel _levelFor(int score) {
    if (score >= 55) {
      return AreaRiskLevel.high;
    }
    if (score >= 25) {
      return AreaRiskLevel.moderate;
    }
    return AreaRiskLevel.low;
  }
}
