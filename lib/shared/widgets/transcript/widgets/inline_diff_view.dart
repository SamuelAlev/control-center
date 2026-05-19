import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:flutter/material.dart';

/// Renders an inline unified diff between [oldText] and [newText] with +/−
/// gutters, green/red row backgrounds, per-line syntax highlighting, and a
/// bounded height. Used for the body of Edit tool cells.
class InlineDiffView extends StatelessWidget {
  /// Creates an [InlineDiffView].
  const InlineDiffView({
    super.key,
    required this.oldText,
    required this.newText,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.maxHeight = 300,
  });

  /// The original text.
  final String oldText;

  /// The replacement text.
  final String newText;

  /// Mono font family.
  final String codeFont;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// `highlight.dart` language id, or null for plain text.
  final String? languageId;

  /// Maximum height before the diff scrolls internally.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = syntaxPaletteFor(theme.brightness);
    final result = computeLineDiff(oldText, newText);
    final baseStyle = AppFonts.codeDynamic(
      codeFont,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );

    const addBg = Color(0x332DA44E);
    const delBg = Color(0x33CF222E);
    const addMark = Color(0xFF2DA44E);
    const delMark = Color(0xFFCF222E);

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.borderSecondary),
      ),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in result.lines)
                  _DiffRow(
                    line: line,
                    baseStyle: baseStyle,
                    languageId: languageId,
                    palette: palette,
                    addBg: addBg,
                    delBg: delBg,
                    addMark: addMark,
                    delMark: delMark,
                    gutterColor: tokens.textQuaternary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.line,
    required this.baseStyle,
    required this.languageId,
    required this.palette,
    required this.addBg,
    required this.delBg,
    required this.addMark,
    required this.delMark,
    required this.gutterColor,
  });

  final DiffLine line;
  final TextStyle baseStyle;
  final String? languageId;
  final Map<String, int> palette;
  final Color addBg;
  final Color delBg;
  final Color addMark;
  final Color delMark;
  final Color gutterColor;

  @override
  Widget build(BuildContext context) {
    final (bg, mark, markColor) = switch (line.kind) {
      DiffLineKind.add => (addBg, '+', addMark),
      DiffLineKind.del => (delBg, '-', delMark),
      DiffLineKind.context => (const Color(0x00000000), ' ', gutterColor),
    };
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(mark, style: baseStyle.copyWith(color: markColor)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: highlightCodeSpans(
                    code: line.text,
                    languageId: languageId,
                    palette: palette,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
