import 'dart:convert';

import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/shared/widgets/markdown/markdown_worker_core.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Parses large GitHub-flavored markdown documents off the main thread (a real
/// isolate on native, a generated `web/markdownWorker.js` Web Worker on the web)
/// and seeds the process-global [CcMarkdownCache], so the widget's next
/// synchronous `parseCached(source, githubMarkdownPlugins)` is a cache hit that
/// never touches the parser on the UI thread.
///
/// SAFE BY DESIGN: the worker only pre-warms the cache. The rendering widgets'
/// synchronous parse path stays authoritative, so if the worker fails, the
/// codec can't reconstruct a document, or nothing was prefetched, markdown
/// still renders correctly (just parsed inline, exactly as before). The offload
/// can therefore never corrupt or drop content — it only removes jank on
/// re-renders / warmed views of big docs, chiefly on the web (no isolates).
///
/// Only the plugin-free GitHub profile is offloaded (see [markdownWorker]).
/// Chat/streaming markdown (AI plugins) is never routed here.
class MarkdownParsePool {
  MarkdownParsePool._();

  /// Process-wide singleton.
  static final MarkdownParsePool instance = MarkdownParsePool._();

  /// Documents shorter than this parse fast enough inline; offloading them
  /// would cost more (worker round-trip + serialization) than it saves.
  static const int minOffloadChars = 2 * 1024;

  /// Number of concurrent parse workers.
  static const int _concurrency = 2;

  /// Cap on the [_seeded] set — bounds memory while covering the working set of
  /// recently-warmed docs so repeated mounts (scroll virtualization) don't
  /// re-spawn identical parses. Kept below `CcParseCache.maxSize` (200) so a
  /// "seeded" source is unlikely to have been evicted from the real cache.
  static const int _seededCap = 128;

  // P and R are both `String`: the source goes in verbatim, the parsed document
  // comes back as JSON. A Web Worker cannot transfer a Dart Map either way
  // (isolate_manager issue #31), so nothing but strings crosses the boundary.
  IsolateManager<String, String>? _manager;
  final Set<String> _inFlight = {};

  /// Sources already seeded this session (insertion-ordered, bounded to
  /// [_seededCap]). A prefetch for one of these is skipped — the cache is warm.
  final Set<String> _seeded = <String>{};

  IsolateManager<String, String> _ensure() =>
      _manager ??= IsolateManager<String, String>.create(
        markdownWorker,
        workerName: 'markdownWorker',
        concurrent: _concurrency,
      );

  /// Best-effort: parses [source] off the main thread and seeds the cache under
  /// ([source], [plugins]). No-op when the doc is small, the plugin set is not
  /// the offloadable plugin-free profile, or a parse for the same source is
  /// already in flight. Never throws; failures are swallowed because the
  /// synchronous parse path remains correct.
  void prefetch(String source, CcPluginSet plugins) {
    if (source.length < minOffloadChars) {
      return;
    }
    // The worker parses with CcPluginSet.empty + default options. Seeding under
    // any other plugin set would poison that key with a plugin-free parse, so
    // only offload when the caller's set IS the plugin-free one.
    if (!identical(plugins, CcPluginSet.empty)) {
      return;
    }
    if (_seeded.contains(source) || !_inFlight.add(source)) {
      return;
    }
    _ensure()
        .compute(source)
        .then((encoded) {
          final doc = decodeCcDocument(
            jsonDecode(encoded) as Map<String, dynamic>,
          );
          // Match CcMarkdownCache._parse: footnote defs ride at the end of the
          // cached block list so one list carries the whole document.
          final nodes = doc.footnotes.isEmpty
              ? doc.blocks
              : <CcBlockNode>[...doc.blocks, ...doc.footnotes];
          CcMarkdownCache.seed(source, plugins, nodes);
          _seeded.add(source);
          if (_seeded.length > _seededCap) {
            _seeded.remove(_seeded.first);
          }
        })
        .catchError((Object _) {
          // Swallow: the widget's synchronous parseCached stays authoritative.
        })
        .whenComplete(() => _inFlight.remove(source));
  }

  /// Tears down the worker pool (tests; production keeps it for the session).
  Future<void> shutdown() async {
    await _manager?.stop();
    _manager = null;
    _inFlight.clear();
    _seeded.clear();
  }
}
