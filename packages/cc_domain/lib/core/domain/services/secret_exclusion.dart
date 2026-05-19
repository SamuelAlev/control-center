/// Per-workspace secret-exclusion policy: a list of glob patterns whose
/// matching paths are hard-blocked from guest/viewer visibility on every
/// code-bearing surface (file reads, diffs).
///
/// Patterns support `**` (any path segments), `*` (within one segment), and
/// `?` (one character), matched against the repo-relative path with `/`
/// separators. Matching is case-insensitive (secrets hide behind `.Env` as
/// happily as `.env`). An empty pattern list excludes nothing.
class SecretExclusionPolicy {
  /// Compiles [globs]; malformed patterns are dropped (a policy typo must not
  /// take down file reads — the defaults still apply).
  SecretExclusionPolicy(List<String> globs)
    : _patterns = [
        for (final glob in globs)
          if (_compile(glob) case final RegExp pattern) pattern,
      ];

  /// Patterns applied to every workspace on top of the configured list —
  /// the common shapes credentials hide in.
  static const defaultGlobs = <String>[
    '**/.env',
    '**/.env.*',
    '**/*.pem',
    '**/*.key',
    '**/id_rsa*',
    '**/credentials.json',
    '**/secrets.*',
  ];

  final List<RegExp> _patterns;

  /// Whether [path] (repo-relative or absolute) matches an exclusion.
  bool isExcluded(String path) {
    if (_patterns.isEmpty) {
      return false;
    }
    final normalized = path.replaceAll('\\', '/');
    // Match both the full path and its basename-anchored tail so `.env`
    // written without `**/` still protects nested files.
    return _patterns.any((p) => p.hasMatch(normalized));
  }

  static RegExp? _compile(String glob) {
    final trimmed = glob.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final ch = trimmed[i];
      switch (ch) {
        case '*':
          if (i + 1 < trimmed.length && trimmed[i + 1] == '*') {
            buffer.write('.*');
            i++;
            // Collapse a trailing `/` in `**/` so `**/x` also matches `x`.
            if (i + 1 < trimmed.length && trimmed[i + 1] == '/') {
              buffer.write('/?');
              i++;
            }
          } else {
            buffer.write('[^/]*');
          }
        case '?':
          buffer.write('[^/]');
        case '.' ||
            '(' ||
            ')' ||
            '+' ||
            '|' ||
            '^' ||
            r'$' ||
            '{' ||
            '}' ||
            '[' ||
            ']' ||
            r'\':
          buffer.write('\\$ch');
        default:
          buffer.write(ch);
      }
    }
    try {
      // Anchored to segment boundaries: `secrets.*` matches
      // `config/secrets.yaml` but never `my-secrets.yaml/inner`.
      return RegExp('(^|/)${buffer.toString()}\$', caseSensitive: false);
    } catch (_) {
      return null;
    }
  }
}
