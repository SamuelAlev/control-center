import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';

/// Publishes a background [CodeIndexer] run somewhere an operator can see it.
///
/// Indexing is the one background job on this server that takes real time (it
/// enumerates and hashes every source file, parses the changed ones and embeds
/// their symbols) and until now it was visible only in the server log. A run
/// that pins a core for a minute has to be attributable from the UI and the UI
/// already has exactly one place where long-running work lives: the pipeline
/// runs table. Every OTHER caller of the indexer — the `index_code` template,
/// manual or on `RepoAdded` — is already a pipeline run; this port is what lets
/// the watcher's runs join them without teaching the watcher what a pipeline is.
///
/// The implementation is expected to be lossy, never load-bearing: the indexer
/// must run identically when no reporter is wired and a reporting failure must
/// never fail the index.
abstract class CodeIndexRunReporter {
  /// Opens a report for one about-to-start index of a checkout.
  ///
  /// Deliberately cheap and non-committal — it writes nothing. Most background
  /// runs turn out to have no work at all (the checkpoint short-circuits, or
  /// every hash matches) and a row per fire would bury the runs table in
  /// no-ops. The handle materializes on the first thing worth reporting.
  ///
  /// [cause] is what the run is ATTRIBUTED to, and it exists because without it
  /// a published run is unattributable: the runs table showed dozens of
  /// identical `index_code` rows a minute apart with nothing to distinguish
  /// them, and the answer ("you saved a file") lived only in a filesystem event
  /// the service had already discarded.
  CodeIndexRun begin({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    CodeIndexCause cause = const CodeIndexCause.initial(),
  });
}

/// What a background index run is attributed to.
enum CodeIndexCauseKind {
  /// The arm-time pass a checkout gets when the watcher first picks it up (or
  /// a reconcile sweep re-arms it). Nothing changed; this is the baseline.
  initial,

  /// Files changed but WHICH ones is unknown — a watcher queue overflow or a
  /// kernel rescan hint. Honest about it rather than reporting an empty list,
  /// which would read as "nothing changed".
  rescan,

  /// One or more source files changed. [CodeIndexCause.paths] names them.
  changes,
}

/// Why a background index run fired, in a form a run row can render.
///
/// Paths are repo-RELATIVE and CAPPED at [maxPaths]: a `git checkout` across a
/// branch touches thousands of files and the point of this is to answer "why is
/// this running", which the first handful answers as well as all of them.
/// [totalChanged] keeps the real count so the UI can say "+2481 more" instead
/// of quietly implying the cap was the whole set.
class CodeIndexCause {
  /// A run nothing triggered — the arm-time or reconcile pass.
  const CodeIndexCause.initial()
    : kind = CodeIndexCauseKind.initial,
      paths = const [],
      totalChanged = 0;

  /// A run triggered by changes whose paths were lost.
  const CodeIndexCause.rescan()
    : kind = CodeIndexCauseKind.rescan,
      paths = const [],
      totalChanged = 0;

  /// A run triggered by [paths] changing, out of [totalChanged] in total.
  const CodeIndexCause.changes(this.paths, {required this.totalChanged})
    : kind = CodeIndexCauseKind.changes;

  /// How many paths a cause carries before it starts counting instead.
  static const int maxPaths = 8;

  /// What triggered the run.
  final CodeIndexCauseKind kind;

  /// Up to [maxPaths] repo-relative paths that changed. Empty unless [kind] is
  /// [CodeIndexCauseKind.changes].
  final List<String> paths;

  /// How many distinct paths changed in the whole coalescing window, including
  /// the ones [paths] dropped at the cap.
  final int totalChanged;

  /// How many changed paths [paths] does not name.
  int get omittedCount {
    final omitted = totalChanged - paths.length;
    return omitted > 0 ? omitted : 0;
  }

  /// JSON view for the published run's trigger payload. Omits the path fields
  /// entirely for a cause that has none, so a payload stays readable.
  Map<String, dynamic> toJson() => {
    'cause': kind.name,
    if (paths.isNotEmpty) 'changed_paths': paths,
    if (totalChanged > 0) 'changed_count': totalChanged,
  };
}

/// One reported index run. See [CodeIndexRunReporter.begin].
abstract class CodeIndexRun {
  /// Whether the operator asked this run to stop (cancelled where it is
  /// displayed). Sampled from whatever the reporter wrote and refreshed by
  /// [report] — a getter rather than a future so it can be handed straight to
  /// [CodeIndexer.indexRepo]'s synchronous `isCancelled`.
  bool get cancelRequested;

  /// Reports live progress. The first call is what makes the run visible.
  Future<void> report(CodeIndexProgress progress);

  /// Reports a finished run. A no-op when nothing was ever reported, so a run
  /// that found no work leaves no trace.
  Future<void> finish(CodeIndexResult result);

  /// Reports a failed run. Unlike [finish] this always publishes: a failing
  /// index is worth seeing even though it indexed nothing.
  Future<void> fail(Object error, [StackTrace? stackTrace]);
}
