import 'dart:math' as math;

/// A rolling-window distribution of a single agent×config's recent behaviour
/// (PRD 21 §8). Compared against a baseline window to catch silent drift —
/// behaviour shifting without a config change (e.g. an upstream model update).
class DriftWindow {
  /// Creates a [DriftWindow].
  const DriftWindow({
    required this.costs,
    required this.turnCounts,
    required this.failureFamilyCounts,
  });

  /// Per-run cost samples (cents).
  final List<double> costs;

  /// Per-run turn-count samples.
  final List<double> turnCounts;

  /// Failure-family → count over the window.
  final Map<String, int> failureFamilyCounts;

  /// Number of runs in the window.
  int get sampleCount => costs.length;
}

/// One dimension that shifted between baseline and recent windows.
class DriftShift {
  /// Creates a [DriftShift].
  const DriftShift({
    required this.dimension,
    required this.baselineValue,
    required this.recentValue,
    required this.deltaPct,
    required this.note,
  });

  /// The dimension name (`cost`/`turns`/`failure_mix`).
  final String dimension;

  /// Baseline central value.
  final double baselineValue;

  /// Recent central value.
  final double recentValue;

  /// Relative change (recent−baseline)/baseline, as a fraction.
  final double deltaPct;

  /// Human-readable note (shown in the drift alarm evidence).
  final String note;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'dimension': dimension,
    'baselineValue': baselineValue,
    'recentValue': recentValue,
    'deltaPct': deltaPct,
    'note': note,
  };
}

/// The verdict of a drift comparison.
class DriftVerdict {
  /// Creates a [DriftVerdict].
  const DriftVerdict({required this.drifted, required this.shifts});

  /// Whether any dimension drifted beyond threshold.
  final bool drifted;

  /// The dimensions that shifted (empty when not drifted).
  final List<DriftShift> shifts;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'drifted': drifted,
    'shifts': shifts.map((s) => s.toJson()).toList(),
  };
}

/// Compares behaviour distributions over trailing windows to fire drift alarms
/// (PRD 21 §8). Pure and deterministic — never single-run outliers: both
/// windows must have a minimum sample count, and a shift must exceed a relative
/// threshold to count.
class DriftDetector {
  /// Creates a [DriftDetector].
  const DriftDetector({
    this.minSamples = 10,
    this.costThresholdPct = 0.4,
    this.turnThresholdPct = 0.4,
    this.failureMixThreshold = 0.25,
  });

  /// Minimum samples required in each window to compare at all.
  final int minSamples;

  /// Relative cost-mean shift that counts as drift.
  final double costThresholdPct;

  /// Relative turn-count-mean shift that counts as drift.
  final double turnThresholdPct;

  /// Failure-rate absolute shift (fraction) that counts as drift.
  final double failureMixThreshold;

  /// Compares [recent] against [baseline]. Returns a [DriftVerdict] whose
  /// [DriftVerdict.drifted] is true when any dimension shifted beyond its
  /// threshold. Insufficient samples → not drifted (never a false alarm).
  DriftVerdict compare(DriftWindow baseline, DriftWindow recent) {
    if (baseline.sampleCount < minSamples || recent.sampleCount < minSamples) {
      return const DriftVerdict(drifted: false, shifts: []);
    }
    final shifts = <DriftShift>[];

    _checkMean(
      shifts,
      dimension: 'cost',
      baseline: baseline.costs,
      recent: recent.costs,
      thresholdPct: costThresholdPct,
      unit: '¢',
    );
    _checkMean(
      shifts,
      dimension: 'turns',
      baseline: baseline.turnCounts,
      recent: recent.turnCounts,
      thresholdPct: turnThresholdPct,
      unit: ' turns',
    );

    // Failure-family mix: compare the overall failure rate.
    final baseFail = _failureRate(baseline);
    final recentFail = _failureRate(recent);
    if ((recentFail - baseFail).abs() >= failureMixThreshold) {
      shifts.add(
        DriftShift(
          dimension: 'failure_mix',
          baselineValue: baseFail,
          recentValue: recentFail,
          deltaPct: baseFail == 0 ? 1 : (recentFail - baseFail) / baseFail,
          note:
              'Failure rate ${(baseFail * 100).round()}% → '
              '${(recentFail * 100).round()}%.',
        ),
      );
    }

    return DriftVerdict(drifted: shifts.isNotEmpty, shifts: shifts);
  }

  void _checkMean(
    List<DriftShift> shifts, {
    required String dimension,
    required List<double> baseline,
    required List<double> recent,
    required double thresholdPct,
    required String unit,
  }) {
    final b = _mean(baseline);
    final r = _mean(recent);
    if (b == 0) {
      // A rise from a zero baseline is an unbounded relative shift with no
      // percentage fallback — flag it directly (this IS the "silent upstream
      // drift" case the alarm exists for; e.g. cost 0¢ → 50¢).
      if (r != 0) {
        shifts.add(
          DriftShift(
            dimension: dimension,
            baselineValue: 0,
            recentValue: r,
            deltaPct: 1,
            note: '0$unit → ${r.toStringAsFixed(1)}$unit (up from zero).',
          ),
        );
      }
      return;
    }
    final delta = (r - b) / b;
    if (delta.abs() >= thresholdPct) {
      shifts.add(
        DriftShift(
          dimension: dimension,
          baselineValue: b,
          recentValue: r,
          deltaPct: delta,
          note:
              '${b.toStringAsFixed(1)}$unit → ${r.toStringAsFixed(1)}$unit '
              '(${(delta * 100).round()}%).',
        ),
      );
    }
  }

  double _failureRate(DriftWindow w) {
    final failures = w.failureFamilyCounts.values.fold<int>(0, (a, b) => a + b);
    final total = math.max(w.sampleCount, failures);
    return total == 0 ? 0 : failures / total;
  }

  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
}
