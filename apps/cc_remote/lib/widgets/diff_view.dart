import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
/// There is deliberately no syntax highlighting. The highlighter is a
/// ~250-grammar TextMate registry the desktop ships and tokenizes in a worker;
/// downloading it into the most bandwidth-sensitive tier in the product to
/// colour a handful of changed lines is a bad trade. What a diff actually
/// needs to be readable — which side a line is on, and its number — is carried
/// by the +/− marker, the gutter and the row tint, in that order of
/// precedence. The marker is a character, not a colour, so the diff still
/// reads in greyscale or with red/green colour blindness.
class DiffView extends StatefulWidget {
  /// Creates a [DiffView] over a unified-diff [patch].
  const DiffView({
    super.key,
    required this.patch,
    this.expanded = false,
    this.onExpand,
    this.onLineSelected,
    this.selectedLine,
    this.maxRows,
  });

  /// The file's unified diff, as GitHub returns it (hunks only, no `---`/`+++`
  /// file headers).
  final String patch;

  /// Whether the row budget has been lifted for this file.
  final bool expanded;

  /// Called when the reader asks for the withheld rows. Null hides the
  /// affordance (the diff is already whole).
  final VoidCallback? onExpand;

  /// Called for an added or deleted row only; line numbers are on that side.
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

  @override
  void didUpdateWidget(DiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patch != widget.patch) {
      _lines = parseUnifiedDiff(widget.patch);
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

    final budget =
        widget.maxRows ?? (widget.expanded ? lines.length : kDiffRowBudget);
    final over = lines.length > budget;
    final shown = over ? lines.take(budget) : lines;

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
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // At least as wide as the viewport, so a short line still
                    // paints its tint edge to edge instead of stopping mid-row.
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: IntrinsicWidth(
                      // Required, not decorative. A scroll view hands its child
                      // an UNBOUNDED width, and `CrossAxisAlignment.stretch`
                      // resolves against the incoming maxWidth — so without a
                      // finite width first, every row is asked to lay out at
                      // infinity and the whole block throws. IntrinsicWidth
                      // measures the longest row and makes that the Column's
                      // width, which is also exactly the width the rows should
                      // share. It costs a second measuring pass over the rows,
                      // which is one more reason [kDiffRowBudget] exists.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final line in shown)
                            _DiffRow(
                              line: line,
                              tokens: t,
                              numberFormat: numberFormat,
                              selected:
                                  identical(line, widget.selectedLine) ||
                                  (widget.selectedLine != null &&
                                      line.kind == widget.selectedLine!.kind &&
                                      line.oldLine ==
                                          widget.selectedLine!.oldLine &&
                                      line.newLine ==
                                          widget.selectedLine!.newLine),
                              onPressed:
                                  widget.onLineSelected == null ||
                                      !((line.kind == DiffLineKind.addition &&
                                              line.newLine != null &&
                                              line.newLine! > 0) ||
                                          (line.kind == DiffLineKind.deletion &&
                                              line.oldLine != null &&
                                              line.oldLine! > 0))
                                  ? null
                                  : () => widget.onLineSelected!(line),
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

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.line,
    required this.tokens,
    required this.numberFormat,
    this.onPressed,
    this.selected = false,
  });

  final DiffLine line;
  final DesignSystemTokens tokens;
  final NumberFormat numberFormat;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = tokens;

    if (line.kind == DiffLineKind.expandGap) {
      // The lines between two hunks that the forge never sent. Fetching them
      // needs the file body (`pr_review.watchFileContent`) — a separate,
      // per-file round trip that the desk is the place to spend. Marking the
      // elision is what stops the next hunk's numbering looking like a bug.
      final count = (line.gapNewEnd ?? 0) - (line.newLine ?? 0) + 1;
      return _band(
        t.bgTertiary,
        Text(
          '  ⋯  ${AppLocalizations.of(context).unchangedLines(count)}',
          style: _mono(t.textTertiary),
        ),
      );
    }

    if (line.kind == DiffLineKind.hunkHeader) {
      return _band(
        t.bgTertiary,
        Text(line.content, style: _mono(t.textTertiary), softWrap: false),
      );
    }

    final isAdd = line.kind == DiffLineKind.addition;
    final isDel = line.kind == DiffLineKind.deletion;
    final background = isAdd
        ? t.successSoft
        : isDel
        ? t.dangerSoft
        : null;
    final marker = isAdd
        ? '+'
        : isDel
        ? '-'
        : ' ';

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? t.bgTertiary : background,
        border: selected
            ? Border(left: BorderSide(color: t.textPrimary, width: 2))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: onPressed == null ? 1 : 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _gutter(line.oldLine, t),
            _gutter(line.newLine, t),
            SizedBox(
              width: 14,
              child: Text(
                marker,
                textAlign: TextAlign.center,
                style: _mono(
                  isAdd
                      ? t.textSuccessPrimary
                      : isDel
                      ? t.textErrorPrimary
                      : t.fgQuaternary,
                ),
              ),
            ),
            Text(
              line.content.replaceAll('\t', '  '),
              softWrap: false,
              style: _mono(t.textPrimary),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
    if (onPressed == null) return content;
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: AppLocalizations.of(context).mobilePrCommentOnLine(
        isAdd ? '+' : '-',
        numberFormat.format(isAdd ? line.newLine! : line.oldLine!),
      ),
      builder: (context, _) => content,
    );
  }

  /// A full-width band (hunk header, gap marker) — no gutter, no marker.
  Widget _band(Color color, Widget child) => DecoratedBox(
    decoration: BoxDecoration(color: color),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
    ),
  );

  // RTL carve-out: the gutter lives inside the LTR diff block — its numbers
  // stay right-aligned against the marker column in every locale.
  Widget _gutter(int? number, DesignSystemTokens t) => SizedBox(
    width: 34,
    child: Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        number == null ? '' : numberFormat.format(number),
        textAlign: TextAlign.right,
        style: _mono(t.fgQuaternary),
      ),
    ),
  );

  // Line numbers only line up when digits share a width — `CcFonts.code` is
  // the seam that supplies tabular figures along with the monospace family.
  TextStyle _mono(Color color) => CcFonts.code(
    textStyle: TextStyle(fontSize: 11, height: 1.45, color: color),
  );
}
