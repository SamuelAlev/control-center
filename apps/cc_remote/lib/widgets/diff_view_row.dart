part of 'diff_view.dart';

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.line,
    this.syntax,
    required this.tokens,
    required this.numberFormat,
    this.selected = false,
  });

  final DiffLine line;

  /// Syntax tokens for [line], or null to paint it in the base colour.
  final List<DiffToken>? syntax;

  final DesignSystemTokens tokens;
  final NumberFormat numberFormat;
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
            _code(t),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
    return content;
  }

  /// The row's source text, coloured per token when [syntax] is present.
  /// Tokens without a colour inherit the base text colour.
  Widget _code(DesignSystemTokens t) {
    final syntax = this.syntax;
    if (syntax == null) {
      return Text(
        line.content.replaceAll('\t', '  '),
        softWrap: false,
        style: _mono(t.textPrimary),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          for (final token in syntax)
            TextSpan(
              text: token.text.replaceAll('\t', '  '),
              style: token.colorValue == null
                  ? null
                  : TextStyle(color: Color(token.colorValue!)),
            ),
        ],
      ),
      softWrap: false,
      style: _mono(t.textPrimary),
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
        style: _mono(t.fgSecondary),
      ),
    ),
  );

  // Line numbers only line up when digits share a width — `CcFonts.code` is
  // the seam that supplies tabular figures along with the monospace family.
  TextStyle _mono(Color color) => CcFonts.code(
    textStyle: TextStyle(fontSize: 12, height: 1.4, color: color),
  );
}
