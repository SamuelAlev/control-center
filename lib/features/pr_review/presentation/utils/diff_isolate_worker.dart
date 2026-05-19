import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:flutter/foundation.dart';
import 'package:highlight/highlight.dart' as hl;

/// Process-singleton pool of 3 long-lived isolates that parse + tokenize PR
/// diffs in two passes (structure first, syntax tokens streamed in chunks).
///
/// Modeled on Pierre's diff pipeline. Pass 1 is cheap — `parseUnifiedDiff` on
/// the patch text — and lets the canvas paint plain text + addition/deletion
/// row backgrounds within ~one frame of opening a file. Pass 2 streams
/// syntax-highlighted tokens back in chunks of [kTokenChunkLines] lines so
/// colour fades in progressively without blocking the UI.
///
/// Each enqueued file gets a generation counter; bumping the generation
/// cancels any pending or in-flight pass-2 chunks for that file.
///
/// The pool is also a [ChangeNotifier] — listeners are pinged whenever the
/// per-worker backlog, the active-job map, or the LRU cache size changes, so
/// a live UI indicator can mirror queue state in real time.
class DiffWorkerPool extends ChangeNotifier {
  DiffWorkerPool._();

  /// Process-wide singleton — kept alive for the whole session.
  static final DiffWorkerPool instance = DiffWorkerPool._();

  /// Number of long-lived worker isolates. Scales with the host CPU so
  /// large PRs (400+ files) get parallel tokenization across all cores
  /// while leaving one core for the UI/main isolate. Clamped to [2, 12]
  /// so low-end devices still get parallelism and very high-core hosts
  /// don't pay the memory overhead of dozens of isolates for diminishing
  /// returns (each isolate has its own ~5–10 MB heap).
  /// On the web there are no isolates — work runs inline on the main thread
  /// (see [enqueue]) — and `Platform.numberOfProcessors` is unsupported and
  /// throws, so the count is fixed to 1 there. `kIsWeb` is a compile-time
  /// const, so the `Platform` call is never evaluated on web.
  static final int kWorkerCount = kIsWeb
      ? 1
      : math.max(2, math.min(12, Platform.numberOfProcessors - 1));

  /// Lines per pass-2 chunk. Trade-off: smaller = smoother fade-in but more
  /// SendPort traffic; larger = fewer messages but visible "stutter" steps.
  /// 200 lines is about one screenful, so the user sees a chunk land just as
  /// the previous one finishes.
  static const int kTokenChunkLines = 200;

  final List<_Worker> _workers = [];
  bool _spawning = false;
  Completer<void>? _readyCompleter;

  /// Active jobs keyed by file ID. Tracks current generation + the stream
  /// controller so out-of-band events from a stale generation can be dropped.
  final Map<String, _ActiveJob> _active = {};

  /// Central job queue. Workers pull from here when they finish their current
  /// job, so a single slow file never blocks others — idle workers pick up
  /// the next pending job immediately.
  final List<_JobRequest> _queue = [];

  /// Workers that are not currently processing a file. When a job is enqueued
  /// and an idle worker exists, the job is dispatched immediately. Otherwise
  /// it sits in [_queue] until a worker becomes idle.
  final Set<_Worker> _idleWorkers = {};

  /// Number of long-lived worker isolates currently spawned. Zero until the
  /// first [enqueue] forces lazy spawn; [kWorkerCount] thereafter.
  int get workerCount => _workers.length;

  /// Per-worker busy count — 0 (idle) or 1 (processing). The order matches
  /// worker IDs 0..N-1. Empty list before the first spawn.
  List<int> get workerBacklogs =>
      List<int>.unmodifiable([for (final w in _workers) w.busy ? 1 : 0]);

  /// Number of files with work currently in flight (not in the LRU cache).
  int get activeJobCount => _active.length;

  /// Number of files currently held in the result LRU cache.
  int get cacheSize => _cache.length;

  /// LRU cache of completed pass-1 + pass-2 results, keyed by
  /// `{cacheKey}|{brightness}|{lang}`. Re-enqueuing the same file returns
  /// the cached events synchronously (in the same microtask) instead of
  /// spinning up isolate work.
  final Map<String, _CachedResult> _cache = {};
  static const int _maxCacheEntries = 1000;

  Future<void> _ensureSpawned() async {
    if (_workers.isNotEmpty) {
      return;
    }
    if (_spawning) {
      return _readyCompleter!.future;
    }
    _spawning = true;
    _readyCompleter = Completer<void>();
    try {
      for (var i = 0; i < kWorkerCount; i++) {
        final worker = await _Worker.spawn(i, _onWorkerEvent, _onWorkerIdle);
        _workers.add(worker);
        _idleWorkers.add(worker);
      }
      _readyCompleter!.complete();
      notifyListeners();
    } catch (e, st) {
      _readyCompleter!.completeError(e, st);
    } finally {
      _spawning = false;
    }
  }

  String _cacheKey(String cacheKey, bool isDark, String? language) =>
      '$cacheKey|${isDark ? 'd' : 'l'}|${language ?? '_'}';

  void _putCache(String key, _CachedResult value) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
    notifyListeners();
  }

  /// Returns the cached pass-1 + pass-2 result for [cacheKey] under the
  /// given [isDark] + [language] combo, or null if absent. Lets a caller
  /// hydrate its UI state synchronously without going through the
  /// [enqueue] stream — useful when a virtualized widget remounts and
  /// would otherwise paint a loading placeholder before the cached
  /// events land via microtask.
  ({DiffRawLines rawLines, DiffTokensChunk tokens})? peekCached({
    required String cacheKey,
    required bool isDark,
    required String? language,
  }) {
    final entry = _cache[_cacheKey(cacheKey, isDark, language)];
    if (entry == null) {
      return null;
    }
    return (rawLines: entry.rawLines, tokens: entry.tokens);
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

  /// Dispatches [job] to an idle worker if one is available, otherwise
  /// appends it to the shared queue.
  void _enqueueOrDispatch(_JobRequest job) {
    if (_idleWorkers.isNotEmpty) {
      final worker = _idleWorkers.first;
      _idleWorkers.remove(worker);
      worker.send(job);
    } else {
      _queue.add(job);
    }
    _scheduleNotify();
  }

  /// Called when a worker finishes a job (Done or Error). Marks the worker
  /// as idle and drains the next pending job from the queue if any.
  void _onWorkerIdle(_Worker worker) {
    _idleWorkers.add(worker);
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _idleWorkers.remove(worker);
      worker.send(next);
    }
    _scheduleNotify();
  }

  /// Enqueues a file for parsing + tokenization. Returns a stream of
  /// [DiffEvent]s — typically `DiffRawLines` first, then 1+ `DiffTokensChunk`
  /// events, then `DiffDone`. Errors arrive as `DiffError`.
  ///
  /// Pass the same [cacheKey] (typically the blob SHA or file path) on
  /// subsequent calls to hit the LRU cache.
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
    final cacheLookup = cacheKey == null
        ? null
        : _cache[_cacheKey(cacheKey, isDark, language)];

    if (cacheLookup != null) {
      scheduleMicrotask(() {
        if (controller.isClosed) {
          return;
        }
        controller
          ..add(cacheLookup.rawLines)
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
      cacheKey: cacheKey == null ? null : _cacheKey(cacheKey, isDark, language),
    );
    _active[fileId] = job;
    _scheduleNotify();

    unawaited(() async {
      if (kIsWeb) {
        // Web has no isolates. Run the parse + tokenize inline on the main
        // thread, deferred to a microtask so the plain-text structure (parsed
        // synchronously by the store) paints first and syntax colour fades in
        // right after. Events route through [_onWorkerEvent] exactly as the
        // isolate path's worker events do, so caching + detach all still work.
        scheduleMicrotask(() {
          if (job.controller.isClosed && !job.detached) {
            return;
          }
          _runJob(
            _JobRequest(
              fileId: fileId,
              generation: generation,
              patch: patch,
              language: language,
              isDark: isDark,
            ),
            _onWorkerEvent,
          );
        });
        return;
      }
      try {
        await _ensureSpawned();
      } catch (e) {
        if (!controller.isClosed) {
          controller.add(DiffError('worker spawn failed: $e'));
          unawaited(controller.close());
        }
        _active.remove(fileId);
        return;
      }
      if (job.controller.isClosed) {
        return;
      }
      _enqueueOrDispatch(
        _JobRequest(
          fileId: fileId,
          generation: generation,
          patch: patch,
          language: language,
          isDark: isDark,
        ),
      );
    }());

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

  void _onWorkerEvent(_WorkerEvent event) {
    final job = _active[event.fileId];
    if (job == null || job.generation != event.generation) {
      // Stale — caller cancelled or bumped generation. Drop silently.
      return;
    }
    // For detached jobs the controller is already closed; we keep
    // processing so the result can land in the LRU cache. Anything else
    // closed is genuinely stale.
    if (job.controller.isClosed && !job.detached) {
      _active.remove(event.fileId);
      return;
    }

    switch (event) {
      case _WorkerRawLinesEvent():
        job.lastRaw = event.payload;
        if (!job.detached) {
          job.controller.add(event.payload);
        }
      case _WorkerTokensChunkEvent():
        job.tokensByLine ??= [];
        // Pad with nulls if chunks arrive out of order or with gaps.
        while (job.tokensByLine!.length < event.payload.startIndex) {
          job.tokensByLine!.add(const []);
        }
        for (var i = 0; i < event.payload.tokens.length; i++) {
          final idx = event.payload.startIndex + i;
          if (idx < job.tokensByLine!.length) {
            job.tokensByLine![idx] = event.payload.tokens[i];
          } else {
            job.tokensByLine!.add(event.payload.tokens[i]);
          }
        }
        if (!job.detached) {
          job.controller.add(event.payload);
        }
      case _WorkerDoneEvent():
        if (job.cacheKey != null && job.lastRaw != null) {
          final tokens = DiffTokensChunk(
            startIndex: 0,
            tokens: job.tokensByLine ?? const [],
          );
          _putCache(
            job.cacheKey!,
            _CachedResult(rawLines: job.lastRaw!, tokens: tokens),
          );
        }
        if (!job.detached) {
          job.controller
            ..add(const DiffDone())
            ..close();
        }
        _active.remove(event.fileId);
      case _WorkerErrorEvent():
        if (!job.detached) {
          job.controller
            ..add(DiffError(event.message))
            ..close();
        }
        _active.remove(event.fileId);
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

  /// Tears down all worker isolates. Used by tests; the production app keeps
  /// the pool alive for the whole process lifetime.
  Future<void> shutdown() async {
    for (final w in _workers) {
      w.kill();
    }
    _workers.clear();
    _idleWorkers.clear();
    _queue.clear();
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

/// Pass-1 result: parsed line structure, no syntax tokens yet.
@immutable
class DiffRawLines extends DiffEvent {
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
  /// `List<Object>` of per-line records, and friendlier to the GC.
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

// ─── Internals ─────────────────────────────────────────────────────────────

@immutable
class _CachedResult {
  const _CachedResult({required this.rawLines, required this.tokens});
  final DiffRawLines rawLines;
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

  /// Last pass-1 payload seen — captured so we can cache the result at done.
  DiffRawLines? lastRaw;

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

@immutable
class _JobRequest {
  const _JobRequest({
    required this.fileId,
    required this.generation,
    required this.patch,
    required this.language,
    required this.isDark,
  });

  final String fileId;
  final int generation;
  final String patch;
  final String? language;
  final bool isDark;
}

@immutable
sealed class _WorkerEvent {
  const _WorkerEvent({required this.fileId, required this.generation});
  final String fileId;
  final int generation;
}

@immutable
class _WorkerRawLinesEvent extends _WorkerEvent {
  const _WorkerRawLinesEvent({
    required super.fileId,
    required super.generation,
    required this.payload,
  });
  final DiffRawLines payload;
}

@immutable
class _WorkerTokensChunkEvent extends _WorkerEvent {
  const _WorkerTokensChunkEvent({
    required super.fileId,
    required super.generation,
    required this.payload,
  });
  final DiffTokensChunk payload;
}

@immutable
class _WorkerDoneEvent extends _WorkerEvent {
  const _WorkerDoneEvent({required super.fileId, required super.generation});
}

@immutable
class _WorkerErrorEvent extends _WorkerEvent {
  const _WorkerErrorEvent({
    required super.fileId,
    required super.generation,
    required this.message,
  });
  final String message;
}

/// One long-lived worker isolate + its plumbing on the main side.
class _Worker {
  _Worker._({
    required this.id,
    required Isolate isolate,
    required SendPort sendPort,
    required ReceivePort receivePort,
    required void Function(_WorkerEvent) onEvent,
    required void Function(_Worker worker) onIdle,
  }) : _isolate = isolate,
       _sendPort = sendPort,
       _receivePort = receivePort {
    _receivePort.listen((dynamic message) {
      if (message is _WorkerEvent) {
        onEvent(message);
        if (message is _WorkerDoneEvent || message is _WorkerErrorEvent) {
          _busy = false;
          onIdle(this);
        }
      }
    });
  }

  final int id;
  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;

  bool _busy = false;

  /// Whether this worker is currently processing a file.
  bool get busy => _busy;

  void send(_JobRequest job) {
    _busy = true;
    _sendPort.send(job);
  }

  void kill() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static Future<_Worker> spawn(
    int id,
    void Function(_WorkerEvent) onEvent,
    void Function(_Worker worker) onIdle,
  ) async {
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerEntrypoint,
      ready.sendPort,
      debugName: 'diff-worker-$id',
    );
    final sendPort = await ready.first as SendPort;
    final mainPort = ReceivePort();
    sendPort.send(mainPort.sendPort);
    return _Worker._(
      id: id,
      isolate: isolate,
      sendPort: sendPort,
      receivePort: mainPort,
      onEvent: onEvent,
      onIdle: onIdle,
    );
  }
}

// ─── Worker side ───────────────────────────────────────────────────────────

void _workerEntrypoint(SendPort ready) {
  final cmdPort = ReceivePort();
  ready.send(cmdPort.sendPort);
  late SendPort eventPort;
  bool gotEventPort = false;

  cmdPort.listen((dynamic message) {
    if (!gotEventPort) {
      eventPort = message as SendPort;
      gotEventPort = true;
      return;
    }
    if (message is _JobRequest) {
      _runJob(message, eventPort.send);
    }
  });
}

/// Pass-1: parses [patch] into the flat-column [DiffRawLines] structure.
///
/// Pure Dart with no Flutter dependency, so the same function backs both the
/// worker isolate's pass-1 and the main-isolate synchronous parse the unified
/// viewer uses to guarantee plain text is always paintable (no loading state).
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

void _runJob(_JobRequest job, void Function(_WorkerEvent) emit) {
  try {
    // ── Pass 1: parse structure ──────────────────────────────────────────
    final parsed = parseUnifiedDiff(job.patch);
    emit(
      _WorkerRawLinesEvent(
        fileId: job.fileId,
        generation: job.generation,
        payload: buildDiffRawLinesFromParsed(parsed),
      ),
    );

    if (parsed.isEmpty) {
      emit(
        _WorkerDoneEvent(fileId: job.fileId, generation: job.generation),
      );
      return;
    }

    // ── Pass 2: tokenize in chunks, accumulate, then apply word-diff ────
    final palette = DiffPalette.forBrightness(
      job.isDark ? Brightness.dark : Brightness.light,
    ).syntax;

    final allTokens = <List<DiffToken>>[];
    const chunkSize = DiffWorkerPool.kTokenChunkLines;
    var chunkStart = 0;
    var chunkBuffer = <List<DiffToken>>[];

    void flushChunk() {
      if (chunkBuffer.isEmpty) {
        return;
      }
      emit(
        _WorkerTokensChunkEvent(
          fileId: job.fileId,
          generation: job.generation,
          payload: DiffTokensChunk(startIndex: chunkStart, tokens: chunkBuffer),
        ),
      );
      chunkStart += chunkBuffer.length;
      chunkBuffer = <List<DiffToken>>[];
    }

    for (var i = 0; i < parsed.length; i++) {
      final line = parsed[i];
      final List<DiffToken> tokens;
      if (line.kind == DiffLineKind.hunkHeader) {
        tokens = [DiffToken(line.hunkHeader ?? '', null)];
      } else {
        tokens = _tokenizeLine(line.content, job.language, palette);
      }
      allTokens.add(tokens);
      chunkBuffer.add(tokens);
      if (chunkBuffer.length >= chunkSize) {
        flushChunk();
      }
    }
    flushChunk();

    // Apply inline word-diff over the accumulated tokens, then emit one
    // patch chunk per contiguous run of lines whose tokens actually changed.
    // (In practice each run = one hunk's addition+deletion block.)
    final specs = <DiffLineSpec>[
      for (var i = 0; i < parsed.length; i++)
        DiffLineSpec(
          kind: parsed[i].kind,
          tokens: allTokens[i],
          oldLine: parsed[i].oldLine,
          newLine: parsed[i].newLine,
          hunkHeader: parsed[i].hunkHeader,
        ),
    ];
    applyInlineWordDiff(specs, palette);

    var runStart = -1;
    final runTokens = <List<DiffToken>>[];
    void flushRun() {
      if (runStart < 0 || runTokens.isEmpty) {
        return;
      }
      emit(
        _WorkerTokensChunkEvent(
          fileId: job.fileId,
          generation: job.generation,
          payload: DiffTokensChunk(
            startIndex: runStart,
            tokens: List<List<DiffToken>>.from(runTokens),
          ),
        ),
      );
      runTokens.clear();
      runStart = -1;
    }

    for (var i = 0; i < specs.length; i++) {
      final updated = specs[i].tokens;
      if (!_tokensEqual(allTokens[i], updated)) {
        runStart = runStart < 0 ? i : runStart;
        runTokens.add(updated);
      } else {
        flushRun();
      }
    }
    flushRun();

    emit(
      _WorkerDoneEvent(fileId: job.fileId, generation: job.generation),
    );
  } catch (e) {
    emit(
      _WorkerErrorEvent(
        fileId: job.fileId,
        generation: job.generation,
        message: e.toString(),
      ),
    );
  }
}

bool _tokensEqual(List<DiffToken> a, List<DiffToken> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].text != b[i].text ||
        a[i].colorValue != b[i].colorValue ||
        a[i].backgroundColorValue != b[i].backgroundColorValue) {
      return false;
    }
  }
  return true;
}

List<DiffToken> _tokenizeLine(
  String code,
  String? language,
  Map<String, int> palette,
) {
  if (language == null || code.isEmpty) {
    return [DiffToken(code, null)];
  }
  hl.Result result;
  try {
    result = hl.highlight.parse(code, language: language);
  } catch (_) {
    return [DiffToken(code, null)];
  }
  final tokens = <DiffToken>[];
  void walk(hl.Node node, int? inheritedColor) {
    final color = node.className != null
        ? (palette[node.className!] ?? inheritedColor)
        : inheritedColor;
    if (node.value != null) {
      tokens.add(DiffToken(node.value!, color));
    } else if (node.children != null) {
      for (final child in node.children!) {
        walk(child, color);
      }
    }
  }

  for (final node in result.nodes ?? const <hl.Node>[]) {
    walk(node, null);
  }
  if (tokens.isEmpty) {
    tokens.add(DiffToken(code, null));
  }
  return tokens;
}
