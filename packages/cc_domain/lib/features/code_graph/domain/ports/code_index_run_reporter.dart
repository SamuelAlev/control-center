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
  CodeIndexRun begin({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
  });
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
