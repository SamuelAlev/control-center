import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_index_run_reporter.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        DirectoryChangeBatch,
        DirectoryChangeWatcher,
        DirectoryChangeWatcherFactory,
        NativeDirectoryWatcher,
        SourceFileWalker,
        WatcherUnavailable;

/// Keeps the code graph in sync with every checkout on disk, in both
/// directions the `RepoAdded`-only trigger never covered:
///
/// * **worktree checkouts** — a conversation/PR-review CoW worktree is checked
///   out at a different revision than the linked checkout (the PR head), so
///   the linked checkout's graph answers with symbols and paths that don't
///   exist there. Each worktree gets its OWN graph partition (keyed by its
///   `isolated_repos` row id), built when the worktree appears and kept
///   current as files change;
/// * **saves outside the pipeline** — the built-in code-server IDE, an
///   external "Open in IDE" editor, an agent's file writes, or a `git
///   checkout` (e.g. `worktree.syncToPrHead` pulling new PR commits) all
///   mutate the tree without touching the indexer. A [DirectoryChangeWatcher]
///   per checkout debounces those writes into one incremental [CodeIndexer]
///   run (content-hash skip makes a no-change run cheap), covering the linked
///   checkouts too, so editing `main` in any editor also stays fresh.
///
/// Checkout discovery is stream-driven off the two authoritative registries
/// ([WorkspaceRepository.watchAll] → `watchReposForWorkspace` for linked
/// checkouts, [IsolatedRepoRepository.watchForWorkspace] for worktrees), plus
/// a slow reconcile sweep that re-arms anything missed (a worktree whose
/// directory materialized after its registry row, or an event lost to a
/// crash). No explicit teardown of graph rows is needed here: deleting an
/// `isolated_repos` row FK-cascades its partition away.
///
/// One instance per host, started at boot and disposed on shutdown. All
/// indexing failures are logged and swallowed — the next file event or sweep
/// retries; a broken checkout must never take the service down.
class CodeGraphWatchService {
  /// Creates the service. [watcherFactory] is a test hook (production uses
  /// [_defaultWatcherFactory], the required native `cc_watcher`).
  /// [armStagger] spaces out arming consecutive checkouts; zero by default
  /// because a native watch costs O(1) to create.
  CodeGraphWatchService({
    required CodeIndexer indexer,
    required WorkspaceRepository workspaces,
    required IsolatedRepoRepository isolatedRepos,
    CodeIndexRunReporter? runReporter,
    Duration debounce = const Duration(seconds: 2),
    Duration maxDebounce = const Duration(seconds: 15),
    Duration reconcileInterval = const Duration(minutes: 1),
    Duration initialDelay = Duration.zero,
    Duration armStagger = Duration.zero,
    int maxConcurrentRuns = 1,
    Future<bool> Function(String workspaceId, String channelId)?
    shouldWatchChannel,
    DirectoryChangeWatcherFactory? watcherFactory,
  }) : _indexer = indexer,
       _runReporter = runReporter,
       _shouldWatchChannel = shouldWatchChannel,
       _maxConcurrentRuns = maxConcurrentRuns,
       _workspaces = workspaces,
       _isolatedRepos = isolatedRepos,
       _debounce = debounce,
       _maxDebounce = maxDebounce,
       _reconcileInterval = reconcileInterval,
       _initialDelay = initialDelay,
       _armStagger = armStagger,
       _watcherFactory = watcherFactory ?? _defaultWatcherFactory;

  final CodeIndexer _indexer;

  /// Where a run that does real work is published so it is visible outside the
  /// log — the pipeline runs table. Null (tests, and any host that wires no
  /// reporter) indexes identically and silently.
  final CodeIndexRunReporter? _runReporter;
  final WorkspaceRepository _workspaces;
  final IsolatedRepoRepository _isolatedRepos;
  final Duration _debounce;

  /// Ceiling on how long coalescing may defer a run. Each event restarts the
  /// [_debounce] window, so a tree written to continuously (a long `git
  /// checkout`, a save-on-keystroke editor) would otherwise never reach a quiet
  /// gap and never reindex at all.
  final Duration _maxDebounce;
  final Duration _reconcileInterval;

  /// How long the first reconcile is held after [start]. The server starts
  /// this service only after it reports ready, and the extra hold keeps the
  /// initial arm/index sweep out of the desktop's first RPC burst (workspace
  /// list, channel hydration). Registry changes are never missed during the
  /// hold — the workspace stream is subscribed immediately; only the sweep
  /// waits.
  final Duration _initialDelay;

  /// How many checkouts may index at once, across ALL workspaces.
  ///
  /// Each run costs a hashing isolate plus a tree-sitter parse isolate per file
  /// and (when the embedder is loaded) ONNX inference per symbol — all
  /// CPU-bound and all multi-threaded. Runs are per-checkout, and a host here
  /// had ~40 checkouts arm at once on a cold start, which pinned ten cores and
  /// made the whole machine lag. Indexing is background work: it must leave the
  /// machine usable, so it is deliberately throttled rather than run as fast as
  /// the hardware allows. Defaults to ONE: measured, two concurrent runs still
  /// left the RPC server unable to answer a request for ~40s after binding.
  final int _maxConcurrentRuns;
  var _activeRuns = 0;

  /// Whether a conversation is worth watching: it still exists AND is recently
  /// active. Worktrees of everything else are neither watched nor indexed.
  ///
  /// `isolated_repos` accumulates. Measured on a real host: 117 rows, of which
  /// only 15 belonged to a conversation active in the last week — 72 had never
  /// exchanged a single message. Back when each row armed a `package:watcher`
  /// `DirectoryWatcher` — whose constructor scans the whole tree and cannot
  /// skip `node_modules`/`build` — arming the set froze the isolate for ~65s
  /// at startup. The native watcher removed that cost, but the filter stays:
  /// every armed checkout still holds OS watch resources and still gets an
  /// initial index run, and a dormant conversation needs neither.
  ///
  /// "Deleted" was the wrong test — only 16 were actually deleted. What matters
  /// is whether anyone is working in the conversation: a dormant worktree is not
  /// being edited, so watching it buys nothing. A conversation that wakes up is
  /// picked up by the next reconcile (see [_watchableTtl]).
  ///
  /// Optional: without it every worktree is watched, as before.
  final Future<bool> Function(String workspaceId, String channelId)?
  _shouldWatchChannel;

  /// Keys judged not-worth-watching, with when the judgement was made. Re-checked
  /// after [_watchableTtl] so a conversation that becomes active again is armed
  /// rather than ignored forever.
  final Map<String, DateTime> _skipped = {};

  /// How long a skip decision stands before it is re-evaluated.
  static const _watchableTtl = Duration(minutes: 5);
  final DirectoryChangeWatcherFactory _watcherFactory;

  /// Production watcher factory: the native `cc_watcher`, which is REQUIRED.
  ///
  /// There is deliberately no `package:watcher` fallback. Its
  /// `DirectoryWatcher` scans the whole tree when constructed and cannot skip
  /// `node_modules`/`build`, which froze the server isolate for a measured 65
  /// seconds across 4 repos + 72 worktrees — a "degraded mode" that bad is
  /// worse than a loud failure. `cc_server` fails its native preflight when
  /// the dylib is missing, so reaching this with an unloadable native means a
  /// broken install: [WatcherUnavailable] propagates out of the arm. A *per-root*
  /// refusal (a `StateError` — the directory vanished mid-arm, watch-descriptor
  /// limits) is instead logged and retried by the next reconcile.
  static DirectoryChangeWatcher _defaultWatcherFactory(
    String path, {
    Set<String> ignoreDirNames = const {},
  }) => NativeDirectoryWatcher.create(
    path,
    ignoreDirNames: ignoreDirNames,
    onLog: (tag, message, [error, stackTrace]) =>
        CcInfraLog.warning('$tag: $message'),
  );

  StreamSubscription<List<Workspace>>? _workspaceSub;
  final Map<String, _WorkspaceSources> _workspaceSources = {};
  final Map<String, _CheckoutWatch> _checkouts = {};
  Timer? _reconcileTimer;
  Timer? _startupHoldTimer;
  var _startupHold = false;
  var _disposed = false;

  /// Starts watching every workspace's linked checkouts and worktrees.
  ///
  /// The workspace stream is subscribed immediately so no registry change is
  /// ever missed, but the reconcile sweep (arming + initial index runs) is
  /// held for [_initialDelay] first.
  void start() {
    if (_initialDelay > Duration.zero) {
      _startupHold = true;
      _startupHoldTimer = Timer(_initialDelay, () {
        _startupHold = false;
        _reconcile();
      });
    }
    _workspaceSub = _workspaces.watchAll().listen(
      _onWorkspaces,
      onError: (Object e, StackTrace st) =>
          CcInfraLog.warning('code-graph watch: workspace stream error: $e'),
    );
    _reconcileTimer = Timer.periodic(_reconcileInterval, (_) => _reconcile());
  }

  /// A cheap in-memory snapshot for the `/healthz` `codeGraph` block: how many
  /// checkouts are watched, how many index runs are in flight, and how many
  /// are queued (debouncing or dirty).
  ({int watching, int indexing, int pending}) get status => (
    watching: _checkouts.length,
    indexing: _activeRuns,
    pending: _checkouts.values
        .where((w) => w.debounceTimer != null || w.dirty)
        .length,
  );

  /// Stops all watchers and timers, then WAITS for any in-flight index run to
  /// wind down.
  ///
  /// The wait is not politeness: indexing writes through the repository, so a
  /// run left detached keeps querying a database the shutdown sequence is about
  /// to close, and surfaces as `Channel was closed before receiving a response`.
  /// `_disposed` is the cancellation signal threaded into [CodeIndexer] as
  /// `isCancelled`, so a run in progress stops at its next file rather than
  /// finishing the whole repo. Bounded by [_shutdownGrace] so a wedged run can
  /// never hang host shutdown.
  Future<void> dispose() async {
    _disposed = true;
    _reconcileTimer?.cancel();
    _startupHoldTimer?.cancel();
    await _workspaceSub?.cancel();
    for (final sources in _workspaceSources.values) {
      await sources.dispose();
    }
    _workspaceSources.clear();
    final inFlight = [
      for (final watch in _checkouts.values)
        if (watch.running != null) watch.running!,
    ];
    for (final watch in _checkouts.values) {
      watch.dispose();
    }
    _checkouts.clear();
    if (inFlight.isEmpty) {
      return;
    }
    CcInfraLog.info(
      'code-graph watch: waiting for ${inFlight.length} in-flight index '
      'run(s) to stop',
    );
    try {
      await Future.wait(inFlight).timeout(_shutdownGrace);
    } on TimeoutException {
      CcInfraLog.warning(
        'code-graph watch: in-flight index did not stop within '
        '${_shutdownGrace.inSeconds}s; continuing shutdown',
      );
    }
  }

  /// Ceiling on how long [dispose] waits for a cancelled run to unwind.
  static const _shutdownGrace = Duration(seconds: 5);

  /// Past this, a run is reported at warning level with its duration — the
  /// signal that a checkout is big enough (or a host loaded enough) that
  /// indexing is worth looking at.
  static const _slowRunThreshold = Duration(seconds: 5);

  // -------------------------------------------------------------------------
  // Discovery
  // -------------------------------------------------------------------------

  void _onWorkspaces(List<Workspace> workspaces) {
    final seen = <String>{};
    for (final workspace in workspaces) {
      seen.add(workspace.id);
      if (_workspaceSources.containsKey(workspace.id)) {
        continue;
      }
      final sources = _WorkspaceSources(
        workspaceId: workspace.id,
        workspaces: _workspaces,
        isolatedRepos: _isolatedRepos,
        onChanged: _reconcile,
        onError: (Object e) => CcInfraLog.warning(
          'code-graph watch: source stream error for ${workspace.id}: $e',
        ),
      );
      _workspaceSources[workspace.id] = sources;
    }
    // Removed workspaces: drop their sources; their checkouts fall out of the
    // desired set on the next reconcile.
    for (final id in _workspaceSources.keys.toList()) {
      if (!seen.contains(id)) {
        final sources = _workspaceSources.remove(id);
        sources?.dispose();
      }
    }
  }

  /// The desired checkout set across every workspace: linked checkouts
  /// (checkoutId null) plus one partition per isolated worktree row.
  Map<String, _DesiredCheckout> _desiredCheckouts() {
    final desired = <String, _DesiredCheckout>{};
    for (final sources in _workspaceSources.values) {
      for (final repo in sources.linkedRepos) {
        desired[_key(sources.workspaceId, repo.id, null)] = _DesiredCheckout(
          workspaceId: sources.workspaceId,
          repoId: repo.id,
          checkoutId: null,
          path: repo.path,
        );
      }
      for (final worktree in sources.worktrees) {
        desired[_key(
          sources.workspaceId,
          worktree.repoId,
          worktree.id,
        )] = _DesiredCheckout(
          workspaceId: sources.workspaceId,
          repoId: worktree.repoId,
          checkoutId: worktree.id,
          path: worktree.path,
          channelId: worktree.channelId,
        );
      }
    }
    return desired;
  }

  static String _key(String workspaceId, String repoId, String? checkoutId) =>
      '$workspaceId|$repoId|${checkoutId ?? ''}';

  // -------------------------------------------------------------------------
  // Reconcile
  // -------------------------------------------------------------------------

  /// Diffs the desired checkout set against the armed watchers: arms new
  /// checkouts (with an initial index), re-arms moved ones, disarms removed
  /// ones. Idempotent; runs on every registry change and on the slow sweep.
  void _reconcile() {
    if (_disposed || _startupHold) {
      return;
    }
    final desired = _desiredCheckouts();

    for (final key in _checkouts.keys.toList()) {
      final watch = _checkouts[key]!;
      final want = desired[key];
      if (want == null) {
        watch.dispose();
        _checkouts.remove(key);
        _baseIndexed.remove(key);
        _skipped.remove(key);
      } else if (want.path != watch.path) {
        // The checkout moved on disk (re-provisioned at a new path): re-arm.
        watch.dispose();
        _checkouts.remove(key);
      }
    }

    final toArm = [
      for (final entry in desired.entries)
        if (!_checkouts.containsKey(entry.key) && !_arming.contains(entry.key))
          entry,
    ];
    _arming.addAll(toArm.map((e) => e.key));
    if (toArm.isNotEmpty) {
      unawaited(_armStaggered(toArm));
    }
  }

  /// Arms the pending checkouts, optionally spaced by [_armStagger].
  ///
  /// Historical postmortem (why this method exists at all): arming used to
  /// construct a `package:watcher` `DirectoryWatcher` per checkout, whose
  /// constructor scans the whole tree and cannot be told to skip
  /// `node_modules`, `build`, or `.dart_tool`. Arming every checkout in one
  /// pass on a host with 4 repos and 72 worktrees froze the isolate for 65
  /// SECONDS, measured: no logs, no RPC, and timers (a 2s debounce, a 10s
  /// timeout) firing a minute late. The native `cc_watcher` fixed that at the
  /// source — creating a watch is O(1) and any walking happens on native
  /// threads — so the stagger now defaults to ZERO and the loop's only awaits
  /// are the dormancy checks. It stays configurable because arming is also
  /// when each checkout's initial index run is scheduled.
  Future<void> _armStaggered(
    List<MapEntry<String, _DesiredCheckout>> pending,
  ) async {
    for (final entry in pending) {
      if (_disposed) {
        return;
      }
      // Re-check: a later reconcile may have armed or dropped it already.
      if (_checkouts.containsKey(entry.key)) {
        continue;
      }
      if (await _isDeadWorktree(entry.key, entry.value)) {
        _arming.remove(entry.key);
        continue;
      }
      _arm(entry.key, entry.value);
      _arming.remove(entry.key);
      if (_armStagger > Duration.zero) {
        await Future<void>.delayed(_armStagger);
      }
    }
    // Anything left (disposed mid-pass, or already armed by a concurrent one)
    // must not stay marked or it can never be armed again.
    _arming.removeAll(pending.map((e) => e.key));
  }

  /// Pause between arming consecutive checkouts. Zero by default — a native
  /// watch costs O(1) to create.
  final Duration _armStagger;

  /// Keys queued for arming but not armed yet. Because arming is now spread
  /// over time, a later reconcile would otherwise queue the same checkout again
  /// and arm it twice — two watchers and two index runs for one tree.
  final Set<String> _arming = {};

  /// Whether [checkout] is a worktree belonging to a channel that no longer
  /// exists. Linked checkouts are never dead. Unknown (no predicate wired, or
  /// the lookup threw) counts as ALIVE — a diagnostic failure must not silently
  /// stop indexing a live conversation.
  Future<bool> _isDeadWorktree(String key, _DesiredCheckout checkout) async {
    final shouldWatch = _shouldWatchChannel;
    final channelId = checkout.channelId;
    if (shouldWatch == null ||
        checkout.checkoutId == null ||
        channelId == null) {
      return false;
    }
    final skippedAt = _skipped[key];
    if (skippedAt != null &&
        DateTime.now().difference(skippedAt) < _watchableTtl) {
      return true;
    }
    try {
      if (await shouldWatch(checkout.workspaceId, channelId)) {
        _skipped.remove(key);
        return false;
      }
    } catch (e) {
      CcInfraLog.warning('code-graph watch: channel check failed for $key: $e');
      return false;
    }
    if (skippedAt == null) {
      CcInfraLog.info(
        'code-graph watch: not watching dormant conversation $channelId '
        '(${checkout.path}) — it arms if the conversation becomes active',
      );
    }
    _skipped[key] = DateTime.now();
    return true;
  }

  void _arm(String key, _DesiredCheckout checkout) {
    if (!Directory(checkout.path).existsSync()) {
      // Row ahead of the filesystem (provisioning in flight): the sweep
      // re-arms once the directory materializes.
      return;
    }
    final _CheckoutWatch watch;
    try {
      watch = _CheckoutWatch(
        checkout: checkout,
        watcherFactory: _watcherFactory,
        onEvent: () => _markDirty(key),
        // The watched root itself vanished (worktree deleted / re-provisioned):
        // drop the dead watch so the next reconcile re-arms it if (and when)
        // the path exists again. Without this a checkout re-provisioned at the
        // SAME path kept a dead watch — reconcile only re-arms on a path change
        // or key removal.
        onRootGone: () {
          final current = _checkouts[key];
          if (current != null && identical(current.checkout, checkout)) {
            current.dispose();
            _checkouts.remove(key);
          }
        },
      );
    } on WatcherUnavailable {
      // The dylib itself is unusable — a broken install, and every other
      // checkout will fail identically. Propagate: `cc_server`'s native
      // preflight already refuses to boot on this, so reaching it means the
      // install broke underneath a running server and silently watching nothing
      // would be worse than crashing.
      rethrow;
    } on Object catch (e) {
      // Per-root refusal (the directory went away mid-arm, watch-descriptor
      // limits). Log and leave the key unarmed: the reconcile sweep retries, and
      // one unwatchable checkout must never take the service — or the other
      // checkouts — down.
      CcInfraLog.warning(
        'code-graph watch: could not watch ${checkout.path}: $e',
      );
      return;
    }
    _checkouts[key] = watch;
    // Initial index: builds a worktree's partition the moment it appears, and
    // (re)heals the linked checkout's on boot. Incremental — cheap when the
    // graph is already current (and near-free when the index checkpoint
    // matches).
    _scheduleIndex(key);
  }

  // -------------------------------------------------------------------------
  // Index scheduling (per-checkout serialized + coalesced)
  // -------------------------------------------------------------------------

  /// Whether [watch] is a worktree whose base partition has not been indexed
  /// yet, and is worth waiting for.
  ///
  /// Only waits when a linked checkout for the same repo is actually armed —
  /// a repo with no linked checkout on this host would otherwise wait forever.
  /// Bounded by [_maxBaseWaits] so a base that never finishes (broken natives,
  /// a vanishing checkout) degrades to indexing the full tree rather than never
  /// indexing at all.
  bool _mustWaitForBase(_CheckoutWatch watch) {
    final checkout = watch.checkout;
    if (checkout.checkoutId == null || watch.baseWaits >= _maxBaseWaits) {
      return false;
    }
    final baseKey = _key(checkout.workspaceId, checkout.repoId, null);
    if (_baseIndexed.contains(baseKey)) {
      return false;
    }
    return _checkouts.containsKey(baseKey);
  }

  /// `workspaceId|repoId|` keys whose LINKED checkout has completed a run, so
  /// worktrees of that repo can measure their delta against a real base.
  final Set<String> _baseIndexed = {};

  /// How many debounce ticks a worktree waits for its base before giving up and
  /// indexing in full.
  ///
  /// Generous on purpose: a first index of a large repo takes minutes, and the
  /// throttle above can queue several behind it. At ~2s per tick this is ~30
  /// minutes — measured, a 2-minute ceiling expired while the base was still
  /// running and 55 of 72 worktrees fell back to indexing their whole tree,
  /// which is the duplication delta indexing exists to prevent. The ceiling only
  /// needs to stop a permanently-wedged base from blocking worktrees forever.
  static const _maxBaseWaits = 900;

  void _markDirty(String key) {
    final watch = _checkouts[key];
    if (watch == null) {
      return;
    }
    watch.dirty = true;
    // A watcher event is PROOF a file changed; the run it triggers must
    // bypass the indexer's checkpoint fingerprint (which is a digest, not a
    // proof). The initial arm-time index keeps force=false — that is exactly
    // the boot path the checkpoint exists to make cheap.
    watch.sawEvent = true;
    watch.firstDirtyAt ??= DateTime.now();
    _scheduleIndex(key);
  }

  void _scheduleIndex(String key) {
    final watch = _checkouts[key];
    if (watch == null) {
      return;
    }
    watch.debounceTimer?.cancel();
    // Past the ceiling, stop deferring: run now and let the next event open a
    // fresh window. Without this a continuously-written tree never indexes.
    final firstDirtyAt = watch.firstDirtyAt;
    if (firstDirtyAt != null &&
        DateTime.now().difference(firstDirtyAt) >= _maxDebounce) {
      watch.debounceTimer = null;
      _runIndex(key);
      return;
    }
    watch.debounceTimer = Timer(_debounce, () => _runIndex(key));
  }

  Future<void> _runIndex(String key) async {
    final watch = _checkouts[key];
    if (watch == null || _disposed) {
      return;
    }
    if (watch.running != null) {
      // Coalesce: one follow-up run after the current one, never a pile-up.
      watch.rerunRequested = true;
      return;
    }
    if (_activeRuns >= _maxConcurrentRuns) {
      // At the concurrency ceiling — retry on the next debounce tick. Not
      // counted as a base wait: this checkout is ready, the machine is not.
      watch.debounceTimer?.cancel();
      watch.debounceTimer = Timer(_debounce, () => _runIndex(key));
      return;
    }
    if (_mustWaitForBase(watch)) {
      // A worktree indexes only its DELTA against the linked checkout, so
      // running before the base partition exists measures the delta against
      // nothing and stores the entire tree — the duplication delta indexing is
      // meant to avoid. On a cold start every checkout arms at once, so without
      // this the first pass writes a full copy per worktree and only converges
      // on a later run. Retry on the debounce tick instead.
      watch.baseWaits++;
      watch.debounceTimer?.cancel();
      watch.debounceTimer = Timer(_debounce, () => _runIndex(key));
      return;
    }
    watch.dirty = false;
    final force = watch.sawEvent;
    watch.sawEvent = false;
    watch.firstDirtyAt = null;
    watch.baseWaits = 0;
    _activeRuns++;
    final checkout = watch.checkout;
    final label =
        '${checkout.path} (checkout ${checkout.checkoutId ?? 'linked'})';
    final startedAt = DateTime.now();
    // Logged unconditionally at start: indexing enumerates and hashes every
    // source file, so it is the one background job here that takes real time,
    // and a silent start makes a slow or wedged run impossible to attribute.
    CcInfraLog.info('code-graph watch: indexing $label');
    // Opened for every run but published only by the first thing worth showing
    // (see CodeIndexRunReporter.begin) — most fires find no work at all.
    final report = _runReporter?.begin(
      workspaceId: checkout.workspaceId,
      repoId: checkout.repoId,
      repoPath: checkout.path,
      checkoutId: checkout.checkoutId,
    );
    final run = _indexer
        .indexRepo(
          workspaceId: checkout.workspaceId,
          repoId: checkout.repoId,
          repoPath: checkout.path,
          checkoutId: checkout.checkoutId,
          // An event-driven run bypasses the checkpoint short-circuit; the
          // arm-time initial run does not (see _markDirty).
          force: force,
          onProgress: report == null
              ? null
              : (progress) => unawaited(report.report(progress)),
          // Shutdown cancellation: stop at the next file rather than running on
          // against a database the shutdown sequence is about to close. Also
          // honours a cancel on the published run, so the Stop button in the
          // pipelines UI stops the actual work rather than only the row.
          isCancelled: () => _disposed || (report?.cancelRequested ?? false),
        )
        .then((result) async {
          if (checkout.checkoutId == null) {
            // Worktrees of this repo can now measure a real delta.
            _baseIndexed.add(key);
          }
          await report?.finish(result);
          final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
          final summary =
              '$label in ${elapsedMs}ms: ${result.filesIndexed} indexed, '
              '${result.filesSkipped} skipped, ${result.removedFiles} pruned';
          if (elapsedMs >= _slowRunThreshold.inMilliseconds) {
            CcInfraLog.warning('code-graph watch: slow index of $summary');
          } else if (result.filesIndexed > 0 || result.removedFiles > 0) {
            CcInfraLog.info('code-graph watch: reindexed $summary');
          } else {
            CcInfraLog.debug('code-graph watch: no changes for $summary');
          }
        })
        .catchError((Object e, StackTrace st) async {
          // A run cancelled by shutdown is expected, not a fault: the database
          // is closing under it. Anything else is a real failure.
          if (_disposed) {
            CcInfraLog.info(
              'code-graph watch: index of $label stopped by shutdown',
            );
            return;
          }
          await report?.fail(e, st);
          CcInfraLog.warning(
            'code-graph watch: index failed for $label '
            '(after ${DateTime.now().difference(startedAt).inMilliseconds}ms): '
            '$e',
          );
        });
    watch.running = run;
    await run;
    watch.running = null;
    _activeRuns--;
    if (_disposed || !_checkouts.containsKey(key)) {
      return;
    }
    if (watch.rerunRequested || watch.dirty) {
      watch.rerunRequested = false;
      _scheduleIndex(key);
    }
  }
}

/// One checkout the service keeps indexed.
class _DesiredCheckout {
  const _DesiredCheckout({
    required this.workspaceId,
    required this.repoId,
    required this.checkoutId,
    required this.path,
    this.channelId,
  });

  final String workspaceId;
  final String repoId;
  final String? checkoutId;
  final String path;

  /// The conversation this worktree belongs to; null for a linked checkout.
  final String? channelId;
}

/// Per-workspace stream pair (linked repos + isolated worktrees) feeding the
/// reconcile loop. Keeps the latest lists so `_desiredCheckouts` is a pure
/// snapshot read.
class _WorkspaceSources {
  _WorkspaceSources({
    required this.workspaceId,
    required WorkspaceRepository workspaces,
    required IsolatedRepoRepository isolatedRepos,
    required void Function() onChanged,
    required void Function(Object error) onError,
  }) {
    _subs = [
      workspaces.watchReposForWorkspace(workspaceId).listen((repos) {
        linkedRepos = repos;
        onChanged();
      }, onError: onError),
      isolatedRepos.watchForWorkspace(workspaceId).listen((rows) {
        worktrees = rows;
        onChanged();
      }, onError: onError),
    ];
  }

  final String workspaceId;
  late final List<StreamSubscription<Object?>> _subs;

  List<Repo> linkedRepos = const [];
  List<IsolatedRepo> worktrees = const [];

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
  }
}

/// A live [DirectoryChangeWatcher] + scheduling state for one checkout.
class _CheckoutWatch {
  _CheckoutWatch({
    required this.checkout,
    required DirectoryChangeWatcherFactory watcherFactory,
    required void Function() onEvent,
    void Function()? onRootGone,
  }) : watcher = watcherFactory(
         checkout.path,
         ignoreDirNames: SourceFileWalker.watchIgnoredDirs,
       ) {
    subscription = watcher.changes.listen(
      (batch) {
        if (batch.rootGone) {
          onRootGone?.call();
          return;
        }
        if (batch.rescanNeeded) {
          // Something changed but the paths are unknown (queue overflow,
          // kernel rescan hint) — treat as a relevant change; the indexer's
          // content-hash skip keeps a false positive cheap.
          onEvent();
          return;
        }
        for (final path in batch.paths) {
          // affectsIndex stays the final gate regardless of backend, so the
          // extension/generated-file semantics are identical either way.
          if (SourceFileWalker.affectsIndex(path)) {
            onEvent();
            return;
          }
        }
      },
      onError: (Object e) {
        CcInfraLog.warning(
          'code-graph watch: watcher error for ${checkout.path}: $e',
        );
      },
    );
  }

  final _DesiredCheckout checkout;
  final DirectoryChangeWatcher watcher;
  late final StreamSubscription<DirectoryChangeBatch> subscription;
  Timer? debounceTimer;
  Future<void>? running;
  bool dirty = false;
  bool rerunRequested = false;

  /// Whether a real watcher event arrived since the last run started — the
  /// signal that the next run must bypass the checkpoint short-circuit.
  bool sawEvent = false;

  /// When the current coalescing window opened, so the service's max-debounce
  /// ceiling can bound it.
  DateTime? firstDirtyAt;

  /// Debounce ticks this worktree has spent waiting for its base partition.
  int baseWaits = 0;

  String get path => checkout.path;

  void dispose() {
    debounceTimer?.cancel();
    subscription.cancel();
    // Releases native handles (cc_watcher) / the fallback's subscription.
    unawaited(watcher.close());
  }
}
