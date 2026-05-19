import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/markdown/highlighted_code_lines.dart';
import 'package:flutter/material.dart';

/// Displays a code block anchored to a specific file and line range,
/// fetched asynchronously from a file content provider.
///
/// The snippet is syntax-highlighted in the app's own shiki theme, resolved
/// from the file's PATH — a review finding always names the file it is about,
/// so the language is never a guess. It is the same treatment markdown fences,
/// tool bodies and the PR diff get; this surface was the odd one out, rendering
/// TypeScript and Dart as flat grey text.
class AnchoredCodeBlock extends StatefulWidget {
  /// Creates an [AnchoredCodeBlock].
  const AnchoredCodeBlock({
    super.key,
    required this.filePath,
    required this.lineNumber,
    required this.fetchFileContent,
    this.lineEnd,
    this.prNumber,
  });

  /// Path of the file to display.
  final String filePath;

  /// Starting line number to anchor to.
  final int lineNumber;

  /// Optional ending line number.
  final int? lineEnd;

  /// Async function that fetches file content given a path.
  final Future<String> Function(String path) fetchFileContent;

  /// Optional PR number for context.
  final int? prNumber;

  @override
  State<AnchoredCodeBlock> createState() => _AnchoredCodeBlockState();
}

/// A fetched file, kept whole alongside its split form.
///
/// The raw text is what the highlighter keys its cache on, so it must not be
/// re-joined per build: two findings in the same file then share one parse.
typedef _Source = ({String text, List<String> lines});

class _AnchoredCodeBlockState extends State<AnchoredCodeBlock> {
  Future<_Source>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant AnchoredCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.lineNumber != widget.lineNumber) {
      _future = _load();
    }
  }

  Future<_Source> _load() => widget
      .fetchFileContent(widget.filePath)
      .then((content) => (text: content, lines: content.split('\n')));

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return FutureBuilder<_Source>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(height: 20, child: Center(child: CcSpinner())),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final source = snapshot.data!;
        final lines = source.lines;
        final startLine = (widget.lineNumber - 3).clamp(0, lines.length - 1);
        final anchorEnd = widget.lineEnd ?? widget.lineNumber;
        final endLine = (anchorEnd + 3).clamp(0, lines.length);
        final visible = lines.sublist(startLine, endLine);

        // Tokenize the WHOLE file when it fits the budget, then take the
        // window out of the result: a snippet lifted out of its file has lost
        // the grammar state that decides whether its first line is inside a
        // block comment or a template literal. Past the caps the window alone
        // is tokenized instead — an occasional wrong colour at a boundary
        // beats a 200KB parse, and both beat flat grey.
        final wholeFileFits =
            source.text.length <= kCodeHighlightMaxChars &&
            lines.length <= kCodeHighlightMaxLines;
        final code = wholeFileFits ? source.text : visible.join('\n');
        final offset = wholeFileFits ? startLine : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: HighlightedCodeLines(
              code: code,
              languageId: shikiLangForPath(widget.filePath),
              builder: (context, highlighted) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++)
                    CodeLineRow(
                      lineNumber: startLine + i + 1,
                      code: visible[i],
                      spans: offset + i < highlighted.length
                          ? highlighted[offset + i]
                          : null,
                      isAnchored:
                          (startLine + i + 1) >= widget.lineNumber &&
                          (startLine + i + 1) <= anchorEnd,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A single row in the anchored code block, showing a line number and code text.
class CodeLineRow extends StatelessWidget {
  /// Creates a [CodeLineRow].
  const CodeLineRow({
    super.key,
    required this.lineNumber,
    required this.code,
    required this.isAnchored,
    this.spans,
  });

  /// The 1-based line number.
  final int lineNumber;

  /// The code text for this line. Also the fallback when [spans] is null.
  final String code;

  /// Highlighted spans for this line. Null renders [code] as plain text.
  final List<InlineSpan>? spans;

  /// Whether this line is part of the anchored range.
  final bool isAnchored;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final isDimmed = !isAnchored;
    // Context lines recede to 0.75 rather than 0.6: they are the reason the
    // anchor is wrong, so they have to stay readable. The anchor is carried by
    // its own tint and by full-strength ink, which is enough of a difference.
    final codeStyle = AppFonts.code(
      textStyle: CcTypography.caption.copyWith(
        height: 1.5,
        color: tokens.textPrimary.withValues(alpha: isDimmed ? 0.75 : 1),
      ),
    );

    return ColoredBox(
      color: isAnchored
          ? tokens.bgBrandPrimary.withValues(alpha: 0.08)
          : const Color(0x00000000),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 1,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '$lineNumber',
                textAlign: TextAlign.right,
                style: AppFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: tokens.textQuaternary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: spans == null
                  ? Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: codeStyle,
                    )
                  : Text.rich(
                      TextSpan(style: codeStyle, children: spans),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
