import 'dart:math' as math;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:control_center/shared/widgets/transcript/util/split_diff.dart';
import 'package:flutter/widgets.dart';

/// Narrowest width at which two code panes are still legible side by side.
/// Below it callers fall back to the unified `InlineDiffView` — a 250px pane of
/// code wraps every line and reads worse than the single-column diff.
const double kSplitDiffMinWidth = 560;

/// Renders a **side-by-side** diff between [oldText] and [newText]: the old text
/// in the left pane, the new text in the right, aligned row by row with fillers
/// opposite unbalanced insertions/deletions.
///
/// Both panes carry per-line syntax highlighting from ONE cached whole-side
/// parse ([highlightCodeLines]) — not a parse per line — so multi-line
/// constructs keep their colour and rebuilds are cheap. Changed lines get the
/// shared [DiffColors] row tint plus a stronger word-level tint behind the
/// characters that actually changed, so a one-token edit reads as one token.
/// The `+`/`−` gutter marker means the change is never signalled by colour
/// alone.
///
/// Diffs longer than [maxRows] render only their head behind a "Show all N
/// lines" expander: [maxHeight] bounds how tall the card *looks*, but the rows
/// under it still lay out, and these bodies now render without a click.
class SplitDiffView extends StatefulWidget {
  /// Creates a [SplitDiffView].
  const SplitDiffView({
    super.key,
    required this.oldText,
    required this.newText,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.maxHeight = 300,
    this.maxRows = 400,
    this.diffColors,
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

  /// Maximum rendered rows before the diff truncates behind a "Show all N
  /// lines" expander.
  final int maxRows;

  /// Optional override for the shared diff colors (e.g. an imported VS Code
  /// theme). Defaults to [DiffColors.of].
  final DiffColors? diffColors;

  @override
  State<SplitDiffView> createState() => _SplitDiffViewState();
}

class _SplitDiffViewState extends State<SplitDiffView> {
  bool _showAll = false;
  final Set<(String, String?, bool)> _pendingAsync = {};

  @override
  void didUpdateWidget(covariant SplitDiffView old) {
    super.didUpdateWidget(old);
    if (old.oldText != widget.oldText || old.newText != widget.newText) {
      _showAll = false;
    }
  }

  /// Per-line spans for one side of the diff, tokenizing no more than the
  /// rendered rows ([neededLines]) — the old code tokenized BOTH full sides
  /// to render 400 rows. Rows past the tokenized head render plain via the
  /// `_SplitCell` out-of-range fallback. Above the grammar's sync budget the
  /// tokenize goes async (plain first, colors on rebuild via the LRU).
  List<List<InlineSpan>> _sideLines(
    String text, {
    required String? languageId,
    required bool dark,
    required int neededLines,
  }) {
    var sliced = text;
    var lineCount = 1 + '\n'.allMatches(text).length;
    if (lineCount > neededLines) {
      sliced = text.split('\n').take(neededLines).join('\n');
      lineCount = neededLines;
    }
    if (shouldHighlightSynchronously(
      languageId: languageId,
      lineCount: lineCount,
    )) {
      return highlightCodeLines(
        code: sliced,
        languageId: languageId,
        dark: dark,
      );
    }
    final cached = peekHighlightedLines(
      code: sliced,
      languageId: languageId,
      dark: dark,
    );
    if (cached != null) {
      return cached;
    }
    final key = (sliced, languageId, dark);
    if (_pendingAsync.add(key)) {
      highlightCodeLinesAsync(
        code: sliced,
        languageId: languageId,
        dark: dark,
      ).whenComplete(() {
        if (mounted && _pendingAsync.remove(key)) {
          setState(() {});
        }
      });
    }
    return highlightCodeLines(code: sliced, languageId: null, dark: dark);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final languageId = widget.languageId;
    final dark = diffBrightnessOf(context) == Brightness.dark;
    final allRows = computeSplitDiff(widget.oldText, widget.newText);
    final truncated = !_showAll && allRows.length > widget.maxRows;
    final rows = truncated ? allRows.take(widget.maxRows).toList() : allRows;
    // While truncated, no cell can reference a line index past the rendered
    // row count, so the tokenized head only needs that many lines per side.
    final neededLines = truncated ? widget.maxRows + 1 : (1 << 30);
    final oldLines = _sideLines(
      widget.oldText,
      languageId: languageId,
      dark: dark,
      neededLines: neededLines,
    );
    final newLines = _sideLines(
      widget.newText,
      languageId: languageId,
      dark: dark,
      neededLines: neededLines,
    );
    // Token-driven rather than `Theme.of(context).textTheme.bodySmall`, so this
    // renderer needs no Material ancestor (it also shows inside dialogs) —
    // `caption` is the same 12px annotation grade the unified diff resolves to.
    final baseStyle = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
      ),
    );
    final colors = widget.diffColors ?? DiffColors.of(context);

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
        // The design system's selection island (cc_markdown owns the one
        // Material dependency selection needs), so this file stays widgets-only.
        child: CcSelectionRegion(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in rows)
                _SplitRow(
                  row: row,
                  oldLines: oldLines,
                  newLines: newLines,
                  baseStyle: baseStyle,
                  colors: colors,
                  fillerColor: tokens.bgSecondary,
                  dividerColor: tokens.borderSecondary,
                  gutterColor: tokens.textQuaternary,
                ),
              if (truncated)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CcTappable(
                      onPressed: () => setState(() => _showAll = true),
                      borderRadius: AppRadii.brSm,
                      builder: (context, states) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).transcriptShowAllLines(allRows.length),
                          style: CcTypography.caption.copyWith(
                            color: tokens.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One aligned row: old-side cell | divider | new-side cell. [IntrinsicHeight]
/// makes both cells share the taller side's height, so a line that wraps on one
/// side does not shear the alignment or leave a half-tinted row.
class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.row,
    required this.oldLines,
    required this.newLines,
    required this.baseStyle,
    required this.colors,
    required this.fillerColor,
    required this.dividerColor,
    required this.gutterColor,
  });

  final SplitDiffRow row;
  final List<List<InlineSpan>> oldLines;
  final List<List<InlineSpan>> newLines;
  final TextStyle baseStyle;
  final DiffColors colors;
  final Color fillerColor;
  final Color dividerColor;
  final Color gutterColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              cell: row.left,
              lines: oldLines,
              baseStyle: baseStyle,
              colors: colors,
              fillerColor: fillerColor,
              gutterColor: gutterColor,
            ),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: _Cell(
              cell: row.right,
              lines: newLines,
              baseStyle: baseStyle,
              colors: colors,
              fillerColor: fillerColor,
              gutterColor: gutterColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.cell,
    required this.lines,
    required this.baseStyle,
    required this.colors,
    required this.fillerColor,
    required this.gutterColor,
  });

  final SplitDiffCell? cell;
  final List<List<InlineSpan>> lines;
  final TextStyle baseStyle;
  final DiffColors colors;
  final Color fillerColor;
  final Color gutterColor;

  @override
  Widget build(BuildContext context) {
    final cell = this.cell;
    if (cell == null) {
      // Filler opposite an unbalanced insertion/deletion: a flat neutral band,
      // never an add/remove tint (nothing happened on this side).
      return ColoredBox(color: fillerColor);
    }

    final (bg, mark, markColor, wordBg) = switch (cell.kind) {
      DiffLineKind.add => (
        colors.additionBg,
        '+',
        colors.additionAccent,
        colors.additionWordBg,
      ),
      DiffLineKind.del => (
        colors.deletionBg,
        '-',
        colors.deletionAccent,
        colors.deletionWordBg,
      ),
      DiffLineKind.context => (
        const Color(0x00000000),
        ' ',
        gutterColor,
        const Color(0x00000000),
      ),
    };

    final spans = cell.lineIndex < lines.length
        ? lines[cell.lineIndex]
        : <InlineSpan>[TextSpan(text: cell.text)];
    final rendered = cell.changed.isEmpty
        ? spans
        : applyIntralineBackground(spans, cell.changed, wordBg);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(mark, style: baseStyle.copyWith(color: markColor)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text.rich(TextSpan(style: baseStyle, children: rendered)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Splits [spans] at the boundaries of [ranges] and paints [background] behind
/// the segments that fall inside one, leaving every glyph's syntax colour
/// intact — emphasis comes from the stronger background, like GitHub's word
/// diff (accent-on-accent text is unreadable). Shared by the split diff and
/// the grep match highlighter.
///
/// [spans] must be the flat, leaf-only list [highlightCodeLines] produces, and
/// is never mutated (it is a cache entry).
List<InlineSpan> applyIntralineBackground(
  List<InlineSpan> spans,
  List<IntralineRange> ranges,
  Color background,
) {
  final out = <InlineSpan>[];
  var offset = 0;
  for (final span in spans) {
    final text = span is TextSpan ? span.text : null;
    if (text == null || text.isEmpty) {
      out.add(span);
      continue;
    }
    final style = (span as TextSpan).style;
    final start = offset;
    final end = offset + text.length;
    offset = end;

    var cursor = start;
    for (final range in ranges) {
      final from = math.max(range.$1, start);
      final to = math.min(range.$2, end);
      if (to <= from) {
        continue;
      }
      if (cursor < from) {
        out.add(
          TextSpan(
            text: text.substring(cursor - start, from - start),
            style: style,
          ),
        );
      }
      out.add(
        TextSpan(
          text: text.substring(from - start, to - start),
          style: (style ?? const TextStyle()).copyWith(
            backgroundColor: background,
          ),
        ),
      );
      cursor = to;
    }
    if (cursor < end) {
      out.add(TextSpan(text: text.substring(cursor - start), style: style));
    }
  }
  return out;
}
