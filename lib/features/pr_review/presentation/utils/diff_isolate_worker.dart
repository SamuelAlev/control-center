import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_worker_core.dart';
import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Process-singleton pool: two-pass PR diff parse + tokenize off the UI thread.
///
/// Pass 1: structure (`parseUnifiedDiff`). Pass 2: tokens in
/// [diffTokenChunkLines] chunks. Via `isolate_manager` (isolates / `diffWorker.js`);
/// payloads are JSON strings (Workers cannot transfer Maps). Worker failure →
/// Worker failure → main-isolate fallback. Generation per file cancels in-flight pass-2.
/// [ChangeNotifier] for queue UI. Core in `diff_worker_core.dart`.
///
/// Lifetime/retention: workers are created lazily on first use and released
/// after [_idleTeardownDelay] with no active job, so reviewing one PR does not
/// pin N isolate heaps / Web Workers for the whole process; the next [enqueue]
/// re-spawns them. Completed token results are held in a bounded LRU — capped
/// by entry COUNT and by an estimated retained-BYTES budget (text plus token /
/// line / list overhead, see [_cachedResultBytes]) — and a result over either
/// budget is skipped rather than allowed to blow the bound.
class DiffWorkerPool extends ChangeNotifier {
  DiffWorkerPool._();

  /// Process-wide singleton. Workers are spawned lazily and reaped when the
  /// pool goes idle (see [_idleTeardownDelay]); the pool object itself lives
  /// for the session.
  static final DiffWorkerPool instance = DiffWorkerPool._();

  /// Number of concurrent workers. Scales with the host CPU so large PRs
  /// (400+ files) get parallel tokenization across all cores while leaving one
  /// core for the UI/main isolate. Clamped to [2, 12] so low-end devices still
  /// get parallelism and very high-core hosts don't pay the memory overhead of
  /// dozens of workers for diminishing returns (each has its own heap).
  ///
  /// On the web there is no `Platform.numberOfProcessors` (it throws), so the
  /// count is fixed. `kIsWeb` is a compile-time const, so the `Platform` call is
  /// never evaluated on web. Unlike the old implementation the web path now
  /// runs on real Web Workers, so a modest fan-out is worthwhile.
  static final int kWorkerCount = kIsWeb
      ? 4
      : math.max(2, math.min(12, Platform.numberOfProcessors - 1));

  /// Effective worker count actually spawned. Defaults to [kWorkerCount]; a
  /// measurement harness (or a memory-constrained bootstrap) may set it before
  /// the first [enqueue] to A/B fewer workers against throughput without
  /// editing the CPU-derived default. Values are clamped to `[1, 32]`. A change
  /// after workers already exist takes effect at the next spawn (idle teardown
  /// or [shutdown]).
  @visibleForTesting
  static int? debugWorkerCountOverride;

  int get _effectiveWorkerCount =>
      math.min(32, math.max(1, debugWorkerCountOverride ?? kWorkerCount));

  /// Retained for source compatibility; the chunk size lives in the worker core.
  static const int kTokenChunkLines = diffTokenChunkLines;

  /// The cross-platform worker pool. Null until the first [enqueue] lazily
  /// creates it (which spawns [_effectiveWorkerCount] isolates / Web Workers on
  /// first `compute`), and null again after idle teardown or [shutdown].
  /// `workerName: 'diffWorker'` selects the generated `web/diffWorker.js` on
  /// the web; it is ignored on native.
  // R and P are JSON `String`s, not Maps: a Web Worker (js_interop) cannot
  // transfer a Dart Map — the maintainer's documented workaround is
  // jsonEncode/jsonDecode (isolate_manager issue #31). So the job is sent as a
  // JSON string and each streamed event comes back as a JSON string.
  IsolateManager<String, String>? _manager;

  /// Circuit breaker: set once a worker `compute` fails or never responds (e.g.
  /// a Web Worker whose JS can't load). Subsequent enqueues then tokenize inline
  /// on the main isolate directly instead of paying a dead round-trip per file.
  /// Reset on [shutdown].
  bool _workerUnavailable = false;

  /// Test hook: forces [enqueue] onto the inline (main-isolate) path, so
  /// widget tests never spawn real isolates or arm the fallback watchdog
  /// [Timer] (which `FakeAsync` would report as pending at teardown).
  @visibleForTesting
  static bool debugForceInline = false;

  /// How long workers may sit unused before [DiffWorkerPool] stops them. The
  /// pool used to keep its isolate heaps (or Web Workers) for the whole process
  /// lifetime after a single PR review; this bounds that retention. Deliberately
  /// conservative: teardown only fires with no active job and no outstanding
  /// worker call, the next [enqueue] re-spawns workers, and completed results
  /// stay cached across teardown — so revisiting an already-tokenized file is
  /// still a synchronous cache hit and never pays the re-warm cost.
  static const Duration _idleTeardownDelay = Duration(seconds: 60);

  /// Override for [_idleTeardownDelay] (`null` = production default).
  /// `Duration.zero` disables idle teardown, restoring the old keep-alive
  /// behavior. Tests shrink it to exercise teardown/re-spawn quickly.
  @visibleForTesting
  static Duration? debugIdleTeardownDelay;

  Timer? _idleTimer;

  /// Worker `compute` calls started but not yet settled (terminal event, error,
  /// or hang-watchdog fallback). Guards idle teardown so it can never stop the
  /// manager under a live compute — `IsolateManager` cannot be restarted after
  /// `stop()`, so killing a live call would strand its completer (and later
  /// trip the watchdog into disabling workers for the session).
  int _inFlightComputes = 0;

  /// Active jobs keyed by file ID. Tracks current generation + the stream
  /// controller so out-of-band events from a stale generation can be dropped.
  final Map<String, _ActiveJob> _active = {};

  /// Number of workers currently spawned. Zero until the first [enqueue] and
  /// back to zero after idle teardown or [shutdown].
  int get workerCount => _manager == null ? 0 : _effectiveWorkerCount;

  /// Per-worker busy count — 0 (idle) or 1 (processing), matching the old
  /// hand-rolled pool's shape so the indicator renders identically. A worker
  /// processes one file at a time, so we light up the first [activeJobCount]
  /// dots (capped at the worker count). Empty list before the first spawn.
  List<int> get workerBacklogs {
    if (_manager == null) {
      return const [];
    }
    final count = _effectiveWorkerCount;
    final busy = math.min(_active.length, count);
    return List<int>.unmodifiable([
      for (var i = 0; i < count; i++) i < busy ? 1 : 0,
    ]);
  }

  /// Number of files with work currently in flight (not in the LRU cache).
  int get activeJobCount => _active.length;

  /// Number of files currently held in the result LRU cache.
  int get cacheSize => _cache.length;

  /// Estimated retained bytes across the result LRU (the budget unit). A
  /// deterministic heap-cost ESTIMATE of the cached token data — text plus
  /// token / line / list overhead — not a measurement of RSS. Exposed so tests
  /// and the queue UI can see the memory bound actually being enforced.
  int get cacheBytes => _cacheBytes;

  /// Current LRU keys, least-recently-used first. Test-only view for the
  /// eviction/LRU boundary assertions.
  @visibleForTesting
  List<String> get debugCachedKeys => _cache.keys.toList();

  /// LRU cache of completed pass-2 token results, keyed by
  /// `{cacheKey}|{brightness}|{lang}|{patch fingerprint}`.
  /// Re-enqueuing the same file returns the cached events synchronously (in the same
  /// microtask) instead of spinning up worker work.
  /// The patch fingerprint is part of the key because tokens carry the TEXT the painter
  /// draws: the same filename is routinely tokenized from DIFFERENT patches (the PR "Files
  /// changed" diff vs the base branch, a worktree diff vs the index, a re-diff after an edit
  /// landed).
  final Map<String, _CachedResult> _cache = {};

  /// Estimated retained bytes across [_cache], maintained incrementally so
  /// eviction accounting is O(1) per entry. See [_cachedResultBytes] for the
  /// model.
  int _cacheBytes = 0;

  /// Hard cap on entries regardless of size — the pre-existing bound.
  static const int _maxCacheEntries = 128;

  /// Total retained-bytes budget (estimated, see [_cachedResultBytes]). The
  /// entry cap alone is not a memory bound: 128 entries of large files
  /// (minified bundles, lockfiles, generated code) can retain tens of
  /// megabytes. `8 MiB` of estimated bytes is a conservative cap.
  static const int _maxCacheBytes = 8 * 1024 * 1024;

  /// Per-result cap. A result over this is NEVER retained — caching one monster
  /// diff would blow the bound for no reuse benefit.
  static const int _maxCachedResultBytes = 2 * 1024 * 1024;

  /// Overrides for the two budgets above (`null` = production default). Tests
  /// shrink them so the eviction/skip boundaries are exercisable with small
  /// fixtures.
  @visibleForTesting
  static int? debugMaxCacheBytes;

  /// Overrides the per-result byte cap; `null` uses the production default.
  @visibleForTesting
  static int? debugMaxCachedResultBytes;

  int get _cacheByteBudget => debugMaxCacheBytes ?? _maxCacheBytes;
  int get _cacheItemBudget =>
      debugMaxCachedResultBytes ?? _maxCachedResultBytes;

  IsolateManager<String, String> _ensureManager() {
    final existing = _manager;
    if (existing != null) {
      return existing;
    }
    final created = IsolateManager<String, String>.createCustom(
      diffWorker,
      workerName: 'diffWorker',
      concurrent: _effectiveWorkerCount,
    );
    _manager = created;
    // Deferred: enqueue (and thus manager creation) is reached from
    // RenderUnifiedDiffSliver.performLayout and a synchronous notify there
    // schedules a build mid-frame ("Build scheduled during frame").
    _scheduleNotify();
    return created;
  }

  String _cacheKey(
    String cacheKey,
    bool isDark,
    String? language,
    String patch,
  ) =>
      '$cacheKey|${ccThemeCacheId(dark: isDark)}|${language ?? '_'}'
      '|${patch.length}:${patch.hashCode}';

  void _putCache(String key, _CachedResult value) {
    // Skip a result that exceeds EITHER budget — including the total budget,
    // even when it would be the only entry. Retaining it would immediately blow
    // the bound; the caller already received the streamed result, so a later
    // revisit simply re-tokenizes. Predictable: results over either budget are
    // NEVER retained.
    if (value.bytes > _cacheItemBudget || value.bytes > _cacheByteBudget) {
      return;
    }
    // Re-inserting on write keeps the insertion-ordered Map in
    // least-recently-USED order, so `keys.first` below is the right victim.
    final previous = _cache.remove(key);
    if (previous != null) {
      _cacheBytes -= previous.bytes;
    }
    _cache[key] = value;
    _cacheBytes += value.bytes;
    // Evict LRU entries until both budgets hold. Termination is guaranteed
    // because the inserted entry passed the skip check above, so once it is the
    // only entry left the loop condition is false.
    while (_cache.length > _maxCacheEntries || _cacheBytes > _cacheByteBudget) {
      final victim = _cache.keys.first;
      final removed = _cache.remove(victim);
      if (removed != null) {
        _cacheBytes -= removed.bytes;
      }
    }
    _scheduleNotify();
  }

  /// Reads [key], refreshing its recency.
  ///
  /// Eviction used to be FIFO — insertion order, ignoring use — so a file the
  /// reviewer keeps coming back to was evicted before files they viewed once
  /// and never opened again, which is backwards for a diff being reviewed.
  /// Re-inserting on a hit turns the same Map into an LRU.
  _CachedResult? _readCache(String key) {
    final hit = _cache.remove(key);
    if (hit == null) {
      return null;
    }
    _cache[key] = hit;
    return hit;
  }

  /// Schedules a `notifyListeners()` for the end of the current microtask.
  /// Collapses bursty mutations (e.g. dispatching N chunks in one tick) into
  /// a single UI update so the indicator doesn't redraw 200× per file.
  bool _notifyScheduled = false;
  void _scheduleNotify() {
    if (_notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  /// (Re)arms the idle-teardown timer. Called after worker activity so the
  /// countdown starts from the last moment a job could still be running. Never
  /// arms without a manager (so the inline-only test path spawns no timers).
  void _armIdleTeardown() {
    if (_manager == null) {
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = null;
    final delay = debugIdleTeardownDelay ?? _idleTeardownDelay;
    if (delay <= Duration.zero) {
      return; // Idle teardown disabled.
    }
    _idleTimer = Timer(delay, _maybeTeardownIdleWorkers);
  }

  /// Releases the worker manager once the pool has been genuinely idle for
  /// [_idleTeardownDelay]. Guarded on [_active]/[_inFlightComputes] so a job
  /// that landed after the timer was armed is never interrupted, and the
  /// manager field is nulled synchronously before the async [IsolateManager.stop]
  /// so a concurrent [enqueue] lazily builds a fresh manager instead of racing
  /// the teardown. The next [enqueue] re-spawns workers (a one-time grammar
  /// recompile) — the delay is deliberately conservative for that reason.
  void _maybeTeardownIdleWorkers() {
    _idleTimer = null;
    final manager = _manager;
    if (manager == null) {
      return;
    }
    if (_active.isNotEmpty || _inFlightComputes > 0) {
      // Busy again between arming and firing — re-arm instead of tearing down
      // mid-flight.
      _armIdleTeardown();
      return;
    }
    _manager = null;
    unawaited(_stopManager(manager));
    _scheduleNotify();
  }

  /// Best-effort teardown: a manager that is already stopped, or whose worker
  /// is mid-dispose, must not raise an unhandled async error out of the
  /// fire-and-forget idle timer.
  static Future<void> _stopManager(
    IsolateManager<String, String> manager,
  ) async {
    try {
      await manager.stop();
    } on Object {
      // Ignored on purpose — see doc above.
    }
  }

  /// Enqueues a file for parsing + tokenization. Returns a stream of
  /// [DiffEvent]s — 1+ `DiffTokensChunk`
  /// events, then `DiffDone`. Errors arrive as `DiffError`.
  ///
  /// Pass the same [cacheKey] (typically the blob SHA or file path) on
  /// subsequent calls to hit the LRU cache. The [patch] content is mixed into
  /// the resolved key, so a path-based key stays correct when the same file is
  /// tokenized from different diffs (PR diff vs worktree diff, or after an
  /// edit changed the patch).
  ///
  /// [generation] is bumped by callers to invalidate prior in-flight work for
  /// the same [fileId] — stale-gen events are dropped before they reach the
  /// stream.
  Stream<DiffEvent> enqueue({
    required String fileId,
    required String patch,
    required String? language,
    required bool isDark,
    required int generation,
    String? cacheKey,
  }) {
    final controller = StreamController<DiffEvent>();
    final resolvedKey = cacheKey == null
        ? null
        : _cacheKey(cacheKey, isDark, language, patch);
    final cacheLookup = resolvedKey == null ? null : _readCache(resolvedKey);

    if (cacheLookup != null) {
      scheduleMicrotask(() {
        if (controller.isClosed) {
          return;
        }
        controller
          ..add(cacheLookup.tokens)
          ..add(const DiffDone())
          ..close();
      });
      return controller.stream;
    }

    // Cancel any prior active job for this fileId — caller bumped generation.
    final prior = _active.remove(fileId);
    if (prior != null && !prior.controller.isClosed) {
      prior.controller.close();
    }

    final job = _ActiveJob(
      fileId: fileId,
      generation: generation,
      controller: controller,
      cacheKey: resolvedKey,
    );
    _active[fileId] = job;
    _scheduleNotify();

    // Syntax colors come from the CC theme compiled into the worker (`dark`
    // picks the variant); the palette lists only feed the inline word-diff
    // washes, resolved here from the Flutter-side DiffPalette.
    final palette = DiffPalette.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    ).syntax;
    final jobMap = buildDiffJob(
      patch: patch,
      language: language,
      dark: isDark,
      palette: palette,
    );

    // Tokenize on the main isolate — the proven pre-worker behavior, kept as a
    // safety net if the worker never delivers. Deferred to a microtask so the
    // plain-text structure (parsed synchronously by the store) paints first and
    // colour fades in right after, matching the worker's async cadence.
    // Re-emitted token chunks are harmless: they overwrite idempotently.
    void runInline() => scheduleMicrotask(
      () => runDiffJob(
        jobMap,
        (event) => _dispatchEvent(fileId, generation, event),
      ),
    );

    if (_workerUnavailable || debugForceInline) {
      // A prior worker call failed/hung this session; skip the dead round-trip
      // and tokenize inline.
      runInline();
    } else {
      final manager = _ensureManager();
      _inFlightComputes++;
      _armIdleTeardown();
      final jobJson = jsonEncode(jobMap);
      var settled = false;
      // Marks this worker call as no longer outstanding exactly once — whether
      // it ended with a terminal event, an error, or the hang watchdog — so
      // idle teardown never stops the manager under a live compute.
      void settle() {
        if (settled) {
          return;
        }
        settled = true;
        _inFlightComputes--;
      }

      // NEVER lose highlighting: fall back to the main isolate if the worker
      // errors or never responds. Trips the breaker so the rest of the session
      // skips the dead round-trip.
      void fallback() {
        if (settled) {
          return;
        }
        settle();
        _workerUnavailable = true;
        // A hung manager must still be reapable even though its compute never
        // settled — settle() already released the in-flight guard.
        _armIdleTeardown();
        runInline();
      }

      // Watchdog for the failure isolate_manager cannot surface as an error: a
      // Web Worker whose `ensureInitialized` never completes (e.g. its JS fails
      // to load) leaves `compute` hanging silently. Generous, to tolerate a
      // cold-start worker spawn; cancelled the moment any event arrives.
      final watchdog = Timer(const Duration(seconds: 8), () {
        if (!settled) {
          fallback();
        }
      });

      unawaited(
        manager
            .compute(
              jobJson,
              callback: (eventJson) {
                watchdog.cancel();
                final event = jsonDecode(eventJson) as Map<String, dynamic>;
                _dispatchEvent(fileId, generation, event);
                final type = event[DiffWire.type];
                final terminal = type == DiffWire.done || type == DiffWire.err;
                if (terminal) {
                  settle(); // worker finished the job; no fallback needed
                }
                return terminal;
              },
            )
            .catchError((Object _) {
              watchdog.cancel();
              fallback();
              return '';
            }),
      );
    }

    controller.onCancel = () {
      // Caller dropped the stream (typically a widget got virtualized
      // away). If the job has a cacheKey, let it run to completion so its
      // result lands in the cache and a future remount hits it
      // synchronously — that's the prefetch behaviour we want for big
      // PRs. Without a cacheKey there's no reuse path, so just drop it.
      if (_active[fileId] != job) {
        return;
      }
      if (job.cacheKey != null) {
        job.detached = true;
      } else {
        _active.remove(fileId);
        _scheduleNotify();
        _armIdleTeardown();
      }
    };

    return controller.stream;
  }

  /// Routes one decoded worker event (a primitive map) to its active job,
  /// applying the same stale-generation drop, detach-to-cache and LRU-caching
  /// rules the previous isolate implementation used.
  void _dispatchEvent(
    String fileId,
    int generation,
    Map<String, dynamic> event,
  ) {
    final job = _active[fileId];
    if (job == null || job.generation != generation) {
      // Stale — caller cancelled or bumped generation. Drop silently.
      return;
    }
    // For detached jobs the controller is already closed; we keep
    // processing so the result can land in the LRU cache. Anything else
    // closed is genuinely stale.
    if (job.controller.isClosed && !job.detached) {
      _active.remove(fileId);
      return;
    }

    switch (event[DiffWire.type]) {
      case DiffWire.tok:
        final chunk = _decodeTok(event);
        job.tokensByLine ??= [];
        // Pad with nulls if chunks arrive out of order or with gaps.
        while (job.tokensByLine!.length < chunk.startIndex) {
          job.tokensByLine!.add(const []);
        }
        for (var i = 0; i < chunk.tokens.length; i++) {
          final idx = chunk.startIndex + i;
          if (idx < job.tokensByLine!.length) {
            job.tokensByLine![idx] = chunk.tokens[i];
          } else {
            job.tokensByLine!.add(chunk.tokens[i]);
          }
        }
        if (!job.detached) {
          job.controller.add(chunk);
        }
      case DiffWire.done:
        if (job.cacheKey != null) {
          final tokens = job.tokensByLine ?? const <List<DiffToken>>[];
          _putCache(
            job.cacheKey!,
            _CachedResult(
              tokens: DiffTokensChunk(startIndex: 0, tokens: tokens),
              bytes: _cachedResultBytes(tokens),
            ),
          );
        }
        if (!job.detached) {
          job.controller
            ..add(const DiffDone())
            ..close();
        }
        _active.remove(fileId);
        _armIdleTeardown();
      case DiffWire.err:
        if (!job.detached) {
          job.controller
            ..add(
              DiffError(
                (event[DiffWire.message] as String?) ?? 'diff worker error',
              ),
            )
            ..close();
        }
        _active.remove(fileId);
        _armIdleTeardown();
    }
  }

  /// Cancels any in-flight pass-2 work for [fileId]. The caller is responsible
  /// for using the returned new generation on its next [enqueue] for the same
  /// fileId — otherwise late events from this generation would slip through.
  void cancel(String fileId) {
    final job = _active.remove(fileId);
    if (job != null && !job.controller.isClosed) {
      job.controller.close();
      _scheduleNotify();
    }
    _armIdleTeardown();
  }

  /// Tears down all workers immediately and resets all retained state. Used by
  /// tests and app teardown; idle use in production is handled automatically by
  /// [_idleTeardownDelay], which stops the workers without clearing the result
  /// cache.
  Future<void> shutdown() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    await _manager?.stop();
    _manager = null;
    _workerUnavailable = false;
    // [_inFlightComputes] is intentionally NOT reset: any compute cancelled by
    // [IsolateManager.stop] still fires its callback/error/watchdog `settle()`,
    // which decrements it back toward zero on its own. Zeroing here would let
    // that late settle drive the count negative and mask a *live* compute of a
    // later spawn.
    for (final job in _active.values) {
      if (!job.controller.isClosed) {
        await job.controller.close();
      }
    }
    _active.clear();
    _cache.clear();
    _cacheBytes = 0;
    notifyListeners();
  }
}

/// Public event types sent on the stream returned from [DiffWorkerPool.enqueue].
@immutable
sealed class DiffEvent {
  const DiffEvent();
}

/// Parsed line structure in flat-column form, no syntax tokens. Built
/// synchronously on the main isolate (see [buildDiffRawLines]) — since the
/// tokenizer swap to shiki the worker no longer emits it, so it is a plain
/// value type, not a [DiffEvent].
@immutable
class DiffRawLines {
  /// Creates a [DiffRawLines] event from parallel column arrays.
  const DiffRawLines({
    required this.kinds,
    required this.contents,
    required this.oldLines,
    required this.newLines,
    required this.hunkHeaders,
    required this.gapOldEnds,
    required this.gapNewEnds,
    required this.maxLineChars,
  });

  /// Parallel arrays — flat columns are cheaper to ship across isolates than a
  /// `List<Object>` of per-line records and friendlier to the GC.
  final List<int> kinds;

  /// Raw text content of each line, indexed by line position.
  final List<String> contents;

  /// Pre-image line number for each line (null when not applicable). For
  /// [DiffLineKind.expandGap] rows this is the (inclusive) start of the
  /// missing range; the inclusive end lives in [gapOldEnds].
  final List<int?> oldLines;

  /// Post-image line number for each line (null when not applicable). For
  /// [DiffLineKind.expandGap] rows this is the (inclusive) start of the
  /// missing range; the inclusive end lives in [gapNewEnds].
  final List<int?> newLines;

  /// Hunk header text, only set for [DiffLineKind.hunkHeader] lines.
  final List<String?> hunkHeaders;

  /// Inclusive end (pre-image) of an [DiffLineKind.expandGap] row's missing
  /// range. Null on non-gap rows. Carried as a parallel array (rather than
  /// stuffed into another field) so the row encoding stays uniform across all
  /// kinds and isolate transfer keeps its flat-column shape.
  final List<int?> gapOldEnds;

  /// Inclusive end (post-image) of an [DiffLineKind.expandGap] row's
  /// missing range. Null on non-gap rows.
  final List<int?> gapNewEnds;

  /// Longest content line (in characters). Used by the canvas viewer to size
  /// its horizontal scroll extent up front.
  final int maxLineChars;

  /// Number of lines.
  int get length => contents.length;

  /// Resolves the [DiffLineKind] for line [i].
  DiffLineKind kindAt(int i) => DiffLineKind.values[kinds[i]];
}

/// Pass-2 chunk: syntax tokens for lines `[startIndex, startIndex + tokens.length)`.
/// Multiple chunks land per file; the last one is followed by [DiffDone].
@immutable
class DiffTokensChunk extends DiffEvent {
  /// Creates a [DiffTokensChunk] covering lines starting at [startIndex].
  const DiffTokensChunk({required this.startIndex, required this.tokens});

  /// Index of the first line in this chunk.
  final int startIndex;

  /// Tokens per line, one inner list per line in the chunk.
  final List<List<DiffToken>> tokens;
}

/// Terminal event — pass 2 finished, including `applyInlineWordDiff`.
@immutable
class DiffDone extends DiffEvent {
  /// Creates a [DiffDone] terminal event.
  const DiffDone();
}

/// Terminal event — something went wrong inside the worker.
@immutable
class DiffError extends DiffEvent {
  /// Creates a [DiffError] terminal event with a human-readable [message].
  const DiffError(this.message);

  /// Error description.
  final String message;
}

/// Pass-1: parses [patch] into the flat-column [DiffRawLines] structure.
///
/// Pure Dart with no Flutter dependency, so the same parse backs both the
/// worker's pass-1 and the main-isolate synchronous parse the unified viewer
/// uses to guarantee plain text is always paintable (no loading state).
DiffRawLines buildDiffRawLines(String patch) =>
    buildDiffRawLinesFromParsed(parseUnifiedDiff(patch));

/// Builds [DiffRawLines] from an already-parsed [parsed] line list, so callers
/// that need the [DiffLine] list too (e.g. the worker's pass-2) parse once.
DiffRawLines buildDiffRawLinesFromParsed(List<DiffLine> parsed) {
  final kinds = <int>[];
  final contents = <String>[];
  final oldLines = <int?>[];
  final newLines = <int?>[];
  final hunkHeaders = <String?>[];
  final gapOldEnds = <int?>[];
  final gapNewEnds = <int?>[];
  var maxLineChars = 0;
  for (final l in parsed) {
    kinds.add(l.kind.index);
    contents.add(l.content);
    oldLines.add(l.oldLine);
    newLines.add(l.newLine);
    hunkHeaders.add(l.hunkHeader);
    gapOldEnds.add(l.gapOldEnd);
    gapNewEnds.add(l.gapNewEnd);
    if (l.content.length > maxLineChars) {
      maxLineChars = l.content.length;
    }
  }
  return DiffRawLines(
    kinds: kinds,
    contents: contents,
    oldLines: oldLines,
    newLines: newLines,
    hunkHeaders: hunkHeaders,
    gapOldEnds: gapOldEnds,
    gapNewEnds: gapNewEnds,
    maxLineChars: maxLineChars,
  );
}

DiffTokensChunk _decodeTok(Map<String, dynamic> e) {
  final startIndex = e[DiffWire.startIndex] as int;
  final lineLens = _ints(e[DiffWire.lineLens]);
  final texts = _strings(e[DiffWire.texts]);
  final colors = _nullableInts(e[DiffWire.colors]);
  final bgs = _nullableInts(e[DiffWire.bgs]);
  final rawKinds = e[DiffWire.kinds];
  final kinds = rawKinds == null
      ? List<int>.filled(texts.length, DiffTokenKind.none)
      : _ints(rawKinds);
  final tokens = <List<DiffToken>>[];
  var offset = 0;
  for (final len in lineLens) {
    final line = <DiffToken>[];
    for (var i = 0; i < len; i++) {
      line.add(
        DiffToken(
          texts[offset],
          colors[offset],
          backgroundColorValue: bgs[offset],
          kind: offset < kinds.length ? kinds[offset] : DiffTokenKind.none,
        ),
      );
      offset++;
    }
    tokens.add(line);
  }
  return DiffTokensChunk(startIndex: startIndex, tokens: tokens);
}

// The wire payload arrives as strongly-typed lists on native (isolate copy) but
// as `List<dynamic>` on web (structured clone), so these coerce eagerly.
List<int> _ints(dynamic list) => [for (final v in (list as List)) v as int];
List<int?> _nullableInts(dynamic list) => [
  for (final v in (list as List)) v as int?,
];
List<String> _strings(dynamic list) => [
  for (final v in (list as List)) v as String,
];

/// Fixed overhead charged per cached result: the outer list header + its
/// backing-array header.
const int _bytesPerOuterList = 24;

/// Fixed overhead charged per line: the inner `List<DiffToken>` header + its
/// backing-array header. Charged even for a line with no tokens, so a
/// mostly-empty result is not free.
const int _bytesPerLineList = 24;

/// Bytes charged per token for the pointer holding it in its line's backing
/// array (an 8-byte reference on 64-bit targets).
const int _bytesPerListSlot = 8;

/// Fixed overhead charged per token: object header + the three `int` fields
/// ([DiffToken.colorValue], [DiffToken.backgroundColorValue], [DiffToken.kind]).
const int _bytesPerToken = 24;

/// Bytes per UTF-16 code unit of token text (Dart strings are UTF-16).
const int _bytesPerTextUnit = 2;

/// Deterministic ESTIMATE of the bytes a completed result retains once cached:
/// token text plus the token / line / list shells around it. Charging the fixed
/// terms is what keeps object-heavy or mostly-empty token arrays from hiding
/// behind a text-only figure (a line of empty tokens still costs real bytes).
///
/// This is a budgeting model, NOT a measurement of RSS or of the live heap; the
/// real cost also depends on the VM, boxed values and GC state.
int _cachedResultBytes(List<List<DiffToken>> tokens) {
  var bytes = _bytesPerOuterList;
  for (final line in tokens) {
    bytes += _bytesPerLineList + line.length * _bytesPerListSlot;
    for (final token in line) {
      bytes += _bytesPerToken + token.text.length * _bytesPerTextUnit;
    }
  }
  return bytes;
}

@immutable
class _CachedResult {
  const _CachedResult({required this.tokens, required this.bytes});

  final DiffTokensChunk tokens;

  /// Estimated retained bytes, precomputed so eviction is O(1) per entry.
  final int bytes;
}

class _ActiveJob {
  _ActiveJob({
    required this.fileId,
    required this.generation,
    required this.controller,
    required this.cacheKey,
  });

  final String fileId;
  final int generation;
  final StreamController<DiffEvent> controller;
  final String? cacheKey;

  /// Accumulator for tokens across chunks — captured for caching at done.
  List<List<DiffToken>>? tokensByLine;

  /// The original subscriber dropped the stream but the job is still
  /// worth finishing — its result will populate the cache so a future
  /// caller (e.g. the file scrolled back into view) hits the cache
  /// synchronously instead of re-enqueueing the parse. Worker events
  /// for detached jobs are processed for caching only; the controller
  /// stays closed.
  bool detached = false;
}
