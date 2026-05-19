import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/highlighted_code_lines.dart';
import 'package:flutter/material.dart';

/// A read-only, syntax-highlighted code block with a line-number gutter and a
/// bounded height (inner scroll past [maxHeight]). Used to render the body of
/// Read / Write tool cells.
///
/// Highlighting is ONE cached whole-block parse split into per-line spans
/// ([HighlightedCodeLines]) — not a parse per line — so rebuilds are cheap and
/// multi-line constructs (block comments, strings) keep their colour across
/// line boundaries. Blocks longer than [maxLines] render only their head with
/// a "Show all N lines" expander.
class CodePreview extends StatefulWidget {
  /// Creates a [CodePreview].
  const CodePreview({
    super.key,
    required this.code,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.startLine = 1,
    this.maxHeight = 300,
    this.maxLines = 500,
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

  /// Maximum rendered lines before the block truncates behind a
  /// "Show all N lines" expander.
  final int maxLines;

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  bool _showAll = false;

  @override
  void didUpdateWidget(covariant CodePreview old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) {
      _showAll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    // Line count of the full block (a single trailing newline doesn't count).
    var totalLines = '\n'.allMatches(widget.code).length + 1;
    if (widget.code.endsWith('\n')) {
      totalLines -= 1;
    }
    final truncated = !_showAll && totalLines > widget.maxLines;

    // Only the rendered head is highlighted while truncated, so a giant file
    // never pays a whole-block parse just to show its first lines.
    final displayCode = truncated
        ? _firstLines(widget.code, widget.maxLines)
        : widget.code;

    final baseStyle = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(
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
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      // No explicit scrollbar: the app-wide [CcScrollBehavior] injects the
      // design-system one, wired to this scrollable's controller.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SelectionArea(
          child: HighlightedCodeLines(
            code: displayCode,
            languageId: widget.languageId,
            builder: (context, highlighted) {
              final lines = highlighted.toList();
              // Drop a single trailing empty line from a final newline.
              if (lines.isNotEmpty &&
                  lines.last.isEmpty &&
                  displayCode.endsWith('\n')) {
                lines.removeLast();
              }
              final gutterWidth = '${widget.startLine + lines.length}'.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Text(
                            '${widget.startLine + i}'.padLeft(gutterWidth),
                            style: gutterStyle,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text.rich(
                              TextSpan(style: baseStyle, children: lines[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (truncated)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CcButton(
                          onPressed: () => setState(() => _showAll = true),
                          variant: CcButtonVariant.ghost,
                          size: CcButtonSize.sm,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).transcriptShowAllLines(totalLines),
                            style: CcTypography.caption.copyWith(
                              color: tokens.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The first [count] lines of [s] (with a trailing newline so the final
  /// rendered line stays terminated like the original).
  static String _firstLines(String s, int count) {
    var index = 0;
    for (var seen = 0; seen < count; seen++) {
      final nl = s.indexOf('\n', index);
      if (nl == -1) {
        return s;
      }
      index = nl + 1;
    }
    return s.substring(0, index);
  }
}
