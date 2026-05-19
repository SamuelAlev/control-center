import 'dart:math' as math;

/// Outcome of a single benchmark trial (one task attempt).
///
/// A trial is [running] while in flight, resolves to [pass] when the verifier
/// awards full reward, [fail] when it scores below the pass threshold, and
/// [error] when the harness itself faults (setup crash, timeout, parse error)
/// rather than the agent producing a wrong answer.
enum TrialStatus {
  /// The trial completed and met the pass threshold.
  pass,

  /// The trial completed but scored below the pass threshold.
  fail,

  /// The harness faulted before a reward could be assigned.
  error,

  /// The trial is still in flight.
  running,
}

/// An immutable record of one benchmark trial: its task name, resolved
/// [status], verifier [reward], and the resource cost it incurred.
///
/// A trial is considered [passed] only when [reward] is non-null and at least
/// `1 - _passEpsilon`, so floating-point rewards that round to 1.0 (for
/// example `0.9999999999`) still count as a pass.
class BenchmarkTrial {
  /// Creates a [BenchmarkTrial].
  const BenchmarkTrial({
    required this.name,
    required this.status,
    this.reward,
    this.costCents = 0,
    this.advisorCostCents = 0,
    this.tokIn = 0,
    this.tokOut = 0,
    this.tokCache = 0,
    this.durationMs = 0,
    this.detail = '',
  });

  /// Name of the task this trial ran.
  final String name;

  /// Resolved status of the trial.
  final TrialStatus status;

  /// Verifier reward in `[0, 1]`, or null while the trial is unresolved.
  final double? reward;

  /// Cost of the main agent for this trial, in US cents.
  final int costCents;

  /// Cost of any advisor / sub-agent calls for this trial, in US cents.
  final int advisorCostCents;

  /// Input tokens consumed by this trial.
  final int tokIn;

  /// Output tokens produced by this trial.
  final int tokOut;

  /// Cache-hit tokens (read + write) for this trial.
  final int tokCache;

  /// Wall-clock duration of this trial, in milliseconds.
  final int durationMs;

  /// Free-form detail (error message, verifier note) for this trial.
  final String detail;

  /// Tolerance applied to the [reward] pass comparison so that rewards that
  /// round to 1.0 in floating point still count as a pass.
  static const _passEpsilon = 1e-9;

  /// Whether this trial met the pass threshold.
  ///
  /// True only when [reward] is non-null and at least `1 - _passEpsilon`.
  bool get passed => reward != null && reward! >= 1 - _passEpsilon;

  /// Returns a copy of this trial with the given fields replaced.
  BenchmarkTrial copyWith({
    String? name,
    TrialStatus? status,
    double? reward,
    int? costCents,
    int? advisorCostCents,
    int? tokIn,
    int? tokOut,
    int? tokCache,
    int? durationMs,
    String? detail,
  }) {
    return BenchmarkTrial(
      name: name ?? this.name,
      status: status ?? this.status,
      reward: reward ?? this.reward,
      costCents: costCents ?? this.costCents,
      advisorCostCents: advisorCostCents ?? this.advisorCostCents,
      tokIn: tokIn ?? this.tokIn,
      tokOut: tokOut ?? this.tokOut,
      tokCache: tokCache ?? this.tokCache,
      durationMs: durationMs ?? this.durationMs,
      detail: detail ?? this.detail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkTrial &&
          name == other.name &&
          status == other.status &&
          reward == other.reward &&
          costCents == other.costCents &&
          advisorCostCents == other.advisorCostCents &&
          tokIn == other.tokIn &&
          tokOut == other.tokOut &&
          tokCache == other.tokCache &&
          durationMs == other.durationMs &&
          detail == other.detail;

  @override
  int get hashCode => Object.hash(
    name,
    status,
    reward,
    costCents,
    advisorCostCents,
    tokIn,
    tokOut,
    tokCache,
    durationMs,
    detail,
  );
}

/// An immutable snapshot of one benchmark run: its [dataset], the [trials]
/// observed so far, and the [expectedTotal] number of trials the run will
/// eventually contain.
///
/// Counts are derived live from [trials], so a run can be inspected while still
/// in progress: resolved trials contribute to [passCount] / [failCount] /
/// [errorCount], in-flight ones to [runningCount], and the difference between
/// [expectedTotal] and the work seen so far is reported as [pendingCount].
class BenchmarkRun {
  /// Creates a [BenchmarkRun].
  const BenchmarkRun({
    required this.id,
    required this.dataset,
    required this.trials,
    required this.expectedTotal,
    required this.startedAt,
    this.finishedAt,
  });

  /// Stable identifier for this run.
  final String id;

  /// Name of the dataset / benchmark this run executed.
  final String dataset;

  /// Trials observed so far, in execution order.
  final List<BenchmarkTrial> trials;

  /// Total number of trials this run is expected to contain when complete.
  final int expectedTotal;

  /// When this run started.
  final DateTime startedAt;

  /// When this run finished, or null while still in progress.
  final DateTime? finishedAt;

  /// Number of resolved trials (pass, fail, or error).
  int get done => trials
      .where(
        (t) =>
            t.status == TrialStatus.pass ||
            t.status == TrialStatus.fail ||
            t.status == TrialStatus.error,
      )
      .length;

  /// Number of trials that passed.
  int get passCount => trials.where((t) => t.status == TrialStatus.pass).length;

  /// Number of trials that failed.
  int get failCount => trials.where((t) => t.status == TrialStatus.fail).length;

  /// Number of trials that errored in the harness.
  int get errorCount =>
      trials.where((t) => t.status == TrialStatus.error).length;

  /// Number of trials currently in flight.
  int get runningCount =>
      trials.where((t) => t.status == TrialStatus.running).length;

  /// Number of trials not yet started, clamped to be non-negative.
  ///
  /// This is the expected total minus the work already seen ([done] plus
  /// [runningCount]); it never goes below zero even if more trials than
  /// expected are observed.
  int get pendingCount => math.max(0, expectedTotal - done - runningCount);

  /// Total main-agent cost across all trials, in US cents.
  int get totalCostCents => trials.fold(0, (sum, t) => sum + t.costCents);

  /// Total advisor / sub-agent cost across all trials, in US cents.
  int get totalAdvisorCostCents =>
      trials.fold(0, (sum, t) => sum + t.advisorCostCents);

  /// Total input tokens across all trials.
  int get totalTokIn => trials.fold(0, (sum, t) => sum + t.tokIn);

  /// Total output tokens across all trials.
  int get totalTokOut => trials.fold(0, (sum, t) => sum + t.tokOut);

  /// Total cache-hit tokens across all trials.
  int get totalTokCache => trials.fold(0, (sum, t) => sum + t.tokCache);

  /// Percentage of resolved trials that passed (`0` when none are resolved).
  double get successPct => done > 0 ? passCount / done * 100 : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkRun &&
          id == other.id &&
          dataset == other.dataset &&
          _listEquals(trials, other.trials) &&
          expectedTotal == other.expectedTotal &&
          startedAt == other.startedAt &&
          finishedAt == other.finishedAt;

  @override
  int get hashCode => Object.hash(
    id,
    dataset,
    Object.hashAll(trials),
    expectedTotal,
    startedAt,
    finishedAt,
  );

  static bool _listEquals(List<BenchmarkTrial> a, List<BenchmarkTrial> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Pure scoring helpers over a [BenchmarkRun]: pass rate, ETA, and a markdown
/// report. Holds no state and reads nothing outside the run it is given.
class BenchmarkScorer {
  /// Creates a [BenchmarkScorer].
  const BenchmarkScorer();

  /// The pass@1 success rate of [run] (`passCount / done`), or `0` when no
  /// trials have resolved.
  ///
  /// This is the single-attempt pass rate. A true multi-attempt pass@k would
  /// require grouping repeated attempts of the same task and counting a task as
  /// solved if any attempt passed; that grouping is intentionally out of scope
  /// here, so this reports the simple k=1 rate.
  double passAtK(BenchmarkRun run) {
    final done = run.done;
    return done > 0 ? run.passCount / done : 0;
  }

  /// Estimates the time remaining for [run] given the current wall clock [now].
  ///
  /// Extrapolates from the average time per resolved trial
  /// (`elapsed / done`) over the trials still outstanding
  /// (`expectedTotal - done`). Returns [Duration.zero] when nothing has
  /// resolved yet (no rate to project from) or when the run is already
  /// complete (`done >= expectedTotal`).
  Duration etaFrom(BenchmarkRun run, DateTime now) {
    final done = run.done;
    if (done <= 0 || done >= run.expectedTotal) {
      return Duration.zero;
    }
    final elapsedMs = now.difference(run.startedAt).inMilliseconds;
    final remaining = run.expectedTotal - done;
    final etaMs = (elapsedMs / done * remaining).round();
    return Duration(milliseconds: etaMs);
  }

  /// Renders [run] as a markdown report: a per-trial table followed by a
  /// summary line and a tokens line.
  ///
  /// The table header is
  /// `| task | result | reward | cost | duration | detail |`, each trial
  /// contributes one row (status icon ✅ / ❌ / ⚠️ / ⏳, reward to two decimals
  /// or `—`, cost as `$X.XX`, duration as `m:ss` or `X.Xs`), and the trailing
  /// summary reads `**N/M passed (P%)** · fail F · error E · spend $C`.
  String markdownReport(BenchmarkRun run) {
    final buffer = StringBuffer()
      ..writeln('| task | result | reward | cost | duration | detail |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');

    for (final trial in run.trials) {
      final reward = trial.reward != null
          ? trial.reward!.toStringAsFixed(2)
          : '—';
      final cost = _formatCents(trial.costCents);
      final duration = _formatDuration(trial.durationMs);
      final detail = _escapeCell(trial.detail);
      buffer.writeln(
        '| ${_escapeCell(trial.name)} | ${_statusIcon(trial.status)} '
        '| $reward | $cost | $duration | $detail |',
      );
    }

    final pct = run.successPct.toStringAsFixed(0);
    final spend = _formatCents(run.totalCostCents + run.totalAdvisorCostCents);
    buffer
      ..writeln()
      ..writeln(
        '**${run.passCount}/${run.done} passed ($pct%)** · '
        'fail ${run.failCount} · error ${run.errorCount} · spend $spend',
      )
      ..writeln(
        'tokens: in ${run.totalTokIn} · out ${run.totalTokOut} · '
        'cache ${run.totalTokCache}',
      );

    return buffer.toString();
  }

  /// The status icon used in the markdown table.
  static String _statusIcon(TrialStatus status) => switch (status) {
    TrialStatus.pass => '✅',
    TrialStatus.fail => '❌',
    TrialStatus.error => '⚠️',
    TrialStatus.running => '⏳',
  };

  /// Formats an integer US-cent amount as `$X.XX`.
  static String _formatCents(int cents) =>
      '\$${(cents / 100).toStringAsFixed(2)}';

  /// Formats a millisecond duration as `m:ss` (>= 1 minute) or `X.Xs`.
  static String _formatDuration(int ms) {
    final seconds = ms / 1000;
    if (seconds >= 60) {
      final minutes = ms ~/ 60000;
      final remSeconds = (ms % 60000) ~/ 1000;
      return '$minutes:${remSeconds.toString().padLeft(2, '0')}';
    }
    return '${seconds.toStringAsFixed(1)}s';
  }

  /// Escapes a cell value so embedded pipes and newlines do not break the
  /// markdown table layout.
  static String _escapeCell(String value) =>
      value.replaceAll('\n', ' ').replaceAll('|', r'\|');
}
