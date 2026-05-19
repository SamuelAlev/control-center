import 'dart:async';
import 'dart:collection';

import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/shared/utils/diff_parser.dart';
import 'package:flutter/foundation.dart';

/// Owns diff line data for the unified viewer, split into two tiers with very
/// different availability guarantees:
///
/// **Structure (pass-1)** — parsed *synchronously on demand* on the main
/// isolate the first time a file is touched, then cached in the [PrDiffDocument]
/// for the rest of the session. `parseUnifiedDiff` is cheap pure-Dart work, so
/// doing it inline the moment a file becomes visible guarantees the painter
/// always has plain text + line numbers + row kinds to draw — there is never a
/// loading placeholder, even on the fastest scrollbar fling. This is the core
/// fix for white space during drag.
///
/// **Tokens (pass-2, syntax colour)** — fetched lazily off the UI thread from
/// the existing [DiffWorkerPool] for files in (or near) the viewport, cached in
/// a bounded LRU, and surfaced through [repaint] so colour fades in over the
/// already-painted plain text without ever blocking a frame.
class DiffStructureStore {
  /// Creates a store backed by [document] (which owns the file list + order).
  DiffStructureStore({
    required this.document,
    required this.maxTokenFiles,
  });

  /// The document whose per-file structure this store fills in.
  final PrDiffDocument document;

  /// Maximum number of files whose syntax tokens are kept resident. Far-away
  /// files' colour is dropped (re-fetched cheaply on return); their structure
  /// stays cached so they still paint plain text instantly.
  final int maxTokenFiles;

  /// Bumped whenever token data changes so the sliver repaints. Exposed as a
  /// [Listenable] the render object can register on its `repaint` channel.
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  bool _isDark = false;

  /// Per-file syntax tokens (`lineIndex -> tokens`), LRU by file index.
  final LinkedHashMap<int, Map<int, List<DiffToken>>> _tokens =
      LinkedHashMap<int, Map<int, List<DiffToken>>>();

  /// Active token subscriptions keyed by file index.
  final Map<int, StreamSubscription<DiffEvent>> _subs = {};

  /// Per-file generation for the worker pool's stale-event cancellation.
  final Map<int, int> _generation = {};

  /// Sets the theme brightness. On change, all cached colour is dropped (it is
  /// brightness-specific) and visible files are re-requested by the caller.
  set isDark(bool value) {
    if (_isDark == value) {
      return;
    }
    _isDark = value;
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _tokens.clear();
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
  /// whose tokens are already cached or in flight are skipped. Files with no
  /// detectable language or an empty patch never request (they paint as plain
  /// text, which is correct).
  void requestTokens(Set<int> wanted) {
    // Cancel in-flight work for files that scrolled away. Their structure
    // stays cached; any partial tokens already landed stay in the LRU.
    final toCancel = _subs.keys.where((i) => !wanted.contains(i)).toList();
    for (final i in toCancel) {
      _subs.remove(i)?.cancel();
    }

    for (final i in wanted) {
      if (_tokens.containsKey(i) || _subs.containsKey(i)) {
        continue;
      }
      final file = document.files[i];
      final language = languageForExtension(file.extension);
      if (language == null || file.patch.isEmpty) {
        continue; // plain text is correct; don't spin up a worker job.
      }
      _startTokenJob(i, file, language);
    }
  }

  void _startTokenJob(int i, PrFile file, String language) {
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
          fileId: 'unified:$i',
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
          case DiffRawLines():
            break; // structure is owned by the main-isolate parse.
          case DiffTokensChunk():
            for (var k = 0; k < event.tokens.length; k++) {
              byLine[event.startIndex + k] = event.tokens[k];
            }
            repaint.value++;
          case DiffDone():
            _subs.remove(i);
            repaint.value++;
          case DiffError():
            _subs.remove(i);
        }
      },
      onError: (Object _) {
        _subs.remove(i);
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
    }
  }

  /// Drops cached structure + tokens for a file (used when a gap expand
  /// re-parses the file with spliced-in context lines).
  void invalidateFile(int i) {
    _subs.remove(i)?.cancel();
    _tokens.remove(i);
  }

  /// Shifts file [i]'s cached tokens to account for a gap expand that replaced
  /// the single gap row at [gapRawIndex] with [insertedCount] context rows.
  /// Token entries above the gap stay put; entries below shift by
  /// `insertedCount - 1`; the gap row itself had no tokens. Newly revealed
  /// context lines stay plain (no tokens) — matching prior behaviour.
  void spliceTokens(int i, int gapRawIndex, int insertedCount) {
    final map = _tokens[i];
    if (map == null) {
      return;
    }
    final shifted = <int, List<DiffToken>>{};
    map.forEach((index, tokens) {
      if (index < gapRawIndex) {
        shifted[index] = tokens;
      } else if (index > gapRawIndex) {
        shifted[index + insertedCount - 1] = tokens;
      }
    });
    _tokens[i] = shifted;
  }

  /// Cancels all in-flight work and clears caches.
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _tokens.clear();
    repaint.dispose();
  }
}
