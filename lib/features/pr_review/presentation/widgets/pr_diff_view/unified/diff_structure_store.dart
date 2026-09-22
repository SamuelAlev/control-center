import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:flutter/foundation.dart';

/// Owns diff line data for the unified viewer, split into two tiers with very
/// different availability guarantees:
///
/// Structure (pass-1) — parsed *synchronously on demand* on the main
/// isolate the first time a file is touched, then cached in the [PrDiffDocument]
/// for the rest of the session. `parseUnifiedDiff` is cheap pure-Dart work, so
/// doing it inline the moment a file becomes visible guarantees the painter
/// always has plain text + line numbers + row kinds to draw — there is never a
/// loading placeholder, even on the fastest scrollbar fling. This is the core
/// fix for white space during drag.
///
/// Tokens (pass-2, syntax colour) — fetched lazily off the UI thread from
/// the existing [DiffWorkerPool] for files in (or near) the viewport, cached in
/// a bounded LRU and surfaced through [repaint] so colour fades in over the
/// already-painted plain text without ever blocking a frame.
class DiffStructureStore {
  /// Creates a store backed by [document] (which owns the file list + order).
  DiffStructureStore({required this.document, required this.maxTokenFiles});

  /// The document whose per-file structure this store fills in.
  final PrDiffDocument document;

  /// Distinguishes this store's worker jobs from other live stores'. The pool
  /// keys in-flight jobs by fileId; two mounted diff views (e.g. the PR Files
  /// tab and the Source control tab) would otherwise both enqueue
  /// `unified:<i>` and silently cancel each other's token streams.
  final int _storeId = _nextStoreId++;
  static int _nextStoreId = 0;

  /// Maximum number of files whose syntax tokens are kept resident. Far-away
  /// files' colour is dropped (re-fetched cheaply on return); their structure
  /// stays cached so they still paint plain text instantly.
  final int maxTokenFiles;

  /// Bumped whenever token data changes so the sliver repaints. Exposed as a
  /// [Listenable] the render object can register on its `repaint` space.
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  bool _isDark = false;

  /// Per-file syntax tokens (`lineIndex -> tokens`), LRU by file index.
  final LinkedHashMap<int, Map<int, List<DiffToken>>> _tokens =
      LinkedHashMap<int, Map<int, List<DiffToken>>>();

  /// Files whose token job ran to a terminal event, so [_tokens] holds every
  /// line it is ever going to hold. Kept in lockstep with [_tokens]: an entry
  /// evicted, invalidated or reset drops out of here too, so "settled" always
  /// implies "resident". [requestTokens] skips exactly these — a file that is
  /// merely *reserved* (its map created when the job started, then cancelled
  /// part-way) must be re-requested, or it would paint plain text forever.
  final Set<int> _settled = {};

  /// Active token subscriptions keyed by file index.
  final Map<int, StreamSubscription<DiffEvent>> _subs = {};

  /// Per-file generation for the worker pool's stale-event cancellation.
  final Map<int, int> _generation = {};

  /// Gap expands applied to each file, in order, in the document's coordinate
  /// space at the time of the expand. Worker chunks always speak pre-expand
  /// patch indices; [_toDocIndex] replays these so a chunk that arrives after
  /// the splice lands on the shifted row.
  final Map<int, List<_IndexSplice>> _splices = {};

  /// Context rows inserted by a gap expand, in current document coordinates.
  /// The patch the worker tokenizes never contains them, so they are coloured
  /// here. A span's first row moves when a later expand above it shifts the file.
  final Map<int, List<_ExpandedSpan>> _spans = {};

  bool _disposed = false;

  /// How many post-image lines above an expanded region are fed to the
  /// grammar so a block comment or string opened in the hunk above stays
  /// open. Bounded so "show end of file" does not re-tokenize the whole file
  /// just to seed state.
  static const int _grammarPrefixLines = 200;

  /// Sets the theme brightness. On change, all cached colour is dropped (it is
  /// brightness-specific) and visible files are re-requested by the caller.
  set isDark(bool value) {
    if (_isDark == value) {
      return;
    }
    _isDark = value;
    resetTokens();
  }

  /// Cancels every in-flight token job and drops all cached syntax colour.
  /// Structure (owned by the [document]) is left intact. Used on theme change
  /// and whenever the file set/order changes — the token caches are keyed by
  /// file index, so reusing them after indices shift would paint one file's
  /// colour onto another. Visible files re-request tokens on the next paint.
  void resetTokens({bool dropExpandedLines = false}) {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _tokens.clear();
    _settled.clear();
    if (dropExpandedLines) {
      _splices.clear();
      _spans.clear();
    } else {
      // Theme swap: the rows stay, their colours do not. Bump epochs so an
      // in-flight highlight of the old theme cannot land in the new map.
      for (final spans in _spans.values) {
        for (final span in spans) {
          span.epoch++;
        }
      }
    }
    repaint.value++;
  }

  /// Whether the current theme is dark.
  bool get isDark => _isDark;

  /// Ensures file [i]'s structure is parsed and cached (synchronously). Returns
  /// the structure. Cheap on a cache hit; a single `parseUnifiedDiff` on a
  /// miss.
  DiffRawLines ensureStructure(int i) {
    final existing = document.structureOf(i);
    if (existing != null) {
      return existing;
    }
    final file = document.files[i];
    final raw = buildDiffRawLines(file.patch);
    document.setStructure(i, raw);
    return raw;
  }

  /// Cached syntax tokens for file [i], or null if not fetched yet. Touches the
  /// LRU so the file stays resident.
  Map<int, List<DiffToken>>? tokensOf(int i) {
    final entry = _tokens.remove(i);
    if (entry == null) {
      return null;
    }
    _tokens[i] = entry; // move to MRU
    return entry;
  }

  /// Requests syntax tokens for the files in [wanted] (typically the visible
  /// window plus a buffer) and releases work for files no longer wanted. Files
  /// whose tokens are fully cached or in flight are skipped. Only files with
  /// an empty patch never request — a language-less file still runs the job so
  /// its word-diff backgrounds apply (its tokens come back plain).
  void requestTokens(Set<int> wanted) {
    // Cancel in-flight work for files that scrolled away. Their structure
    // stays cached. The worker pool keeps a cancelled job running to
    // completion and caches its result, so the re-request when the file
    // scrolls back is a cache hit — but the half-filled (usually still empty)
    // map reserved for it here must go with the subscription. Left behind, it
    // reads to the skip test below as "already coloured" and that file paints
    // plain text for the rest of the session: the same file highlights or not
    // depending only on whether the user scrolled past it quickly.
    final toCancel = _subs.keys.where((i) => !wanted.contains(i)).toList();
    for (final i in toCancel) {
      _subs.remove(i)?.cancel();
      if (!_settled.contains(i)) {
        _tokens.remove(i);
      }
    }

    for (final i in wanted) {
      if (_settled.contains(i) || _subs.containsKey(i)) {
        continue;
      }
      final file = document.files[i];
      final language = shikiLangForPath(file.filename);
      if (file.patch.isEmpty) {
        continue; // nothing to tokenize or word-diff.
      }
      _startTokenJob(i, file, language);
    }
  }

  void _startTokenJob(int i, PrFile file, String? language) {
    final generation = (_generation[i] ?? 0) + 1;
    _generation[i] = generation;
    final byLine = <int, List<DiffToken>>{};
    _tokens[i] = byLine; // reserve the slot so we don't double-request
    _evictTokensIfNeeded();

    // Lifecycle is managed: stored in `_subs[i]` and cancelled in
    // requestTokens / isDark / invalidateFile / dispose.
    // ignore: cancel_subscriptions
    final sub = DiffWorkerPool.instance
        .enqueue(
          fileId: 'unified:$_storeId:$i',
          patch: file.patch,
          language: language,
          isDark: _isDark,
          generation: generation,
          cacheKey: file.filename,
        )
        .listen(
          (event) {
            // Stale guard: a newer request for this file superseded us.
            if (_generation[i] != generation) {
              return;
            }
            switch (event) {
              case DiffTokensChunk():
                for (var k = 0; k < event.tokens.length; k++) {
                  _putWorkerLine(i, event.startIndex + k, event.tokens[k]);
                }
                repaint.value++;
              case DiffDone():
                _subs.remove(i);
                _settled.add(i);
                _colorExpanded(i);
                repaint.value++;
              case DiffError():
                // Terminal too: the tokenizer gave up on this file, so settle
                // it plain rather than re-requesting a failing job every time
                // it re-enters the viewport. Expanded context is independent
                // of the patch job and can still be coloured.
                _subs.remove(i);
                _settled.add(i);
                _colorExpanded(i);
            }
          },
          onError: (Object _) {
            _subs.remove(i);
            _settled.add(i);
            _colorExpanded(i);
          },
        );
    _subs[i] = sub;
  }

  void _evictTokensIfNeeded() {
    while (_tokens.length > maxTokenFiles) {
      final oldest = _tokens.keys.first;
      if (_subs.containsKey(oldest)) {
        // Don't evict a file that's actively streaming; stop at the first
        // resident-but-busy entry to keep eviction O(1) amortised.
        break;
      }
      _tokens.remove(oldest);
      _settled.remove(oldest);
    }
  }

  /// Drops cached structure + tokens for a file (used when a gap expand
  /// re-parses the file with spliced-in context lines).
  void invalidateFile(int i) {
    _subs.remove(i)?.cancel();
    _tokens.remove(i);
    _settled.remove(i);
    _splices.remove(i);
    _spans.remove(i);
  }

  /// Shifts file [i]'s cached tokens to account for a gap expand that replaced
  /// the single gap row at [gapRawIndex] with [insertedLines], then highlights
  /// those rows.
  ///
  /// Call after the document structure has been spliced. Token entries above
  /// the gap stay put; entries below shift by `insertedLines.length - 1`; the
  /// gap row itself had no tokens. The inserted rows are not in the patch, so
  /// they are tokenized on their own, seeded with the post-image lines above
  /// the gap so a comment or string that started in the hunk stays open.
  void spliceTokens(int i, int gapRawIndex, List<String> insertedLines) {
    final insertedCount = insertedLines.length;
    _shiftTokenKeys(i, gapRawIndex, insertedCount);
    (_splices[i] ??= []).add(_IndexSplice(gapRawIndex, insertedCount));
    final spans = _spans[i] ??= [];
    for (final span in spans) {
      if (span.start > gapRawIndex) {
        span.start += insertedCount - 1;
      }
    }
    if (insertedCount > 0) {
      spans.add(_ExpandedSpan(gapRawIndex, List<String>.of(insertedLines)));
    }
    // Recolour this expand and any expanded region below it: a comment opened
    // in the new rows has to flow into what was already revealed.
    _colorExpanded(i, from: gapRawIndex);
    repaint.value++;
  }

  void _shiftTokenKeys(int file, int gap, int insertedCount) {
    final map = _tokens[file];
    if (map == null || map.isEmpty) {
      return;
    }
    final shift = insertedCount - 1;
    final moved = <int, List<DiffToken>>{};
    final remove = <int>[];
    for (final entry in map.entries) {
      if (entry.key == gap) {
        remove.add(entry.key);
      } else if (entry.key > gap) {
        moved[entry.key + shift] = entry.value;
        remove.add(entry.key);
      }
    }
    for (final key in remove) {
      map.remove(key);
    }
    map.addAll(moved);
  }

  /// Maps a worker (pre-expand patch) line index onto the current document,
  /// or null when that index was the gap row a splice removed.
  int? _toDocIndex(int file, int workerIndex) {
    final splices = _splices[file];
    if (splices == null || splices.isEmpty) {
      return workerIndex;
    }
    var idx = workerIndex;
    for (final splice in splices) {
      if (idx == splice.docIndex) {
        return null;
      }
      if (idx > splice.docIndex) {
        idx += splice.inserted - 1;
      }
    }
    return idx;
  }

  void _putWorkerLine(int file, int workerIndex, List<DiffToken> tokens) {
    final map = _tokens[file];
    if (map == null) {
      return;
    }
    final doc = _toDocIndex(file, workerIndex);
    if (doc == null) {
      return;
    }
    map[doc] = tokens;
  }

  /// Highlights expanded regions of [file] whose first row is at or below
  /// [from]. No-op when the token map is not resident yet; the patch job's
  /// terminal event colours them once the map exists.
  void _colorExpanded(int file, {int from = 0}) {
    if (_disposed) {
      return;
    }
    final spans = _spans[file];
    final map = _tokens[file];
    if (spans == null || map == null) {
      return;
    }
    for (final span in spans) {
      if (span.start >= from) {
        _colorSpan(file, span);
      }
    }
  }

  void _colorSpan(int file, _ExpandedSpan span) {
    final epoch = ++span.epoch;
    final dark = _isDark;
    final language = shikiLangForPath(document.files[file].filename);
    final prefix = _grammarPrefix(file, span.start);
    unawaited(() async {
      final tokens = await highlightDiffRegion(
        span.lines,
        prefixLines: prefix,
        languageId: language,
        dark: dark,
      );
      if (_disposed || span.epoch != epoch || _isDark != dark) {
        return;
      }
      final map = _tokens[file];
      final spans = _spans[file];
      if (map == null || spans == null || !spans.contains(span)) {
        return;
      }
      if (tokens == null) {
        return;
      }
      for (var k = 0; k < tokens.length; k++) {
        map[span.start + k] = tokens[k];
      }
      repaint.value++;
    }());
  }

  /// Post-image source above [start], newest-last, for grammar seeding.
  /// Deletions are not in the file the expanded lines belong to. A collapsed
  /// gap ends the walk: the rows above it are not adjacent.
  List<String> _grammarPrefix(int file, int start) {
    final raw = document.structureOf(file);
    if (raw == null || start <= 0) {
      return const [];
    }
    final out = <String>[];
    for (var i = start - 1; i >= 0 && out.length < _grammarPrefixLines; i--) {
      switch (raw.kindAt(i)) {
        case DiffLineKind.expandGap:
          return out.reversed.toList(growable: false);
        case DiffLineKind.hunkHeader:
        case DiffLineKind.deletion:
          continue;
        case DiffLineKind.context:
        case DiffLineKind.addition:
          out.add(raw.contents[i]);
      }
    }
    return out.reversed.toList(growable: false);
  }

  /// Cancels all in-flight work and clears caches.
  void dispose() {
    _disposed = true;
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _tokens.clear();
    _settled.clear();
    _splices.clear();
    _spans.clear();
    repaint.dispose();
  }
}

/// One gap expand, recorded in the document coordinates of that moment.
class _IndexSplice {
  _IndexSplice(this.docIndex, this.inserted);

  /// Document index of the gap row that was replaced.
  final int docIndex;

  /// Context rows that replaced that one gap row.
  final int inserted;
}

/// One run of context rows inserted by a gap expand.
class _ExpandedSpan {
  _ExpandedSpan(this.start, this.lines);

  /// Current document index of [lines]'s first row.
  int start;

  final List<String> lines;

  /// Bumped to drop an in-flight highlight superseded by a theme change or a
  /// recolour of the same rows.
  int epoch = 0;
}
