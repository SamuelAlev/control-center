import 'package:control_center/core/theme/diff_colors.dart'
    show diffBrightnessOf;
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/widgets.dart';

/// Hard tokenize caps for a code surface. Past either, the block renders plain
/// rather than paying a whole-block parse — a 200KB file tokenized inside
/// `build` is a dropped frame, and no colour is worth that.
const int kCodeHighlightMaxChars = 60 * 1024;

/// Line-count sibling of [kCodeHighlightMaxChars].
const int kCodeHighlightMaxLines = 800;

/// Resolves per-line syntax-highlighted spans for [code] and hands them to
/// [builder].
///
/// ONE home for the budget discipline every code surface needs, so a new one
/// cannot get it subtly wrong (or skip it and jank the frame):
///
///  * inside the grammar's sync line budget → tokenize in `build`, coloured on
///    the first frame;
///  * above it → render PLAIN immediately and tokenize off the UI thread; the
///    result lands in the highlight LRU and the rebuild picks it up;
///  * past the hard caps, or with no language → plain, permanently.
///
/// [builder] always receives one entry per line of [code] (an empty inner list
/// for a blank line), so a caller can lay out a gutter against it without
/// checking whether highlighting actually happened.
class HighlightedCodeLines extends StatefulWidget {
  /// Creates a [HighlightedCodeLines].
  const HighlightedCodeLines({
    super.key,
    required this.code,
    required this.languageId,
    required this.builder,
    this.maxChars = kCodeHighlightMaxChars,
    this.maxLines = kCodeHighlightMaxLines,
  });

  /// The source to highlight. Highlighting is a whole-block parse, so grammar
  /// state (block comments, template literals) carries across lines.
  final String code;

  /// Canonical shiki id, from `shared/syntax/syntax_languages.dart`. Null
  /// renders plain.
  final String? languageId;

  /// Builds the surface from the resolved per-line spans.
  final Widget Function(BuildContext context, List<List<InlineSpan>> lines)
  builder;

  /// Character cap past which the block renders plain.
  final int maxChars;

  /// Line cap past which the block renders plain.
  final int maxLines;

  @override
  State<HighlightedCodeLines> createState() => _HighlightedCodeLinesState();
}

class _HighlightedCodeLinesState extends State<HighlightedCodeLines> {
  /// The async tokenize in flight, so a rebuild does not queue a second one
  /// for the same (code, language, theme).
  (String, String?, bool)? _pendingAsync;

  List<List<InlineSpan>> _lines({required bool dark}) {
    final code = widget.code;
    final languageId = widget.languageId;
    final lineCount = 1 + '\n'.allMatches(code).length;

    if (languageId == null ||
        code.length > widget.maxChars ||
        lineCount > widget.maxLines) {
      return highlightCodeLines(code: code, languageId: null, dark: dark);
    }
    if (shouldHighlightSynchronously(
      languageId: languageId,
      lineCount: lineCount,
    )) {
      return highlightCodeLines(code: code, languageId: languageId, dark: dark);
    }
    final cached = peekHighlightedLines(
      code: code,
      languageId: languageId,
      dark: dark,
    );
    if (cached != null) {
      return cached;
    }
    final key = (code, languageId, dark);
    if (_pendingAsync != key) {
      _pendingAsync = key;
      highlightCodeLinesAsync(
        code: code,
        languageId: languageId,
        dark: dark,
      ).whenComplete(() {
        if (mounted && _pendingAsync == key) {
          setState(() => _pendingAsync = null);
        }
      });
    }
    return highlightCodeLines(code: code, languageId: null, dark: dark);
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _lines(dark: diffBrightnessOf(context) == Brightness.dark),
  );
}

/// Flattens per-line spans back into one run, re-inserting the newlines the
/// per-line form drops. For a surface that renders a whole block as a single
/// `Text.rich` / `SelectableText.rich` rather than row-per-line.
List<InlineSpan> joinCodeLineSpans(List<List<InlineSpan>> lines) {
  final out = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    out.addAll(lines[i]);
    if (i < lines.length - 1) {
      out.add(const TextSpan(text: '\n'));
    }
  }
  return out;
}
