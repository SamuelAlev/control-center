import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart'
    show ExtractionResult;
import 'package:cc_infra/src/code_graph/code_indexer_fingerprint.dart';
import 'package:cc_infra/src/code_graph/extraction_isolate.dart';
import 'package:cc_infra/src/code_graph/extraction_worker.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart';

/// Default [CodeIndexer]: enumerate source files, group them by language
/// (detected from extension), then for each language whose tree-sitter natives
/// are installed, skip unchanged files (content hash), parse + extract each
/// changed file in a long-lived worker isolate and ingest into the
/// [CodeGraphRepository] in batched transactions. Finally prune deleted files
/// and resolve cross-file references repo-wide.
///
/// A run handed `changedPaths` skips the enumeration entirely and works from
/// that list: it hashes those paths (through the same filters the walk applies),
/// reads only their stored rows and prunes only among them. That is the
/// difference between "reindex on save" costing the size of the CHANGE and
/// costing the size of the CHECKOUT — measured, 5-9s and ~19k stats per saved
/// file before it existed.
///
/// Before any of that, the run is short-circuited by an INDEX CHECKPOINT:
/// a cheap git-driven fingerprint of the checkout ([RepoStateProbe]) plus a
/// fingerprint of the extraction toolchain ([codeIndexerFingerprint]) are
/// compared against what the last successful run recorded — a full match
/// returns [CodeIndexResult.unchanged] without reading a single file state
/// row or walking the tree. This is what makes an unchanged checkout
/// near-free at boot.
///
/// The tree-sitter natives are REQUIRED: they ship inside the host bundle, so
/// [indexRepo] throws a [StateError] naming the offenders when ANY recognised
/// language's grammar dylib or `.scm` query cannot be resolved — a broken
/// install must fail loudly, not silently produce a code graph that happens to
/// omit every Dart symbol. There is no per-language skip: the extension→language
/// registry (`kLanguageByExtension`) and the set of grammars the build scripts
/// produce are the same list, so an unresolvable language is always a broken
/// tree, never finite coverage. Resolution happens up front, before any file is
/// ingested, so a failed run leaves no half-written index.
class DefaultCodeIndexer implements CodeIndexer {
  /// Creates a [DefaultCodeIndexer].
  DefaultCodeIndexer({
    required CodeGraphRepository repository,
    required GrammarManager grammarManager,
    Future<String> Function(String queryId)? queryLoader,
    SourceFileWalker? walker,
    RepoStateProbe? probe,
    Future<ExtractionResult> Function(ExtractionRequest request)? extractor,
    Future<ExtractionWorker> Function()? extractionWorkerFactory,
  }) : _repository = repository,
       _grammarManager = grammarManager,
       _walker = walker ?? const SourceFileWalker(),
       _probe = probe ?? const RepoStateProbe(),
       _queryLoader = queryLoader,
       _extractOverride = extractor,
       _workerFactory = extractionWorkerFactory ?? ExtractionWorker.spawn;

  final CodeGraphRepository _repository;
  final GrammarManager _grammarManager;
  final SourceFileWalker _walker;
  final RepoStateProbe _probe;

  /// How many parsed files accumulate before one batched ingest transaction.
  ///
  /// 32 files is ~300-1300 symbol rows per commit — one WAL fsync per batch
  /// instead of four auto-committed statements per file, while a crash or
  /// cancellation loses at most 32 files of work (re-done idempotently from
  /// content hashes on the next run). Progress granularity coarsens to the
  /// same 32; the only consumer is the pipeline step-run snapshot.
  static const _ingestBatchSize = 32;

  /// Test seam: when injected, runs one file's parse + extraction directly
  /// (no worker isolate spawns at all). Production leaves it null and uses a
  /// long-lived [ExtractionWorker] per run.
  final Future<ExtractionResult> Function(ExtractionRequest request)?
  _extractOverride;

  /// Spawns the per-run extraction worker (test seam; production is
  /// [ExtractionWorker.spawn]).
  final Future<ExtractionWorker> Function() _workerFactory;

  /// Loads a tree-sitter `.scm` query by id. Optional: when null (the
  /// production path) the query is read from disk beside the grammar lib via
  /// [GrammarManager.loadQuery] — the `.scm` files ship next to the natives in
  /// dev (`build_tree_sitter.sh`) and release bundles (`scripts/release/*`),
  /// so no Flutter asset / `rootBundle` is involved and the `dart build cli`
  /// server reads them the same way. Tests inject a stub loader.
  final Future<String> Function(String queryId)? _queryLoader;

  /// Resolves the `.scm` query for [queryId]: the injected loader if present
  /// (tests), otherwise the on-disk query beside the grammar lib. Null when no
  /// query is found, so the caller skips that language gracefully.
  Future<String?> _loadQuery(String queryId) {
    final loader = _queryLoader;
    return loader != null
        ? loader(queryId)
        : _grammarManager.loadQuery(queryId);
  }

  /// Serializes indexing per `(workspaceId, repoId, checkoutId)` partition.
  ///
  /// Two lanes reach one indexer instance for the same checkout and neither
  /// knows about the other: the `index_code` pipeline (fired by `RepoAdded` or
  /// started by hand) and the code-graph watcher's own sweep, which publishes
  /// its work as a PROJECTION run row deliberately kept out of that template's
  /// `maxParallelRuns` accounting. Adding a batch of repos ran both against the
  /// same checkout at once: one repo walked, hashed, parsed, embedded and
  /// ingested TWICE, the two passes contending for the cores and for the
  /// workspace's single database writer — precisely what `maxParallelRuns: 1`
  /// on that template exists to prevent.
  final Map<String, Future<void>> _partitionLocks = {};

  /// Concurrent calls for the same partition are SERIALIZED, not coalesced into
  /// one shared future. The second caller keeps its own [onProgress] and
  /// [isCancelled] — a joined run could not honour the pipeline's Stop button
  /// or move its step-run snapshot — and gets a result describing its own call
  /// rather than someone else's. It is not the expensive way round either: by
  /// the time it runs the first pass has written the checkpoint, so the
  /// short-circuit below answers it with two process spawns instead of a
  /// second full walk.
  @override
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    List<String>? changedPaths,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // Both ids are UUIDs and the checkout id is a UUID or absent, so `|` can
    // occur in none of them and no two partitions collide on the joined key.
    // The same key shape the pipeline engine uses for its own per-template
    // locks.
    final lockKey = '$workspaceId|$repoId|${checkoutId ?? ''}';
    final prev = _partitionLocks[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _partitionLocks[lockKey] = gate.future;
    try {
      // The gate is only ever `complete`d, never `completeError`d, so a run
      // that throws releases the partition without poisoning the chain behind
      // it.
      await prev;
      return await _indexPartition(
        workspaceId: workspaceId,
        repoId: repoId,
        repoPath: repoPath,
        checkoutId: checkoutId,
        force: force,
        changedPaths: changedPaths,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
    } finally {
      gate.complete();
      // Only when still the tail: a later caller has already replaced it.
      if (_partitionLocks[lockKey] == gate.future) {
        // `remove` hands back the stored future; it is already complete here.
        unawaited(_partitionLocks.remove(lockKey));
      }
    }
  }

  /// One partition's index pass, already serialized by [indexRepo].
  Future<CodeIndexResult> _indexPartition({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    List<String>? changedPaths,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // ── Checkpoint short-circuit ─────────────────────────────────────────
    // Probe the checkout's git state (2 process spawns + a stat per dirty
    // path) and the extraction toolchain; when both match the checkpoint the
    // last successful run recorded, nothing observable changed and the whole
    // run is skipped. `force` (a watcher event — proof a file changed)
    // bypasses the comparison but still reads the view, which the checkpoint
    // write at the end needs. A null probe (not a git tree, git missing,
    // huge dirty set) NEVER skips.
    final stateFp = await _probe.probe(repoPath);
    String? toolchainFp;
    CodeIndexCheckpointView? checkpointView;
    if (stateFp != null) {
      toolchainFp = await codeIndexerFingerprint(_grammarManager);
      checkpointView = await _repository.readCheckpoint(
        workspaceId,
        repoId,
        checkoutId: checkoutId,
      );
      final own = checkpointView.own;
      if (!force &&
          own != null &&
          own.headSha == stateFp.headSha &&
          own.worktreeDigest == stateFp.digest &&
          own.indexerFingerprint == toolchainFp &&
          // A worktree's delta is measured against the base partition; a base
          // re-index since this checkpoint invalidates it even though the
          // worktree's own tree never moved.
          (checkoutId == null ||
              own.baseGeneration == checkpointView.baseGeneration)) {
        return const CodeIndexResult.unchanged();
      }
    }

    // ── Discovery: targeted or full ──────────────────────────────────────
    // A watcher-driven run arrives KNOWING which paths changed, and everything
    // below is otherwise spent rediscovering that: a `git ls-files` plus a stat
    // of every file in the checkout, and a read of the partition's whole
    // `code_files` table (twice for a worktree — its own and the base's). Both
    // scale with the size of the CHECKOUT, not with the size of the change.
    //
    // Measured on a 19k-file checkout: 5-9 SECONDS and ~19k stats per run to
    // index one saved file, ~90 times an hour while an agent worked — and under
    // contention that reached 185s for a single file. Targeting pays for the
    // handed paths instead, so the cost finally tracks the change.
    //
    // Empty means "full pass" as much as null does: an event whose paths were
    // all filtered out must not be read as "nothing in this repo changed".
    final targeted = changedPaths != null && changedPaths.isNotEmpty;

    // What this partition already knows. Full pass: the whole partition, so
    // unchanged files cost a stat rather than a full read + SHA-256 — the
    // difference between an unchanged checkout costing a directory walk and
    // costing every byte of every file. Targeted: only the changed paths' rows,
    // which is all the rest of this method looks at.
    final knownStates = targeted
        ? await _repository.fileStatesFor(
            workspaceId,
            repoId,
            changedPaths,
            checkoutId: checkoutId,
          )
        : await _repository.fileStates(
            workspaceId,
            repoId,
            checkoutId: checkoutId,
          );
    // Enumeration + hashing runs on its own isolate either way; inline it would
    // stall the server's event loop for the whole run. `hashPaths` applies the
    // SAME extension / generated-file / gitignore filters the walk does, so a
    // targeted run can never index something a full run would leave out.
    final files = targeted
        ? await _walker.hashPaths(repoPath, changedPaths)
        : await _walker.walkAndHash(
            repoPath,
            known: {
              for (final entry in knownStates.entries)
                entry.key: IndexedFileState(
                  contentHash: entry.value.contentHash,
                  indexedAt: entry.value.indexedAt,
                ),
            },
          );

    // A WORKTREE partition stores only its DELTA against the linked checkout.
    //
    // A conversation/PR worktree is a copy of the same repo: measured on a real
    // database, 88% of the files it indexed were byte-identical to the linked
    // checkout, so a full per-worktree graph duplicated ~350k symbols (and their
    // embeddings) across 78 partitions for no new information. Files whose hash
    // matches the base are left to the base partition, which reads merge over —
    // see `CodeGraphDao` (reads widen to `checkout_id = X OR IS NULL` and
    // de-duplicate by path, the worktree's row winning).
    //
    // The linked partition (checkoutId == null) has no base and always indexes
    // everything.
    final baseHashes = checkoutId == null
        ? const <String, String>{}
        : targeted
        ? await _repository.fileHashesFor(workspaceId, repoId, changedPaths)
        : await _repository.fileHashes(workspaceId, repoId);
    final indexable = <HashedSourceFile>[];
    var inheritedFromBase = 0;
    for (final file in files) {
      if (baseHashes[file.relativePath] == file.contentHash) {
        inheritedFromBase++;
        continue;
      }
      indexable.add(file);
    }
    // What this partition is expected to own after the run. Anything else it
    // currently holds is pruned below — including a file that has since become
    // identical to base (edited back, or the base caught up), which must leave
    // the delta or reads would keep serving the worktree's stale copy.
    //
    // In a TARGETED run this is scoped to the changed paths, and so is the
    // `existing` set it is subtracted from — every untouched file is out of the
    // prune's reach by construction, which is what makes the subtraction below
    // correct without a full enumeration.
    final current = {for (final file in indexable) file.relativePath};

    // Group the files this partition owns by detected language.
    final byLanguage = <String, List<HashedSourceFile>>{};
    for (final file in indexable) {
      final languageId = languageIdForPath(file.relativePath);
      if (languageId == null) {
        continue;
      }
      (byLanguage[languageId] ??= <HashedSourceFile>[]).add(file);
    }

    // Already loaded above as part of the mtime fast-path — no second query.
    final existing = {
      for (final entry in knownStates.entries)
        entry.key: entry.value.contentHash,
    };
    var indexed = 0;
    var skipped = 0;
    var symbols = 0;
    var edges = 0;
    var failed = 0;

    // ── Resolve every language's natives BEFORE any extraction ──
    // Each language the walker recognises ships a grammar + a `.scm` query
    // (`kLanguageByExtension` and the build script are the same list), so a
    // language that fails to resolve is a BROKEN INSTALL, not a coverage gap.
    // Resolving up front means such a run fails without having half-ingested a
    // repo and no per-language "skipped" path can quietly produce an index that
    // is missing every Dart symbol.
    final natives = <String, ({GrammarPaths grammar, String query})>{};
    final missingNatives = <String>[];
    for (final languageId in byLanguage.keys) {
      final grammar = await _grammarManager.install(languageId);
      if (grammar == null) {
        missingNatives.add('$languageId (grammar dylib)');
        continue;
      }
      final query = await _loadQuery(queryIdFor(languageId));
      if (query == null || query.isEmpty) {
        missingNatives.add('$languageId (${queryIdFor(languageId)}.scm query)');
        continue;
      }
      natives[languageId] = (grammar: grammar, query: query);
    }
    if (missingNatives.isNotEmpty) {
      throw StateError(
        'tree-sitter natives missing for: ${missingNatives.join(', ')} '
        '(build them with scripts/natives/build_tree_sitter.sh — on Windows '
        'scripts/release/windows_natives.sh — or rebuild the host bundle with '
        'the natives staged). Every recognised language ships a grammar, so '
        'this is a broken install; refusing to index instead of writing an '
        'index that silently omits these languages. One exception, if the '
        'server booted (the preflight resolves these same dylibs) and then '
        'lost EVERY language at once: `dart build cli` deletes the bundle '
        'before it rewrites it, so a rebuild during a run unlinks the '
        "grammars underneath the live process — that server's index is dead "
        'until it is restarted against the new bundle.',
      );
    }

    // One extraction worker for the whole run, spawned lazily on the first
    // file that actually needs a parse — a run where every file's hash
    // matched never pays the isolate spawn. Killed and respawned when a
    // pathological file wedges it (see the timeout handler).
    ExtractionWorker? worker;
    final pending = <CodeFileIngest>[];

    // The work this run actually has, computed before any of it happens: the
    // files the loop below will parse, i.e. the ones whose hash moved. It is the
    // denominator every progress reader wants and — because the FIRST tick can
    // be emitted before the first parse — it is also what lets a caller learn
    // "this run has work" up front rather than after the first ingest.
    var toIndex = 0;
    for (final group in byLanguage.values) {
      for (final file in group) {
        if (existing[file.relativePath] != file.contentHash) {
          toIndex++;
        }
      }
    }

    // `totalFiles` is the run's candidate set, which a TARGETED run scopes to
    // the changed paths rather than the checkout. That is the honest number for
    // a progress bar here — a "3 of 19248" that jumps straight to done is worse
    // than "3 of 3" — and no reader treats it as the size of the repo.
    CodeIndexProgress progressAt(int done) => CodeIndexProgress(
      filesIndexed: done,
      filesToIndex: toIndex,
      totalFiles: files.length,
      symbols: symbols,
      edges: edges,
    );

    Future<void> flush() async {
      if (pending.isEmpty) {
        return;
      }
      await _repository.ingestFiles(List.of(pending));
      pending.clear();
      onProgress?.call(progressAt(indexed));
    }

    // Announce the run BEFORE the first parse. Progress used to be emitted only
    // after an ingest batch committed, so a run of fewer than `_ingestBatchSize`
    // files — every incremental re-index — reported nothing until it was already
    // finished and anything watching (the pipeline step snapshot, the repo
    // index button) had nothing to show while the slow part ran.
    if (toIndex > 0) {
      onProgress?.call(progressAt(0));
    }

    try {
      outer:
      for (final entry in byLanguage.entries) {
        final languageId = entry.key;
        // Non-null: the resolve loop above threw unless every language resolved.
        final grammar = natives[languageId]!.grammar;
        final query = natives[languageId]!.query;

        for (final file in entry.value) {
          if (isCancelled?.call() ?? false) {
            break outer;
          }
          final hash = file.contentHash;
          if (existing[file.relativePath] == hash) {
            skipped++;
            continue;
          }
          String source;
          try {
            source = await File(file.absolutePath).readAsString();
          } catch (_) {
            continue;
          }
          final request = ExtractionRequest(
            workspaceId: workspaceId,
            repoId: repoId,
            checkoutId: checkoutId,
            filePath: file.relativePath,
            source: source,
            languageId: languageId,
            querySource: query,
            runtimePath: grammar.runtimePath,
            grammarPath: grammar.grammarPath,
          );
          ExtractionResult result;
          try {
            final override = _extractOverride;
            Future<ExtractionResult> extraction;
            if (override != null) {
              extraction = override(request);
            } else {
              if (worker == null || !worker.isAlive) {
                worker = await _workerFactory();
              }
              extraction = worker.extract(request);
            }
            // Bound each file's parse so a pathological file can't consume the
            // whole 30-minute step budget and surface (rather than silently
            // swallow) isolate crashes / grammar failures.
            result = await extraction.timeout(const Duration(seconds: 30));
          } on TimeoutException {
            failed++;
            CcInfraLog.warning(
              'Timed out parsing ${file.relativePath} (30s); skipping',
            );
            // A shared worker held by a wedged native parse can't serve the
            // next file (unlike the old throwaway `Isolate.run`) — kill it;
            // the next file spawns a fresh one.
            await worker?.kill();
            worker = null;
            continue;
          } on TreeSitterUnavailable {
            // The natives resolved on this isolate but failed to load in the
            // worker — a broken install, never a per-file condition. Fail the
            // whole index rather than "indexing" every file to nothing.
            rethrow;
          } on Object catch (e) {
            failed++;
            CcInfraLog.warning(
              'Failed to parse ${file.relativePath}: $e; skipping',
            );
            continue;
          }
          pending.add(
            CodeFileIngest(
              workspaceId: workspaceId,
              repoId: repoId,
              checkoutId: checkoutId,
              filePath: file.relativePath,
              contentHash: hash,
              symbols: result.symbols,
              edges: result.edges,
              language: languageId,
            ),
          );
          indexed++;
          symbols += result.symbols.length;
          edges += result.edges.length;
          if (pending.length >= _ingestBatchSize) {
            await flush();
          }
        }
      }
    } finally {
      await worker?.dispose();
    }
    // Persist whatever the loop produced — including the partial batch of a
    // cancelled run; ingest is idempotent on deterministic ids.
    await flush();

    if (failed > 0) {
      CcInfraLog.warning(
        'skipped $failed file(s) due to parse timeout or extraction error',
      );
    }

    // Prune anything this partition should no longer own: files gone from disk,
    // and (worktree partitions) files that have become identical to base, whose
    // symbols now come from the base partition instead.
    final removed = existing.keys
        .where((path) => !current.contains(path))
        .toList();
    if (removed.isNotEmpty) {
      await _repository.deleteFiles(
        workspaceId,
        repoId,
        removed,
        checkoutId: checkoutId,
      );
    }

    // Bind cross-file references now that every file's symbols are present.
    // (Internally probes the unresolved count first, so a run with nothing
    // pending pays one indexed COUNT, not a symbol-table read.)
    final resolved = await _repository.resolvePendingReferences(
      workspaceId,
      repoId,
      checkoutId: checkoutId,
    );

    // Then drop what could not bind. A surviving edge has no definition
    // anywhere in the indexed tree (external package, SDK, vendor namespace,
    // ambiguous simple name) and no graph query can ever see it — every
    // consumer joins on the bound target symbol id. Keeping the rows only
    // re-pays the unresolved read on every later run: measured on a real
    // index, 80% of all edge rows were permanently unresolved. Steady state
    // is now ~zero pending, which is also what makes the resolver's COUNT
    // probe skip the whole pass on a quiet save.
    final pruned = await _repository.pruneUnresolvedEdges(
      workspaceId,
      repoId,
      checkoutId: checkoutId,
    );
    if (pruned > 0) {
      CcInfraLog.info(
        'code index: pruned $pruned unresolvable reference edge(s) '
        '(external packages / ambiguous names) in $repoId',
      );
    }

    // ── Checkpoint write ─────────────────────────────────────────────────
    // Only after a COMPLETE, CLEAN run: a cancelled run must re-run next
    // time and a run with parse failures stays retryable (the old behavior:
    // a timed-out file is retried on the next run, not frozen out until its
    // content changes). `generation` bumps only when rows actually changed,
    // so a no-op run of the base does not invalidate every worktree's delta.
    //
    // A TARGETED run writes it too, which is a deliberate call: the fingerprint
    // was probed BEFORE the run and describes the whole tree, so recording it
    // asserts that the handed path set explained every difference. That is what
    // "the set must be COMPLETE" in [CodeIndexer.indexRepo] buys, and the
    // watcher is the one component that can promise it — `cc_watcher` is
    // kernel-recursive and reports `rescanNeeded` when it loses events, at which
    // point the caller passes no paths and this becomes a full pass again. The
    // alternative (never checkpoint a targeted run) would make the next
    // arm-time pass re-walk the whole checkout for changes already indexed.
    final cancelled = isCancelled?.call() ?? false;
    if (stateFp != null && toolchainFp != null && !cancelled && failed == 0) {
      final own = checkpointView?.own;
      final changedRows = indexed > 0 || removed.isNotEmpty;
      await _repository.writeCheckpoint(
        CodeIndexCheckpoint(
          workspaceId: workspaceId,
          repoId: repoId,
          checkoutId: checkoutId,
          headSha: stateFp.headSha,
          worktreeDigest: stateFp.digest,
          indexerFingerprint: toolchainFp,
          generation: (own?.generation ?? 0) + (changedRows ? 1 : 0),
          baseGeneration: checkoutId == null
              ? 0
              : (checkpointView?.baseGeneration ?? 0),
          indexedAt: DateTime.now(),
        ),
      );
    }

    if (inheritedFromBase > 0) {
      CcInfraLog.info(
        'code index: $inheritedFromBase file(s) identical to the linked '
        'checkout left to the base partition (delta indexing)',
      );
    }
    return CodeIndexResult(
      // Files left to the base partition count as skipped work, same as a file
      // whose hash was unchanged since the last run — neither was re-extracted.
      filesIndexed: indexed,
      filesSkipped: skipped + inheritedFromBase,
      symbols: symbols,
      edges: edges,
      removedFiles: removed.length,
      resolvedReferences: resolved,
      // Constant now: the run either resolved every language's natives or threw
      // above. Kept on the wire because pipeline step output and the repo
      // "indexed" badge read it (see `repo_index_button.dart`).
      nativeAvailable: true,
    );
  }
}
