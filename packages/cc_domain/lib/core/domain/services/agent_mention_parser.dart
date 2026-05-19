import 'dart:convert';

/// Agent mention parser.
class AgentMentionParser {
  /// Creates a new [AgentMentionParser].
  const AgentMentionParser();

  /// A mention token in prose: starts and ends on a word character and may
  /// carry inner hyphens, so `@code-reviewer` is one token rather than `code`.
  static final RegExp _proseToken = RegExp(
    r'@([A-Za-z0-9_](?:[A-Za-z0-9_-]*[A-Za-z0-9_])?)',
  );

  /// Characters that, immediately before an `@`, mean it is part of a larger
  /// token rather than the start of a mention: an email local part
  /// (`sam@host`), a path (`pkg/@scope`), a version (`node@20`) or a doubled
  /// `@@`.
  static final RegExp _attachedBefore = RegExp(r'[A-Za-z0-9_./\\@-]');

  /// A backtick-delimited inline code span on a single line.
  static final RegExp _inlineCode = RegExp(r'`[^`\n]*`');

  /// Parse mentions.
  List<String> parseMentions(String text) {
    return RegExp(r'@(\w+)')
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toList(growable: false);
  }

  /// Strip mentions.
  String stripMentions(String text) {
    return text.replaceAll(RegExp(r'@\w+\s*'), '').trim();
  }

  /// Parses `@name` mentions out of PROSE — text an agent wrote itself, rather
  /// than a line a human typed into the composer.
  ///
  /// Stricter than [parseMentions] because the input is different in kind: a
  /// composer line is short and deliberate, while a turn is long, quotes code
  /// and pastes logs. Three rules keep an incidental `@` from waking somebody:
  ///
  /// * code is not prose — fenced blocks and inline spans are removed first, so
  ///   a `@Override` in a Java snippet or a `pip install foo@1.2` in a shell
  ///   block cannot mention anyone;
  /// * an `@` glued to the preceding token is an address, a path or a version
  ///   pin, never a mention (`sam@host.com`, `pkg/@scope`, `node@20`);
  /// * a token keeps its inner hyphens, so `@code-reviewer` resolves as itself
  ///   instead of silently reaching an agent whose name starts with `code`.
  ///
  /// Returns lowercase tokens, deduplicated, in order of first appearance.
  /// Resolving those tokens to agents is the caller's job and must be exact —
  /// this parser deliberately reports candidates, not decisions.
  List<String> parseProseMentions(String text) {
    final prose = stripCodeRegions(text);
    final seen = <String>{};
    final tokens = <String>[];
    for (final match in _proseToken.allMatches(prose)) {
      if (match.start > 0 &&
          _attachedBefore.hasMatch(prose[match.start - 1])) {
        continue;
      }
      final token = match.group(1)!.toLowerCase();
      if (seen.add(token)) {
        tokens.add(token);
      }
    }
    return List.unmodifiable(tokens);
  }

  /// Blanks fenced code blocks (``` or ~~~) and inline code spans, preserving
  /// line structure so offsets stay meaningful.
  ///
  /// An unterminated fence blanks everything after it: a turn that was cut off
  /// mid-snippet is the case most likely to contain stray `@`s, so the
  /// conservative reading is the right one.
  String stripCodeRegions(String text) {
    final out = StringBuffer();
    var inFence = false;
    String? openMarker;
    for (final line in LineSplitter.split(text)) {
      final trimmed = line.trimLeft();
      final marker = trimmed.startsWith('```')
          ? '```'
          : (trimmed.startsWith('~~~') ? '~~~' : null);
      if (marker != null) {
        if (!inFence) {
          inFence = true;
          openMarker = marker;
        } else if (marker == openMarker) {
          inFence = false;
          openMarker = null;
        }
        out.writeln();
        continue;
      }
      out.writeln(inFence ? '' : line.replaceAll(_inlineCode, ' '));
    }
    return out.toString();
  }
}
