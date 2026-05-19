import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:flutter/widgets.dart';

/// One row of a suggestion's mini diff: the line-number gutter plus the
/// tokenized code, tinted by whether the row is an addition or a deletion.
///
/// Selection is owned by the block's single `CcSelectionRegion`, not per row —
/// a row that owned its own selection could not be part of a drag that crossed
/// into the row below it.
class SuggestionDiffLine extends StatelessWidget {
  /// Creates a [SuggestionDiffLine].
  const SuggestionDiffLine({
    super.key,
    required this.spec,
    required this.style,
    required this.gutterWidth,
  });

  /// The row's kind, tokens and line numbers.
  final DiffLineSpec spec;

  /// The base (monospace) text style.
  final TextStyle style;

  /// Width reserved for the line-number gutter.
  final double gutterWidth;

  @override
  Widget build(BuildContext context) {
    final isAdd = spec.kind == DiffLineKind.addition;
    final bgColor = (isAdd ? const Color(0xFF2DA44E) : const Color(0xFFCF222E))
        .withValues(alpha: 0.10);
    final gutterColor =
        (isAdd ? const Color(0xFF1A7F37) : const Color(0xFFCF222E)).withValues(
          alpha: 0.85,
        );
    final lineNumber = isAdd ? spec.newLine : spec.oldLine;
    // A blank line tokenizes to a single EMPTY token, so its paragraph has no
    // glyph run to measure and falls back to the paragraph style — the comment
    // body's, not the code's, unless the `Text.rich` names one. Pin both
    // columns to the code metrics so the mini diff keeps one rhythm.
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Out of the selection: a copied suggestion must paste as code, not
          // as code with a line number welded to the front of every line.
          SelectionContainer.disabled(
            child: SizedBox(
              width: gutterWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  lineNumber?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: style.copyWith(
                    color: gutterColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  strutStyle: strut,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TokenizedText(
                tokens: spec.tokens,
                baseStyle: style,
                strut: strut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenizedText extends StatelessWidget {
  const _TokenizedText({
    required this.tokens,
    required this.baseStyle,
    required this.strut,
  });
  final List<DiffToken> tokens;
  final TextStyle baseStyle;
  final StrutStyle strut;

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Text(' ', style: baseStyle, strutStyle: strut);
    }

    // Plain `Text.rich`, not `SelectableText`: the ancestor `CcSelectionRegion`
    // owns selection for the whole block so a drag can cross line boundaries.
    return Text.rich(
      TextSpan(
        children: [
          for (final t in tokens)
            TextSpan(
              text: t.text,
              style: baseStyle.copyWith(
                color: t.colorValue != null ? Color(t.colorValue!) : null,
                backgroundColor: t.backgroundColorValue != null
                    ? Color(t.backgroundColorValue!)
                    : null,
              ),
            ),
        ],
      ),
      style: baseStyle,
      strutStyle: strut,
    );
  }
}
