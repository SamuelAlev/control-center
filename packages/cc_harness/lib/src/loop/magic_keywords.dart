import 'package:cc_harness/src/provider/reasoning_effort.dart';

/// A standalone lowercase word that attaches a hidden instruction to one turn.
class MagicKeyword {
  /// Creates a [MagicKeyword].
  const MagicKeyword({
    required this.word,
    required this.instruction,
    this.effort,
  });

  /// The exact lowercase spelling that triggers it.
  final String word;

  /// The hidden instruction appended to the turn.
  final String instruction;

  /// Reasoning effort this keyword forces for the turn, when it forces one.
  final ReasoningEffort? effort;
}

/// The built-in keywords.
///
/// Deliberately few. Each one is a mode the user cannot otherwise reach
/// mid-sentence, and every additional word is another way for ordinary prose
/// to change agent behaviour by accident.
const List<MagicKeyword> builtinMagicKeywords = [
  MagicKeyword(
    word: 'ultrathink',
    // The whole point is "use everything you have", so this is the ceiling,
    // not merely a step up from the default.
    effort: ReasoningEffort.xhigh,
    instruction:
        'Think carefully and at length before acting. Work the problem '
        'through step by step, consider the failure modes, and check your '
        'reasoning before you commit to an approach.',
  ),
  MagicKeyword(
    word: 'orchestrate',
    instruction:
        'Treat this as substantial work to be run in parallel. Scope the full '
        'task first, split it into genuinely independent pieces, delegate '
        'them concurrently with the task tool, and VERIFY each result before '
        'building on it. Keep going until the whole request is complete — do '
        'not stop after the first phase.',
  ),
];

// Boundary matching is the entire difficulty here, and getting it wrong is
// worse than not having the feature: prose is not the only thing a user
// pastes. A stack trace containing `orchestrate.ts`, a path like
// `src/orchestrate/`, or a Rust call `foo::orchestrate()` must NOT silently
// change how the agent behaves.
//
// Left:  not preceded by a word character, digit, `_`, `.`, `/`, `\` or `-`,
//        and not by `::`.
// Right: not followed by a word character, digit, `_`, `/`, `\` or `-`; not by
//        `.` + an identifier character (so `orchestrate.ts` is out but
//        `orchestrate.` at the end of a sentence is in); and not by `(`.
const String _leftBoundary = r'(?<![\w\d_./\\-])(?<!::)';
const String _rightBoundary = r'(?![\w\d_/\\-])(?!\.[\w\d_-])(?!\()';

/// Matches [keyword] as a standalone word.
RegExp magicKeywordPattern(String keyword) =>
    RegExp('$_leftBoundary${RegExp.escape(keyword)}$_rightBoundary');

/// Replaces fenced code blocks, inline code spans and XML/HTML sections with
/// spaces, so a keyword inside them cannot trigger.
///
/// Same length in, same length out — offsets stay valid for the caller.
String maskNonProse(String text) {
  final masked = List<String>.from(text.split(''));
  void blank(int start, int end) {
    for (var i = start; i < end && i < masked.length; i++) {
      if (masked[i] != '\n') {
        masked[i] = ' ';
      }
    }
  }

  for (final match in RegExp(r'```[\s\S]*?```').allMatches(text)) {
    blank(match.start, match.end);
  }
  for (final match in RegExp(r'~~~[\s\S]*?~~~').allMatches(text)) {
    blank(match.start, match.end);
  }
  for (final match in RegExp('`[^`\n]*`').allMatches(text)) {
    blank(match.start, match.end);
  }
  // An opening tag through its closing tag, and self-closing/standalone tags.
  for (final match in RegExp(
    r'<([A-Za-z][\w-]*)\b[^>]*>[\s\S]*?</\1>',
  ).allMatches(text)) {
    blank(match.start, match.end);
  }
  for (final match in RegExp(r'<[^>\n]{1,200}>').allMatches(text)) {
    blank(match.start, match.end);
  }
  return masked.join();
}

/// The keywords present in [text] as standalone prose words.
///
/// Cheap on the common path: three `indexOf` probes before any regex or
/// masking work, because this runs on every prompt.
List<MagicKeyword> detectMagicKeywords(
  String text, {
  List<MagicKeyword> keywords = builtinMagicKeywords,
  Set<String> disabled = const {},
}) {
  final candidates = [
    for (final keyword in keywords)
      if (!disabled.contains(keyword.word) && text.contains(keyword.word))
        keyword,
  ];
  if (candidates.isEmpty) {
    return const [];
  }
  final prose = maskNonProse(text);
  return [
    for (final keyword in candidates)
      if (magicKeywordPattern(keyword.word).hasMatch(prose)) keyword,
  ];
}

/// The hidden instruction block for [keywords], or null when there is none.
///
/// The visible prompt is deliberately left untouched: the user sees the word
/// they typed, and the instruction rides alongside. Rewriting their message
/// would make the transcript disagree with what they wrote.
String? magicKeywordDirective(List<MagicKeyword> keywords) {
  if (keywords.isEmpty) {
    return null;
  }
  return keywords.map((k) => k.instruction).join('\n\n');
}

/// The strongest effort any of [keywords] demands, or null.
ReasoningEffort? magicKeywordEffort(List<MagicKeyword> keywords) {
  ReasoningEffort? best;
  for (final keyword in keywords) {
    final effort = keyword.effort;
    if (effort == null) {
      continue;
    }
    if (best == null || effort.index > best.index) {
      best = effort;
    }
  }
  return best;
}
