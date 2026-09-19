import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:flutter/widgets.dart';
import 'package:shiki_flutter/engine.dart' show ThemedToken;

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
    includeExplanation: true,
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
    tokens.add(
      DiffToken(
        text,
        ccArgbForTokenColor(t.color),
        kind: diffTokenKindFromScopes(t.scopes),
      ),
    );
    chars += text.length;
  }
  if (tokens.isEmpty || chars != content.length) {
    return [DiffToken(content, null)];
  }
  return tokens;
}

/// Builds a syntax-colored span for editable or read-only diff text.
TextSpan highlightedDiffTextSpan({
  required String text,
  required String? languageId,
  required bool dark,
  required TextStyle baseStyle,
}) {
  final lines = highlightDiffLines(text, languageId, dark: dark);
  final children = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    for (final token in lines[i]) {
      children.add(
        TextSpan(
          text: token.text,
          style: baseStyle.copyWith(
            color: token.colorValue == null ? null : Color(token.colorValue!),
          ),
        ),
      );
    }
    if (i < lines.length - 1) {
      children.add(const TextSpan(text: '\n'));
    }
  }
  return TextSpan(style: baseStyle, children: children);
}

/// Text controller that keeps editable replacement code syntax highlighted.
class DiffSyntaxTextEditingController extends TextEditingController {
  /// Creates a syntax-highlighting controller.
  DiffSyntaxTextEditingController({
    super.text,
    this.languageId,
    this.dark = false,
  });

  /// Grammar used to tokenize the current text.
  String? languageId;

  /// Whether token colors come from the dark syntax theme.
  bool dark;

  /// Updates the grammar and theme used on the next editable-text build.
  void configure({required String? languageId, required bool dark}) {
    this.languageId = languageId;
    this.dark = dark;
  }

  /// Rebuilds the text spans after a deferred grammar becomes available.
  void refreshHighlighting() => notifyListeners();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return highlightedDiffTextSpan(
      text: text,
      languageId: languageId,
      dark: dark,
      baseStyle: style ?? const TextStyle(),
    );
  }
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
