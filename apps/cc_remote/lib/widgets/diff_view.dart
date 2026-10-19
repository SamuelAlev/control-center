import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/syntax/diff_highlighter.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

part 'diff_view_row.dart';

/// How many diff rows render before the "show the rest" affordance appears.
///
/// A generated lockfile or a vendored bundle arrives as one file with tens of
/// thousands of lines, and this list is nested inside the PR screen's own
/// scroll view — so every row is built eagerly, not lazily. Capping is what
/// keeps tapping a file from freezing the tab; the rest is one tap away and
/// the count says exactly what is being withheld.
const int kDiffRowBudget = 400;

/// Renders one file's unified diff.
///
/// Parsing is [parseUnifiedDiff] from the shared kernel — the SAME function
/// the desktop diff viewer runs, so line numbering, hunk handling and gap
/// detection cannot drift between the two clients.
///
/// Syntax colours come from the desktop's shiki themes and language table
/// (`cc_syntax`), but the tokenizer is a deferred library: rows paint plain
/// first and take their colours once it has loaded, and a language outside
/// the curated tier stays plain. Colour is never what makes the diff
/// readable — which side a line is on, and its number, is carried by the +/−
/// marker, the gutter and the row tint, in that order of precedence. The
/// marker is a character, not a colour, so the diff still reads in greyscale
/// or with red/green colour blindness.
class DiffView extends StatefulWidget {
  /// Creates a [DiffView] over a unified-diff [patch].
  const DiffView({
    super.key,
    required this.patch,
    this.path,
    this.expanded = false,
    this.onExpand,
    this.onLineSelected,
    this.selectedLine,
    this.maxRows,
  });

  /// The file's unified diff, as GitHub returns it (hunks only, no `---`/`+++`
  /// file headers).
  final String patch;

  /// The file's path, which picks the highlighting grammar. Null renders
  /// plain.
  final String? path;

  /// Whether the row budget has been lifted for this file.
  final bool expanded;

  /// Called when the reader asks for the withheld rows. Null hides the
  /// affordance (the diff is already whole).
  final VoidCallback? onExpand;

  /// Called when a changed line is chosen in the touch-sized comment selector.
  final ValueChanged<DiffLine>? onLineSelected;

  /// The selected changed row, highlighted until the composer is dismissed.
  final DiffLine? selectedLine;

  /// Optional incremental cap for large generated files.
  final int? maxRows;
  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  late List<DiffLine> _lines = parseUnifiedDiff(widget.patch);
  final _horizontalScroll = ScrollController();

  /// Syntax tokens for the first `_tokens.length` rows, or null while plain.
  List<List<DiffToken>>? _tokens;

  /// What the latest highlight request covered: rows and theme.
  int _requestedRows = 0;
  bool? _requestedDark;

  /// Bumped whenever the patch or path changes, so a slower earlier result
  /// cannot overwrite the current one.
  int _generation = 0;

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_highlight());
  }

  @override
  void didUpdateWidget(DiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patch != widget.patch || oldWidget.path != widget.path) {
      if (oldWidget.patch != widget.patch) {
        _lines = parseUnifiedDiff(widget.patch);
      }
      _generation++;
      _tokens = null;
      _requestedRows = 0;
      _requestedDark = null;
    }
    unawaited(_highlight());
  }

  int get _budget =>
      widget.maxRows ?? (widget.expanded ? _lines.length : kDiffRowBudget);

  /// Tokenizes the rows the budget shows, when they or the theme changed.
  ///
  /// Only the shown prefix is tokenized: a generated file arrives as one
  /// hunk of tens of thousands of lines, and lifting the budget re-requests
  /// the longer prefix so grammar state still runs from the hunk's start.
  Future<void> _highlight() async {
    final language = diffLanguageForPath(widget.path);
    if (language == null || _lines.isEmpty) {
      return;
    }
    final dark = context.ccTheme?.isDark ?? false;
    final rows = _budget.clamp(0, _lines.length);
    if (dark == _requestedDark && rows <= _requestedRows) {
      return;
    }
    _requestedRows = rows;
    _requestedDark = dark;
    final generation = _generation;
    final tokens = await highlightDiffRows(
      _lines.sublist(0, rows),
      language,
      dark: dark,
    );
    if (!mounted || generation != _generation || _requestedDark != dark) {
      return;
    }
    if (tokens == null) {
      // Plain is the steady state for this language; drop a stale theme's
      // colours rather than keep them.
      if (_tokens != null) {
        setState(() => _tokens = null);
      }
      return;
    }
    if (tokens.length >= (_tokens?.length ?? 0)) {
      setState(() => _tokens = tokens);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final lines = _lines;
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          l10n.noTextDiff,
          style: TextStyle(fontSize: 12, height: 1.4, color: t.textTertiary),
        ),
      );
    }

    final budget = _budget;
    final tokens = _tokens;
    final over = lines.length > budget;
    final shown = over ? lines.take(budget) : lines;
    final commentLines = [
      if (widget.onLineSelected != null)
        for (final line in shown)
          if ((line.kind == DiffLineKind.addition && (line.newLine ?? 0) > 0) ||
              (line.kind == DiffLineKind.deletion && (line.oldLine ?? 0) > 0))
            line,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RTL carve-out: diffs/code are universally LTR — gutters, markers and
        // code order must not mirror with the app locale.
        Directionality(
          textDirection: TextDirection.ltr,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.borderSoft),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              // ONE horizontal scroller around the whole block, gutters
              // included. Pinning the gutter and scrolling only the code needs a
              // controller per row kept in sync, and on a phone the gutter is
              // four characters wide — the width it would save is not worth a
              // scroll position that can disagree with itself.
              child: LayoutBuilder(
                builder: (context, constraints) => CcScrollbar(
                  controller: _horizontalScroll,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (index, line) in shown.indexed)
                              _DiffRow(
                                line: line,
                                syntax: tokens != null && index < tokens.length
                                    ? tokens[index]
                                    : null,
                                tokens: t,
                                numberFormat: numberFormat,
                                selected:
                                    identical(line, widget.selectedLine) ||
                                    (widget.selectedLine != null &&
                                        line.kind ==
                                            widget.selectedLine!.kind &&
                                        line.oldLine ==
                                            widget.selectedLine!.oldLine &&
                                        line.newLine ==
                                            widget.selectedLine!.newLine),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (commentLines.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Keep code dense; the separate selector provides a full phone tap
          // target instead of adding button padding to every source line.
          SizedBox(
            height: kMinTouchTarget,
            child: CcSelect<DiffLine>(
              value: widget.selectedLine,
              semanticLabel: l10n.mobilePrSelectCommentLine,
              hintText: l10n.mobilePrSelectCommentLine,
              options: [
                for (final line in commentLines)
                  CcSelectOption(
                    value: line,
                    label: l10n.mobilePrCommentOnLine(
                      line.kind == DiffLineKind.addition ? '+' : '-',
                      numberFormat.format(
                        line.kind == DiffLineKind.addition
                            ? line.newLine!
                            : line.oldLine!,
                      ),
                    ),
                  ),
              ],
              onChanged: widget.onLineSelected!,
            ),
          ),
        ],
        if (over) ...[
          const SizedBox(height: 8),
          CcButton(
            fullWidth: true,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: widget.onExpand,
            child: Text(l10n.showRemainingLines(lines.length - shown.length)),
          ),
        ],
      ],
    );
  }
}
