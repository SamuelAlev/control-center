// ignore_for_file: avoid_classes_with_only_static_members

/// Glob-style wildcard matching.
///
/// `*` matches any run of characters (including none), `?` matches exactly one
/// character. All other regex metacharacters are escaped and the pattern is
/// anchored (`^…$`). Matching is case-sensitive (provider ids are lowercase).
abstract final class Wildcard {
  /// Compiled patterns, most-recently-used last.
  ///
  /// Bounded because the keys are CALLER-SUPPLIED: a routing rule, a policy
  /// glob, an allow-list entry typed into settings. An unbounded static map
  /// keyed on that is a slow leak in a long-lived server process and a
  /// cross-test channel in a short-lived one — the same map is shared by every
  /// test in a file. [_maxCacheEntries] is far above any realistic rule set,
  /// so the eviction path is a backstop rather than something the hot path
  /// hits.
  static final Map<String, RegExp> _cache = {};

  /// Cap on distinct compiled patterns held at once.
  static const int _maxCacheEntries = 256;

  /// Whether [input] matches the glob [pattern]. Backslashes in [input] are
  /// normalized to forward slashes first.
  static bool match(String input, String pattern) {
    // `remove` + re-insert keeps insertion order == recency, which is what
    // makes `_cache.keys.first` the least-recently-used entry below.
    final cached = _cache.remove(pattern);
    final re = cached ?? _compile(pattern);
    if (cached == null && _cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[pattern] = re;
    return re.hasMatch(input.replaceAll(r'\', '/'));
  }

  /// Drops every compiled pattern. For tests that care about compile counts.
  static void clearCache() => _cache.clear();

  /// How many patterns are currently memoized. Test seam for the bound.
  static int get debugCacheSize => _cache.length;

  static RegExp _compile(String pattern) {
    // Normalize backslashes to forward slashes so a pattern authored with `\`
    // matches the normalized input.
    final normalized = pattern.replaceAll(r'\', '/');
    final buf = StringBuffer();
    for (final rune in normalized.runes) {
      final ch = String.fromCharCode(rune);
      switch (ch) {
        case '*':
          buf.write('.*');
        case '?':
          buf.write('.');
        // Escape everything that is meaningful in a RegExp.
        case '.':
        case '+':
        case '^':
        case r'$':
        case '{':
        case '}':
        case '(':
        case ')':
        case '|':
        case '[':
        case ']':
          buf
            ..write(r'\')
            ..write(ch);
        default:
          buf.write(ch);
      }
    }
    // NOTE: a niche `" .*"` → `"( .)?"` trailing-space special
    // case exists for action patterns like `provider.use *`. CC's governance only uses
    // plain resource globs (provider ids, `*`, `*-cn`), never trailing-space
    // patterns, so that quirk is intentionally omitted.
    return RegExp('^${buf.toString()}\$', dotAll: true);
  }
}
