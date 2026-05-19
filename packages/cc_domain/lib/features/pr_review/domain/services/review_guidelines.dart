// Standing review instructions, and which of them apply to a given PR.
//
// A reviewer that has to be told the same house rule on every pull request is
// not learning, and a rule that applies to `lib/api/**` should not be spent as
// context on a PR that only touches docs. So guidelines carry an optional path
// glob and are filtered against the actual changed files before they reach a
// brief.
//
// Pure: glob matching over strings. The storage (memory facts) and the file
// read (REVIEW.md) both live above this.

/// One standing review instruction.
class ReviewGuideline {
  /// Creates a [ReviewGuideline].
  const ReviewGuideline({
    required this.instruction,
    this.pathGlob,
    this.source = '',
  });

  /// What the reviewer should do.
  final String instruction;

  /// The path glob this applies to, or null for repository-wide.
  final String? pathGlob;

  /// Where the guideline came from, for attribution in the brief.
  final String source;

  /// Whether this guideline is scoped to a path.
  bool get isScoped => pathGlob != null && pathGlob!.isNotEmpty;
}

/// Selects and renders the guidelines that apply to a change.
class ReviewGuidelineResolver {
  /// Creates a [ReviewGuidelineResolver].
  const ReviewGuidelineResolver();

  /// The guidelines in [all] that apply to [changedFiles].
  ///
  /// Unscoped guidelines always apply. A scoped one applies when its glob
  /// matches at least one changed file — matching none means the rule is about
  /// code this PR does not touch, and including it would just crowd out the
  /// rules that do apply.
  List<ReviewGuideline> applicable({
    required List<ReviewGuideline> all,
    required List<String> changedFiles,
  }) => [
    for (final g in all)
      if (!g.isScoped || changedFiles.any((f) => matchesGlob(g.pathGlob!, f)))
        g,
  ];

  /// Renders the applicable guidelines as the brief's guideline section.
  ///
  /// States the precedence explicitly rather than leaving it to be inferred:
  /// when a path rule and a learned suppression disagree, the deliberate rule
  /// wins. A reviewer agent that has to guess which of two instructions
  /// outranks the other will guess differently on different runs.
  String render({
    required List<ReviewGuideline> guidelines,
    String repoInstructions = '',
  }) {
    if (guidelines.isEmpty && repoInstructions.trim().isEmpty) {
      return '';
    }
    final buf = StringBuffer()
      ..writeln('## Review guidelines')
      ..writeln()
      ..writeln(
        'Precedence when these conflict: a path-scoped rule beats a '
        'repository-wide one, and BOTH beat a learned suppression from '
        '`review-suppressions`.',
      )
      ..writeln();

    final scoped = [
      for (final g in guidelines)
        if (g.isScoped) g,
    ];
    final global = [
      for (final g in guidelines)
        if (!g.isScoped) g,
    ];

    if (scoped.isNotEmpty) {
      buf.writeln('### Path-scoped');
      for (final g in scoped) {
        buf.writeln('- `${g.pathGlob}` — ${g.instruction}');
      }
      buf.writeln();
    }
    if (global.isNotEmpty) {
      buf.writeln('### Repository-wide');
      for (final g in global) {
        buf.writeln('- ${g.instruction}');
      }
      buf.writeln();
    }
    if (repoInstructions.trim().isNotEmpty) {
      buf
        ..writeln('### From `REVIEW.md` in the repository')
        ..writeln()
        ..writeln(repoInstructions.trim())
        ..writeln();
    }
    return buf.toString();
  }
}

/// Whether [path] matches [glob].
///
/// Supports the subset that path globs actually use: `**` (any depth), `*`
/// (any characters except `/`), `?` (one character) and `{a,b}` alternation.
/// Anything else is matched literally.
///
/// Hand-rolled rather than pulled from `package:glob` because this lives in
/// the pure domain, which carries no dependencies — and because the matching a
/// review rule needs is a small, stable subset.
bool matchesGlob(String glob, String path) {
  if (glob.isEmpty) {
    return false;
  }
  final normalized = path.replaceAll(r'\', '/');
  // A bare directory prefix (`lib/api`) is the rule people actually write;
  // treat it as `lib/api/**` rather than failing to match anything.
  final effective = glob.contains('*') || glob.contains('?')
      ? glob
      : (glob.endsWith('/') ? '$glob**' : '$glob/**');
  try {
    return RegExp('^${_globToRegExp(effective)}\$').hasMatch(normalized);
  } on FormatException {
    return false;
  }
}

String _globToRegExp(String glob) {
  final buf = StringBuffer();
  for (var i = 0; i < glob.length; i++) {
    final ch = glob[i];
    switch (ch) {
      case '*':
        if (i + 1 < glob.length && glob[i + 1] == '*') {
          i++;
          // `**/` should also match zero directories, so `lib/**/x` matches
          // `lib/x` — otherwise every rule needs two globs to be useful.
          if (i + 1 < glob.length && glob[i + 1] == '/') {
            i++;
            buf.write('(?:.*/)?');
          } else {
            buf.write('.*');
          }
        } else {
          buf.write('[^/]*');
        }
      case '?':
        buf.write('[^/]');
      case '{':
        buf.write('(?:');
      case '}':
        buf.write(')');
      case ',':
        buf.write('|');
      case '.':
      case '(':
      case ')':
      case '[':
      case ']':
      case '+':
      case '^':
      case r'$':
      case '|':
      case r'\':
        buf.write(r'\' + ch);
      default:
        buf.write(ch);
    }
  }
  return buf.toString();
}
