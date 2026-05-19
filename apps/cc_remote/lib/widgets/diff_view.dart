import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

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
class DiffView extends StatelessWidget {
  /// Creates a [DiffView] over a unified-diff [patch].
  const DiffView({
    super.key,
    required this.patch,
    this.expanded = false,
    this.onExpand,
  });

  /// The file's unified diff, as GitHub returns it (hunks only, no `---`/`+++`
  /// file headers).
  final String patch;

  /// Whether the row budget has been lifted for this file.
  final bool expanded;

  /// Called when the reader asks for the withheld rows. Null hides the
  /// affordance (the diff is already whole).
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lines = parseUnifiedDiff(patch);
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No text diff for this file — it is binary, or too large for the '
          'forge to return one.',
          style: TextStyle(fontSize: 12, height: 1.4, color: t.textTertiary),
        ),
      );
    }

    final over = !expanded && lines.length > kDiffRowBudget;
    final shown = over ? lines.take(kDiffRowBudget).toList() : lines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
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
                          _DiffRow(line: line, tokens: t),
                      ],
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
            onPressed: onExpand,
            child: Text(
              'Show the remaining ${lines.length - kDiffRowBudget} lines',
            ),
          ),
        ],
      ],
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.line, required this.tokens});

  final DiffLine line;
  final DesignSystemTokens tokens;

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
          '  ⋯  $count unchanged line${count == 1 ? '' : 's'}',
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

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
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
              // A tab renders as a single narrow glyph in most fonts, which
              // silently destroys the indentation a diff is read by. Expand
              // to two spaces — enough to show nesting without pushing every
              // line off a 44-character column.
              line.content.replaceAll('\t', '  '),
              softWrap: false,
              style: _mono(t.textPrimary),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
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

  Widget _gutter(int? number, DesignSystemTokens t) => SizedBox(
    width: 34,
    child: Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        number?.toString() ?? '',
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
