import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/ci_log_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_host/cc_host.dart';

/// One failing CI job, reduced to what a reviewer can act on.
class CiJobSignals {
  /// Creates a [CiJobSignals].
  const CiJobSignals({
    required this.name,
    required this.conclusion,
    this.htmlUrl = '',
    this.failingTests = const [],
    this.errorLines = const [],
    this.correlations = const [],
    this.logsPublished = true,
  });

  /// The job/check name.
  final String name;

  /// Its conclusion wire name (`failure`, `timed_out`, …).
  final String conclusion;

  /// Link to the run on the forge.
  final String htmlUrl;

  /// Test names the log reported as failing.
  final List<String> failingTests;

  /// Error lines the log reported.
  final List<String> errorLines;

  /// Frames matched onto the PR's own changed files.
  final List<CiFileCorrelation> correlations;

  /// Whether the forge served the job's logs.
  ///
  /// False is a real state, not an error: logs expire, and a run still in
  /// progress has none. The UI says "logs not published" rather than
  /// "no failures found", which would be a different and untrue claim.
  final bool logsPublished;

  /// Serializes to the RPC wire shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    'conclusion': conclusion,
    if (htmlUrl.isNotEmpty) 'html_url': htmlUrl,
    'failing_tests': failingTests,
    'error_lines': errorLines,
    'logs_published': logsPublished,
    'correlations': [for (final c in correlations) c.toJson()],
  };
}

/// A CI frame matched to one of the PR's changed files.
class CiFileCorrelation {
  /// Creates a [CiFileCorrelation].
  const CiFileCorrelation({
    required this.filePath,
    this.line,
    this.evidence = '',
    this.cohortKey,
  });

  /// The PR's changed file (repository-relative).
  final String filePath;

  /// Line the log named, when it named one.
  final int? line;

  /// The failing test or error line that produced the match.
  final String evidence;

  /// The review area the file belongs to, when it belongs to one.
  final String? cohortKey;

  /// Serializes to the RPC wire shape.
  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    if (line != null) 'line': line,
    if (evidence.isNotEmpty) 'evidence': evidence,
    if (cohortKey != null) 'cohort_key': cohortKey,
  };
}

/// The whole CI picture for a PR.
class PrCiSignals {
  /// Creates a [PrCiSignals].
  const PrCiSignals({
    required this.available,
    this.jobs = const [],
    this.failingCount = 0,
    this.note = '',
  });

  /// Whether this forge can serve per-job detail at all.
  ///
  /// A forge without `ciJobDetail` has no story here, and the UI hides the
  /// panel rather than showing an empty one — an affordance a forge
  /// structurally cannot have is not "temporarily unavailable".
  final bool available;

  /// Per failing job.
  final List<CiJobSignals> jobs;

  /// How many checks are failing (including ones with no readable logs).
  final int failingCount;

  /// Human-readable qualifier for a degraded result.
  final String note;

  /// Serializes to the RPC wire shape.
  Map<String, dynamic> toJson() => {
    'available': available,
    'failing_count': failingCount,
    if (note.isNotEmpty) 'note': note,
    'jobs': [for (final j in jobs) j.toJson()],
  };
}

/// Reads a PR's failing CI jobs and turns their logs into review signals.
///
/// Deliberately parasitic on data the PR page already fetches: the same
/// `listCheckRuns` / `getJobRunDetail` calls behind the checks tab. The logs
/// have been sitting there unparsed — this is the cheapest deterministic
/// signal available, because it costs no new forge surface at all.
class ReviewCiSignalService {
  /// Creates a [ReviewCiSignalService].
  const ReviewCiSignalService({
    this.parser = const CiLogParser(),
    this.maxJobs = 5,
  });

  /// The log parser.
  final CiLogParser parser;

  /// How many failing jobs to fetch detail for.
  ///
  /// A matrix build can fail 40 ways for one reason; reading five of them
  /// finds that reason, and reading forty just costs forty round-trips.
  final int maxJobs;

  /// Computes the CI signals for [prNumber].
  ///
  /// [repository] is the PR's forge-resolved repository — the same one the
  /// checks tab reads, so this adds no forge surface. [supportsJobDetail] is
  /// the forge's static `ciJobDetail` capability.
  Future<PrCiSignals> compute({
    required PrReviewRepository repository,
    required int prNumber,
    required List<String> changedFiles,
    required List<ReviewCohort> cohorts,
    bool supportsJobDetail = true,
  }) async {
    if (!supportsJobDetail) {
      return const PrCiSignals(available: false);
    }

    List<CheckRun> checks;
    try {
      checks = await repository.watchCheckRuns(prNumber).first;
    } on Object catch (e) {
      CcHostLog.warning('review_ci: check runs could not be read: $e');
      return const PrCiSignals(
        available: true,
        note: 'checks could not be read',
      );
    }

    final failing = [
      for (final c in checks)
        if (c.isFailing) c,
    ];
    if (failing.isEmpty) {
      return const PrCiSignals(available: true);
    }

    final cohortByFile = <String, String>{};
    for (final c in cohorts) {
      for (final path in c.filePaths) {
        cohortByFile.putIfAbsent(path, () => c.cohortKey);
      }
    }

    final jobs = <CiJobSignals>[];
    for (final check in failing.take(maxJobs)) {
      final jobId = check.jobId;
      final conclusion = check.conclusion?.name ?? 'failure';
      if (jobId == null) {
        jobs.add(
          CiJobSignals(
            name: check.name,
            conclusion: conclusion,
            htmlUrl: check.htmlUrl,
            logsPublished: false,
          ),
        );
        continue;
      }
      String? logs;
      try {
        final detail = await repository.getJobRunDetail(jobId);
        logs = detail?.logs;
      } on Object catch (e) {
        CcHostLog.warning('review_ci: job $jobId detail failed: $e');
      }
      if (logs == null || logs.isEmpty) {
        jobs.add(
          CiJobSignals(
            name: check.name,
            conclusion: conclusion,
            htmlUrl: check.htmlUrl,
            logsPublished: false,
          ),
        );
        continue;
      }
      final signals = parser.parse(logs);
      final correlations = parser.correlate(signals, changedFiles);
      jobs.add(
        CiJobSignals(
          name: check.name,
          conclusion: conclusion,
          htmlUrl: check.htmlUrl,
          failingTests: signals.failingTests,
          errorLines: signals.errorLines,
          correlations: [
            for (final c in correlations)
              CiFileCorrelation(
                filePath: c.filePath,
                line: c.line,
                evidence: c.evidence,
                cohortKey: cohortByFile[c.filePath],
              ),
          ],
        ),
      );
    }

    final dropped = failing.length - jobs.length;
    return PrCiSignals(
      available: true,
      failingCount: failing.length,
      jobs: jobs,
      note: dropped > 0 ? '$dropped further failing job(s) not read' : '',
    );
  }

  /// The advisory correctness-axis note for [signals], or empty when there is
  /// nothing honest to say.
  ///
  /// Advisory only. A failing test is strong evidence but the correlation is a
  /// path-suffix heuristic, so it annotates the axis rather than moving a gate.
  String correctnessNote(PrCiSignals signals) {
    if (!signals.available || signals.failingCount == 0) {
      return '';
    }
    for (final job in signals.jobs) {
      for (final c in job.correlations) {
        final test = c.evidence.isEmpty ? job.name : c.evidence;
        return 'CI failure "$test" points at ${c.filePath}';
      }
    }
    return '${signals.failingCount} CI check(s) failing';
  }
}
