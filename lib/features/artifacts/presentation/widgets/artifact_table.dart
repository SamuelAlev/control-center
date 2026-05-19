import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Renders an [ArtifactTableBlock] as a tokenized data table.
///
/// Scrolls horizontally inside its own box rather than letting a wide table
/// widen the page — the surrounding surface must never scroll sideways.
///
/// Distinct from cc_markdown's table renderer, which draws tables parsed from
/// markdown source. This one takes typed data (columns with keys and alignment,
/// rows as values), which is what an agent produces when it has a result set
/// rather than prose.
class ArtifactTable extends StatelessWidget {
  /// Creates an [ArtifactTable].
  const ArtifactTable({
    super.key,
    required this.columns,
    required this.rows,
    this.compact = false,
  });

  /// Column headers, in display order.
  final List<ArtifactColumn> columns;

  /// Row values, parallel to [columns]. A short row renders blank cells rather
  /// than throwing — a persisted artifact must always come back out.
  final List<List<String>> rows;

  /// Tightens padding and type.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = resolveDesignTokens(context);
    final hPad = compact ? 10.0 : 12.0;
    final vPad = compact ? 6.0 : 8.0;

    final headerStyle = AppTextStyles.labelSmall(tokens).copyWith(
      color: tokens.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final cellStyle =
        (compact
                ? AppTextStyles.bodySmall(tokens)
                : AppTextStyles.bodyMedium(tokens))
            .copyWith(color: tokens.textPrimary, height: 1.35);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // IntrinsicWidth is required, not decorative: a horizontal scroller
          // hands its child unbounded width and `stretch` needs a bounded
          // cross axis. Without it the header/row bands cannot size to the
          // widest row and the column asserts.
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ColoredBox(
                  color: tokens.bgSecondary,
                  child: _Row(
                    cells: [for (final c in columns) c.label],
                    aligns: [for (final c in columns) c.align],
                    style: headerStyle,
                    hPad: hPad,
                    vPad: vPad,
                    isHeader: true,
                  ),
                ),
                for (var r = 0; r < rows.length; r++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tokens.borderSecondary),
                      ),
                      // Zebra striping so a long row stays trackable across a
                      // wide table without relying on the reader's eye alone.
                      color: r.isOdd ? tokens.bgSecondary : null,
                    ),
                    child: _Row(
                      cells: [
                        for (var c = 0; c < columns.length; c++)
                          c < rows[r].length ? rows[r][c] : '',
                      ],
                      aligns: [for (final c in columns) c.align],
                      style: cellStyle,
                      hPad: hPad,
                      vPad: vPad,
                      isHeader: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.cells,
    required this.aligns,
    required this.style,
    required this.hPad,
    required this.vPad,
    required this.isHeader,
  });

  final List<String> cells;
  final List<ArtifactColumnAlign?> aligns;
  final TextStyle? style;
  final double hPad;
  final double vPad;
  final bool isHeader;

  /// Per-column width bounds: wide enough to be readable, capped so one verbose
  /// cell cannot push every other column off-screen.
  static const double _minCellWidth = 88;
  static const double _maxCellWidth = 320;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minCellWidth,
              maxWidth: _maxCellWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Text(
                cells[i],
                style: style,
                textAlign: switch (aligns[i]) {
                  ArtifactColumnAlign.center => TextAlign.center,
                  ArtifactColumnAlign.right => TextAlign.right,
                  ArtifactColumnAlign.left => TextAlign.left,
                  null => TextAlign.left,
                },
              ),
            ),
          ),
      ],
    );
  }
}
