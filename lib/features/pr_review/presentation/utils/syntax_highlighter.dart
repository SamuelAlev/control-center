import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:flutter/widgets.dart';
import 'package:shiki_flutter/engine.dart' show ThemedToken;

/// Color used as the base text color in diff content lines.
Color diffCodeColor(BuildContext context) =>
    (context.designSystem ?? DesignSystemTokens.light()).textPrimary;

/// Synchronously tokenizes [text] with shiki and returns one [DiffToken] list
/// per line, coloured by the CC theme for [dark]. Exposed so widgets that
/// render small inline diffs (suggestions, hover previews) can match the PR
/// diff's syntax highlighting without round-tripping through the worker.
///
/// The whole text is ONE tokenize (grammar state carries across lines);
/// language resolution is the caller's job (`shikiLangForPath`). Any failure
/// mode — unknown language, grammar error, row misalignment — degrades to
/// plain tokens for the affected lines, never throws.
List<List<DiffToken>> highlightDiffLines(
  String text,
  String? languageId, {
  required bool dark,
}) {
  final sourceLines = text.split('\n');
  List<List<DiffToken>> plain() => [
    for (final line in sourceLines) [DiffToken(line, null)],
  ];
  if (languageId == null || text.isEmpty) {
    return plain();
  }
  final tokenLines = CcShikiTokenizer.instance.tokenizeSync(
    text,
    langId: languageId,
    dark: dark,
  );
  if (tokenLines == null || tokenLines.length != sourceLines.length) {
    return plain();
  }
  return [
    for (var i = 0; i < sourceLines.length; i++)
      _rowTokens(tokenLines[i], sourceLines[i]),
  ];
}

/// Converts one line's shiki tokens to [DiffToken]s, falling back to a single
/// plain token when the line doesn't round-trip to [content] exactly.
List<DiffToken> _rowTokens(List<ThemedToken> line, String content) {
  final tokens = <DiffToken>[];
  var chars = 0;
  for (final t in line) {
    final text = t.content;
    if (text.isEmpty) {
      continue;
    }
    tokens.add(DiffToken(text, ccArgbForTokenColor(t.color)));
    chars += text.length;
  }
  if (tokens.isEmpty || chars != content.length) {
    return [DiffToken(content, null)];
  }
  return tokens;
}

/// ARGB-int palette feeding the inline word-diff (background washes plus the
/// `addition`/`deletion` fallback tints). Syntax colors no longer come from
/// this map — they are baked in at tokenize time by the CC theme. Kept as
/// plain ints so the worker boundary doesn't need `flutter/material`.
/// Delegates to [DiffPalette].
Map<String, int> diffSyntaxPalette({required bool isDark}) =>
    DiffPalette.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    ).syntax;
