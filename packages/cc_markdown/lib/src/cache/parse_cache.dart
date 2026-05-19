import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/block_parser.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';
import 'package:meta/meta.dart';

/// LRU parse cache keyed by `(source string, plugin-set identity, options)`.
///
/// Identity keying on the plugin set is sound because [CcPluginSet] is
/// immutable — app-side sets are process-global finals, so the same set instance
/// always means the same grammar. Distinct sets parsing the same string get
/// distinct entries (chat vs GitHub registers must not poison each other).
///
/// [CcParseOptions] participates BY VALUE for the same reason: two registers can
/// share a plugin set yet disagree on grammar toggles (footnotes off in chat,
/// mermaid off in a plain-text surface) and whichever parsed first would
/// otherwise answer for both.
///
/// The LRU touch is O(1): a single [Map] insertion-ordered by recency
/// (remove + reinsert on hit), unlike a list-based access-order queue.
final class CcParseCache {
  /// Creates a cache holding at most [maxSize] parses totalling at most
  /// [maxSourceChars] characters of source.
  CcParseCache({this.maxSize = 200, this.maxSourceChars = 2 * 1024 * 1024});

  /// Maximum number of cached parses.
  final int maxSize;

  /// Maximum total SOURCE length across cached entries.
  ///
  /// The entry count alone does not bound memory: a 500 KB PR body parses to
  /// an AST several times its own size, so 200 of those is not 200 small
  /// things. Source length is a cheap, monotone proxy for AST size — the same
  /// dual bound the syntax highlighter's LRU uses (entries AND chars), which
  /// is the model cache in this repo.
  final int maxSourceChars;

  final Map<_Key, List<CcBlockNode>> _entries = {};

  /// Running sum of `source.length` over [_entries].
  int _sourceChars = 0;

  /// Total source length currently held. Test/diagnostic seam.
  @visibleForTesting
  int get debugSourceChars => _sourceChars;

  /// The cached parse for ([source], [plugins], [options]), or null. Refreshes
  /// recency.
  List<CcBlockNode>? get(
    String source,
    CcPluginSet plugins, {
    CcParseOptions options = const CcParseOptions(),
  }) {
    final key = _Key(source, plugins, options);
    final hit = _entries.remove(key);
    if (hit == null) {
      return null;
    }
    _entries[key] = hit;
    return hit;
  }

  /// Stores [nodes], evicting the least-recently-used entry beyond capacity.
  void put(
    String source,
    CcPluginSet plugins,
    List<CcBlockNode> nodes, {
    CcParseOptions options = const CcParseOptions(),
  }) {
    final key = _Key(source, plugins, options);
    if (_entries.remove(key) != null) {
      _sourceChars -= source.length;
    }
    // An entry larger than the whole budget is never cached: admitting it
    // would evict the entire working set to hold one thing. (Same rule as the
    // highlighter's oversized-item guard.)
    if (source.length > maxSourceChars) {
      return;
    }
    _entries[key] = nodes;
    _sourceChars += source.length;
    while (_entries.length > maxSize ||
        (_sourceChars > maxSourceChars && _entries.length > 1)) {
      _evictOldest();
    }
  }

  void _evictOldest() {
    final oldest = _entries.keys.first;
    _entries.remove(oldest);
    _sourceChars -= oldest.source.length;
  }

  /// Removes one entry. Returns whether it existed.
  bool remove(
    String source,
    CcPluginSet plugins, {
    CcParseOptions options = const CcParseOptions(),
  }) {
    final removed = _entries.remove(_Key(source, plugins, options)) != null;
    if (removed) {
      _sourceChars -= source.length;
    }
    return removed;
  }

  /// Empties the cache.
  void clear() {
    _entries.clear();
    _sourceChars = 0;
  }

  /// Number of cached parses.
  int get length => _entries.length;
}

final class _Key {
  const _Key(this.source, this.plugins, this.options);

  final String source;
  final CcPluginSet plugins;
  final CcParseOptions options;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      identical(plugins, other.plugins) &&
      source == other.source &&
      options == other.options;

  @override
  int get hashCode => Object.hash(source, identityHashCode(plugins), options);
}

/// Process-global parse cache facade with the debug hooks the app's tests
/// use (`debugParseCount`, `debugParseOverride`, `clearCache`).
// Static-only by design: a process-global facade over one cache instance, not
// a thing to instantiate. `abstract final` already forbids both.
// ignore: avoid_classes_with_only_static_members
abstract final class CcMarkdownCache {
  static final CcParseCache _cache = CcParseCache();

  /// Number of real parses (cache misses). Test hook.
  static int debugParseCount = 0;

  /// Overrides the parse function in tests (count/observe without parsing).
  @visibleForTesting
  static List<CcBlockNode> Function(String data, CcPluginSet plugins)?
  debugParseOverride;

  /// Parses [data] through the cache: hit returns the exact cached AST
  /// instance; miss parses, stores and returns.
  static List<CcBlockNode> parseCached(
    String data,
    CcPluginSet plugins, {
    CcParseOptions options = const CcParseOptions(),
  }) {
    final hit = _cache.get(data, plugins, options: options);
    if (hit != null) {
      return hit;
    }
    final nodes = _parse(data, plugins, options);
    _cache.put(data, plugins, nodes, options: options);
    return nodes;
  }

  /// Parses [data], consulting the cache but NEVER inserting — for streaming
  /// intermediates, which are never-again-seen strings whose insertion would
  /// evict real history.
  static List<CcBlockNode> parseEphemeral(
    String data,
    CcPluginSet plugins, {
    CcParseOptions options = const CcParseOptions(),
  }) {
    return _cache.get(data, plugins, options: options) ??
        _parse(data, plugins, options);
  }

  /// Inserts an already-computed parse (the streaming controller's
  /// authoritative final parse seeds the cache through this).
  static void seed(
    String data,
    CcPluginSet plugins,
    List<CcBlockNode> nodes, {
    CcParseOptions options = const CcParseOptions(),
  }) => _cache.put(data, plugins, nodes, options: options);

  /// Clears the process-global cache. Test hook.
  static void clearCache() => _cache.clear();

  static List<CcBlockNode> _parse(
    String data,
    CcPluginSet plugins,
    CcParseOptions options,
  ) {
    debugParseCount++;
    final override = debugParseOverride;
    if (override != null) {
      return override(data, plugins);
    }
    final doc = parseMarkdownDocument(data, options: options, plugins: plugins);
    // Footnote definitions ride at the END of the cached block list (the
    // renderer skips them in normal flow; widgets extract them for the
    // document-end footnote section) so one cached list carries the whole
    // document.
    if (doc.footnotes.isEmpty) {
      return doc.blocks;
    }
    return [...doc.blocks, ...doc.footnotes];
  }
}
