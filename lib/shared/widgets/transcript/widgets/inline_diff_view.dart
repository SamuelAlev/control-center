import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:flutter/material.dart';

/// Hard tokenize caps per diff side: past either, that side renders plain.
const int _maxHighlightChars = 60 * 1024;
const int _maxHighlightLines = 800;

/// Renders an inline unified diff between [oldText] and [newText] with +/−
/// gutters, green/red row backgrounds, per-line syntax highlighting, and a
/// bounded height. Used for the body of Edit tool cells.
///
/// Each side is tokenized ONCE as a whole block (two tokenizes total — the
/// old code ran one parse per rendered row), which is both cheaper and
/// correct for multi-line constructs (block comments, strings) that a
/// per-row parse loses at line boundaries.
class InlineDiffView extends StatefulWidget {
  /// Creates an [InlineDiffView].
  const InlineDiffView({
    super.key,
    required this.oldText,
    required this.newText,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.maxHeight = 300,
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

  /// Shiki language id, or null for plain text.
  final String? languageId;

  /// Maximum height before the diff scrolls internally.
  final double maxHeight;

  /// Optional override for the shared diff colors (e.g. an imported VS Code
  /// theme). Defaults to [DiffColors.of] so this matches the PR and
  /// session-review diffs.
  final DiffColors? diffColors;

  @override
  State<InlineDiffView> createState() => _InlineDiffViewState();
}

class _InlineDiffViewState extends State<InlineDiffView> {
  final Set<(String, String?, bool)> _pendingAsync = {};

  /// Per-line spans for one side: sync within the grammar's line budget,
  /// async-with-plain-first above it, hard-capped for giant inputs.
  List<List<InlineSpan>> _sideLines(
    String text, {
    required String? languageId,
    required bool dark,
  }) {
    final lineCount = 1 + '\n'.allMatches(text).length;
    if (languageId == null ||
        text.length > _maxHighlightChars ||
        lineCount > _maxHighlightLines) {
      return highlightCodeLines(code: text, languageId: null, dark: dark);
    }
    if (shouldHighlightSynchronously(
      languageId: languageId,
      lineCount: lineCount,
    )) {
      return highlightCodeLines(
        code: text,
        languageId: languageId,
        dark: dark,
      );
    }
    final cached = peekHighlightedLines(
      code: text,
      languageId: languageId,
      dark: dark,
    );
    if (cached != null) {
      return cached;
    }
    final key = (text, languageId, dark);
    if (_pendingAsync.add(key)) {
      highlightCodeLinesAsync(
        code: text,
        languageId: languageId,
        dark: dark,
      ).whenComplete(() {
        if (mounted && _pendingAsync.remove(key)) {
          setState(() {});
        }
      });
    }
    return highlightCodeLines(code: text, languageId: null, dark: dark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = widget.tokens;
    final dark = theme.brightness == Brightness.dark;
    final result = computeLineDiff(widget.oldText, widget.newText);
    final oldLines = _sideLines(
      widget.oldText,
      languageId: widget.languageId,
      dark: dark,
    );
    final newLines = _sideLines(
      widget.newText,
      languageId: widget.languageId,
      dark: dark,
    );
    final baseStyle = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );

    final c = widget.diffColors ?? DiffColors.of(context);
    final addBg = c.additionBg;
    final delBg = c.deletionBg;
    final addMark = c.additionAccent;
    final delMark = c.deletionAccent;

    // Walk the unified rows tracking each side's line cursor so every row can
    // pull its pre-tokenized spans (context rows read the new side — both
    // sides hold identical text there).
    final rows = <_DiffRow>[];
    var oldIndex = 0;
    var newIndex = 0;
    for (final line in result.lines) {
      final List<List<InlineSpan>> side;
      final int index;
      switch (line.kind) {
        case DiffLineKind.del:
          side = oldLines;
          index = oldIndex++;
        case DiffLineKind.add:
          side = newLines;
          index = newIndex++;
        case DiffLineKind.context:
          oldIndex++;
          side = newLines;
          index = newIndex++;
      }
      final spans = index < side.length && side[index].isNotEmpty
          ? side[index]
          : <InlineSpan>[TextSpan(text: line.text)];
      rows.add(
        _DiffRow(
          line: line,
          spans: spans,
          baseStyle: baseStyle,
          addBg: addBg,
          delBg: delBg,
          addMark: addMark,
          delMark: delMark,
          gutterColor: tokens.textQuaternary,
        ),
      );
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.line,
    required this.spans,
    required this.baseStyle,
    required this.addBg,
    required this.delBg,
    required this.addMark,
    required this.delMark,
    required this.gutterColor,
  });

  final DiffLine line;
  final List<InlineSpan> spans;
  final TextStyle baseStyle;
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
              child: Text.rich(TextSpan(style: baseStyle, children: spans)),
            ),
          ),
        ],
      ),
    );
  }
}
