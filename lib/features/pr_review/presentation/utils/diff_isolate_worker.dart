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

/// Process-singleton pool of long-lived workers that parse + tokenize PR diffs
/// in two passes (structure first, syntax tokens streamed in chunks).
///
/// Modeled on Pierre's diff pipeline. Pass 1 is cheap — `parseUnifiedDiff` on
/// the patch text — and lets the canvas paint plain text + addition/deletion
/// row backgrounds within ~one frame of opening a file. Pass 2 streams
/// syntax-highlighted tokens back in chunks of [diffTokenChunkLines] lines so
/// colour fades in progressively without blocking the UI.
///
/// The heavy compute runs off the main thread on **every** platform via
/// [`isolate_manager`](https://pub.dev/packages/isolate_manager): real isolates
/// on native, a generated `web/diffWorker.js` Web Worker on the web (desktop
/// parity — the pre-migration web path ran inline on the main thread and janked
/// large PRs). Everything crossing the boundary is a JSON **string**, because a
/// Web Worker cannot transfer a Dart Map (isolate_manager issue #31). If the
/// worker ever errors or fails to load, [enqueue] falls back to tokenizing on
/// the main isolate so syntax highlighting is never lost. The pure compute
/// pipeline + worker entrypoint live in `diff_worker_core.dart` (Flutter-free);
/// this class owns the main-side pool, cache and streaming plumbing.
///
/// Each enqueued file gets a generation counter; bumping the generation cancels
/// any pending or in-flight pass-2 chunks for that file.
///
/// The pool is also a [ChangeNotifier] — listeners are pinged whenever the
/// per-worker backlog, the active-job map, or the LRU cache size changes, so
/// a live UI indicator can mirror queue state in real time.
class DiffWorkerPool extends ChangeNotifier {
  DiffWorkerPool._();

  /// Process-wide singleton — kept alive for the whole session.
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

  /// Retained for source compatibility; the chunk size lives in the worker core.
  static const int kTokenChunkLines = diffTokenChunkLines;

  /// The cross-platform worker pool. Null until the first [enqueue] lazily
  /// creates it (which spawns [kWorkerCount] isolates / Web Workers on first
  /// `compute`). `workerName: 'diffWorker'` selects the generated
  /// `web/diffWorker.js` on the web; it is ignored on native.
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

  /// Active jobs keyed by file ID. Tracks current generation + the stream
  /// controller so out-of-band events from a stale generation can be dropped.
  final Map<String, _ActiveJob> _active = {};

  /// Number of workers currently spawned. Zero until the first [enqueue];
  /// [kWorkerCount] thereafter.
  int get workerCount => _manager == null ? 0 : kWorkerCount;

  /// Per-worker busy count — 0 (idle) or 1 (processing), matching the old
  /// hand-rolled pool's shape so the indicator renders identically. A worker
  /// processes one file at a time, so we light up the first [activeJobCount]
  /// dots (capped at [kWorkerCount]). Empty list before the first spawn.
  List<int> get workerBacklogs {
    if (_manager == null) {
      return const [];
    }
    final busy = math.min(_active.length, kWorkerCount);
    return List<int>.unmodifiable([
      for (var i = 0; i < kWorkerCount; i++) i < busy ? 1 : 0,
    ]);
  }

  /// Number of files with work currently in flight (not in the LRU cache).
  int get activeJobCount => _active.length;

  /// Number of files currently held in the result LRU cache.
  int get cacheSize => _cache.length;

  /// LRU cache of completed pass-2 token results, keyed by
  /// `{cacheKey}|{brightness}|{lang}|{patch fingerprint}`. Re-enqueuing the
  /// same file returns the cached events synchronously (in the same microtask)
  /// instead of spinning up worker work.
  ///
  /// The patch fingerprint is part of the key because tokens carry the TEXT
  /// the painter draws: the same filename is routinely tokenized from
  /// DIFFERENT patches (the PR "Files changed" diff vs the base branch, a
  /// worktree diff vs the index, a re-diff after an edit landed). Without the
  /// fingerprint those collide and a stale hit paints one patch's text under
  /// another patch's line numbers.
  ///
  /// Only tokens are cached. Pass-1 structure is deliberately NOT retained
  /// here: the sole consumer (`DiffStructureStore`) parses structure
  /// synchronously itself and ignores worker `DiffRawLines` events, so
  /// caching them would keep a second full copy of every file's patch text
  /// resident for the whole session.
  final Map<String, _CachedResult> _cache = {};
  static const int _maxCacheEntries = 128;

  IsolateManager<String, String> _ensureManager() {
    final existing = _manager;
    if (existing != null) {
      return existing;
    }
    final created = IsolateManager<String, String>.createCustom(
      diffWorker,
      workerName: 'diffWorker',
      concurrent: kWorkerCount,
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
    // Re-inserting on write keeps the insertion-ordered Map in
    // least-recently-USED order, so `keys.first` below is the right victim.
    _cache.remove(key);
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
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
      final jobJson = jsonEncode(jobMap);
      var settled = false;
      // NEVER lose highlighting: fall back to the main isolate if the worker
      // errors or never responds. Trips the breaker so the rest of the session
      // skips the dead round-trip.
      void fallback() {
        if (settled) {
          return;
        }
        settled = true;
        _workerUnavailable = true;
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
                  settled = true; // worker finished the job; no fallback needed
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
          final tokens = DiffTokensChunk(
            startIndex: 0,
            tokens: job.tokensByLine ?? const [],
          );
          _putCache(job.cacheKey!, _CachedResult(tokens: tokens));
        }
        if (!job.detached) {
          job.controller
            ..add(const DiffDone())
            ..close();
        }
        _active.remove(fileId);
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
  }

  /// Tears down all workers. Used by tests; the production app keeps the pool
  /// alive for the whole process lifetime.
  Future<void> shutdown() async {
    await _manager?.stop();
    _manager = null;
    _workerUnavailable = false;
    for (final job in _active.values) {
      if (!job.controller.isClosed) {
        await job.controller.close();
      }
    }
    _active.clear();
    _cache.clear();
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

// ─── Main-isolate synchronous parse (no worker) ──────────────────────────────

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

// ─── Wire decoders (main-isolate side) ───────────────────────────────────────

DiffTokensChunk _decodeTok(Map<String, dynamic> e) {
  final startIndex = e[DiffWire.startIndex] as int;
  final lineLens = _ints(e[DiffWire.lineLens]);
  final texts = _strings(e[DiffWire.texts]);
  final colors = _nullableInts(e[DiffWire.colors]);
  final bgs = _nullableInts(e[DiffWire.bgs]);
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

// ─── Internals ─────────────────────────────────────────────────────────────

@immutable
class _CachedResult {
  const _CachedResult({required this.tokens});
  final DiffTokensChunk tokens;
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
