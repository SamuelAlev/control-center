part of 'repo_ide_data_service.dart';

// Pure helpers behind `repos.searchContent`: pathspecs, `git grep` argv,
// option parsing and match windows.

/// Options for [RepoIdeDataService.searchContent], mirroring VS Code's search
/// controls. Defaults (`caseSensitive: false`, `regex: false`, `wholeWord:
/// false`, empty globs) are a case-insensitive literal search, which is what a
/// caller that omits the option map gets.
class SearchContentOptions {
  /// Creates [SearchContentOptions]. All flags default to a case-insensitive,
  /// literal, unglobbed search.
  const SearchContentOptions({
    this.caseSensitive = false,
    this.regex = false,
    this.wholeWord = false,
    this.include = const [],
    this.exclude = const [],
    this.paths = const [],
  });

  /// Case-sensitive matching. When false (default) `git grep` runs with `-i`.
  final bool caseSensitive;

  /// Treat `query` as a regex. When false (default) `git grep` runs with `-F`
  /// (fixed-string); when true the `-F` is dropped.
  final bool regex;

  /// Whole-word matching. Adds `git grep`'s `-w`.
  final bool wholeWord;

  /// Comma/space-separated include pathspecs (matched as path globs after
  /// `git grep`'s `--`). Empty (default) → no include filter.
  final List<String> include;

  /// Comma/space-separated exclude pathspecs (each forwarded as `:!glob`).
  /// Empty (default) → no exclude filter.
  final List<String> exclude;

  /// Exact repo-relative files to grep (a JSON list, never a split string).
  ///
  /// When non-empty these replace [include] as the include pathspecs, so a
  /// PR-scoped search cannot leak into the rest of the tree. [include] then
  /// filters this list (git-style globs) rather than OR-ing onto the whole
  /// tree. Empty (default) → whole-tree grep, optionally narrowed by
  /// [include].
  final List<String> paths;
}

/// Include pathspecs for a grep: exact [SearchContentOptions.paths]
/// (optionally filtered by [SearchContentOptions.include] globs) or, when
/// paths is empty, the include globs themselves.
List<String> _includePathspecs(SearchContentOptions options) {
  if (options.paths.isEmpty) {
    return [
      for (final raw in options.include)
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
  }
  final paths = [
    for (final raw in options.paths)
      if (raw.trim().isNotEmpty) raw.trim(),
  ];
  final globs = [
    for (final raw in options.include)
      if (raw.trim().isNotEmpty) raw.trim(),
  ];
  if (globs.isEmpty) {
    return paths;
  }
  return [
    for (final path in paths)
      if (globs.any((glob) => _pathspecMatches(path, glob))) path,
  ];
}

/// Git's default pathspec glob: `*` matches across `/`, `?` is one character.
bool _pathspecMatches(String path, String glob) {
  final buf = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    switch (c) {
      case '*':
        buf.write('.*');
      case '?':
        buf.write('.');
      default:
        buf.write(RegExp.escape(c));
    }
  }
  buf.write(r'$');
  return RegExp(buf.toString(), caseSensitive: false).hasMatch(path);
}

/// Repo-relative POSIX path if [raw] names a file inside [root], else null.
/// Rejects `..` / absolute escapes so a client-supplied path cannot leave
/// the worktree. Missing files (deleted PR paths) return null.
String? _existingWorktreeRel(String root, String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final joined = p.normalize(p.join(root, trimmed));
  if (joined == root || !p.isWithin(root, joined)) {
    return null;
  }
  if (!File(joined).existsSync()) {
    return null;
  }
  final rel = p.relative(joined, from: root);
  return Platform.isWindows ? rel.replaceAll('\\', '/') : rel;
}

/// Keeps at most [RepoIdeDataService._contentMaxLineChars] of [text]. A match that already
/// fits in the leading window stays put (the client ellipsizes the lead).
/// A match past that window is recentered so the payload still contains it;
/// without this, a hit on a long line is sliced off before the preview can
/// show it. A query our matcher cannot place falls back to the leading
/// window — the same bytes the old truncation sent.
String _clipContentLine(
  String text,
  String query,
  SearchContentOptions options,
) {
  const max = RepoIdeDataService._contentMaxLineChars;
  if (text.length <= max) {
    return text;
  }
  final match = _firstContentMatch(text, query, options);
  if (match == null || match.end <= max) {
    return text.substring(0, max);
  }
  const lead = 80;
  var start = match.start - lead;
  if (start < 0) {
    start = 0;
  }
  var end = start + max;
  if (end > text.length) {
    end = text.length;
    start = end - max;
    if (start < 0) {
      start = 0;
    }
  }
  if (match.start < start) {
    start = match.start;
  }
  if (match.start >= end) {
    start = match.start;
    end = text.length < start + max ? text.length : start + max;
  }
  return text.substring(start, end);
}

/// First match of [query] in [text], using the same case/regex/word flags
/// `git grep` ran with. Null when the pattern is empty or not a Dart regex
/// (git's ERE and Dart's regex are not the same dialect).
RegExpMatch? _firstContentMatch(
  String text,
  String query,
  SearchContentOptions options,
) {
  final q = query.trim();
  if (q.isEmpty) {
    return null;
  }
  final String pattern;
  if (options.regex) {
    pattern = options.wholeWord ? '\\b(?:$q)\\b' : q;
  } else {
    final escaped = RegExp.escape(q);
    pattern = options.wholeWord ? '\\b$escaped\\b' : escaped;
  }
  try {
    return RegExp(
      pattern,
      caseSensitive: options.caseSensitive,
    ).firstMatch(text);
  } on FormatException {
    return null;
  }
}

/// Builds the `git grep` argv for [query] under [options].
///
/// The defaults (`caseSensitive: false`, `regex: false`) emit
/// `-i -F`. Whole-word adds `-w`; regex replaces `-F` with `-E` (extended
/// regex — git grep's default BRE doesn't recognise `\d` etc.). Include/
/// exclude globs become pathspecs after `--`: a default pathspec already
/// treats `*` as a wildcard across the whole path (so `*skip.dart` matches
/// `lib/skip.dart`) and excludes are prefixed with `:(exclude)`. The argv is
/// bounded by [RepoIdeDataService._contentMaxPathspecs] defensively, except when
/// [includeOverride] is a pre-batched chunk of exact paths (already sized).
List<String> _buildGrepArgs(
  String query,
  SearchContentOptions options, {
  List<String>? includeOverride,
}) {
  final args = <String>[
    'grep',
    '-n',
    '-I',
    '--untracked',
    '--no-color',
    if (!options.caseSensitive) '-i',
    if (options.regex) '-E' else '-F',
    if (options.wholeWord) '-w',
    '-e',
    query,
  ];
  final includes =
      includeOverride ??
      [
        for (final raw in options.include)
          if (raw.trim().isNotEmpty) raw.trim(),
      ];
  final pathspecs = <String>[];
  var count = 0;
  final includeCap = includeOverride != null
      ? includes.length
      : RepoIdeDataService._contentMaxPathspecs;
  for (final glob in includes) {
    if (count >= includeCap) {
      break;
    }
    pathspecs.add(glob);
    count++;
  }
  for (final raw in options.exclude) {
    if (includeOverride == null &&
        count >= RepoIdeDataService._contentMaxPathspecs) {
      break;
    }
    final glob = raw.trim();
    if (glob.isEmpty) {
      continue;
    }
    pathspecs.add(':(exclude)$glob');
    count++;
  }
  if (pathspecs.isNotEmpty) {
    args
      ..add('--')
      ..addAll(pathspecs);
  }
  return args;
}

/// Parses the wire `options` map into [SearchContentOptions]. Tolerates a
/// missing map and wrong-typed values (each falls back to the default).
SearchContentOptions _parseSearchOptions(Map<String, Object?> options) {
  bool boolOpt(String key) {
    final v = options[key];
    return v is bool ? v : false;
  }

  List<String> listOpt(String key) {
    final v = options[key];
    if (v is List) {
      return v.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) {
      // Accept a single comma/space-separated glob string for ergonomics.
      return v
          .split(RegExp(r'[,\s]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  // Exact file paths must stay a JSON list — comma-splitting would break
  // paths with spaces and would OR a joined blob as one glob.
  List<String> pathsOpt() {
    final v = options['paths'];
    if (v is List) {
      return v.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  return SearchContentOptions(
    caseSensitive: boolOpt('case_sensitive'),
    regex: boolOpt('regex'),
    wholeWord: boolOpt('whole_word'),
    include: listOpt('include'),
    exclude: listOpt('exclude'),
    paths: pathsOpt(),
  );
}
