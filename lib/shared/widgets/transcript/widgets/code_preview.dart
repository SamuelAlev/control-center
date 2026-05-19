import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/material.dart';

/// A read-only, syntax-highlighted code block with a line-number gutter and a
/// bounded height (inner scroll past [maxHeight]). Used to render the body of
/// Read / Write tool cells.
class CodePreview extends StatelessWidget {
  /// Creates a [CodePreview].
  const CodePreview({
    super.key,
    required this.code,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.startLine = 1,
    this.maxHeight = 300,
  });

  /// The code to render.
  final String code;

  /// Mono font family.
  final String codeFont;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// `highlight.dart` language id, or null for plain text.
  final String? languageId;

  /// Line number of the first line (Read tools preserve the file offset).
  final int startLine;

  /// Maximum height before the block scrolls internally.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = syntaxPaletteFor(theme.brightness);
    final lines = code.split('\n');
    // Drop a single trailing empty line from a final newline.
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    final gutterWidth = '${startLine + lines.length}'.length;
    final baseStyle = AppFonts.codeDynamic(
      codeFont,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );
    final gutterStyle = baseStyle.copyWith(color: tokens.textQuaternary);

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
                for (var i = 0; i < lines.length; i++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          '${startLine + i}'.padLeft(gutterWidth),
                          style: gutterStyle,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text.rich(
                            TextSpan(
                              style: baseStyle,
                              children: highlightCodeSpans(
                                code: lines[i],
                                languageId: languageId,
                                palette: palette,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
