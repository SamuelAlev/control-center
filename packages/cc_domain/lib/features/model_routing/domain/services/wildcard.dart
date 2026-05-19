// ignore_for_file: avoid_classes_with_only_static_members

/// Glob-style wildcard matching.
///
/// `*` matches any run of characters (including none), `?` matches exactly one
/// character. All other regex metacharacters are escaped, and the pattern is
/// anchored (`^…$`). Matching is case-sensitive (provider ids are lowercase).
abstract final class Wildcard {
  static final Map<String, RegExp> _cache = {};

  /// Whether [input] matches the glob [pattern]. Backslashes in [input] are
  /// normalized to forward slashes first.
  static bool match(String input, String pattern) {
    final re = _cache.putIfAbsent(pattern, () => _compile(pattern));
    return re.hasMatch(input.replaceAll(r'\', '/'));
  }

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
