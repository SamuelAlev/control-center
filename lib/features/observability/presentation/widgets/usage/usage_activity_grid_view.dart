import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
// `intl` exports its own `TextDirection`, which would shadow the `dart:ui` one
// the painter needs for `TextPainter`.
import 'package:intl/intl.dart' hide TextDirection;

/// The token-activity calendar: one column per ISO week, seven day cells each,
/// with month labels beneath — the trailing year of token usage at a glance.
///
/// The grid is PAINTED rather than built from a widget per cell: a year is
/// ~371 cells, and that many [MouseRegion]s (one per cell, as a widget-based
/// grid needs for hover) costs a hit-test walk over every one of them on each
/// pointer move. A single painter plus one region that resolves the hovered
/// cell arithmetically keeps the surface cheap.
///
/// Intensity never reports alone: hovering reads the exact figure out above
/// the grid, and the whole grid carries a semantic summary for a screen
/// reader.
class UsageActivityGridView extends StatefulWidget {
  /// Creates a [UsageActivityGridView].
  const UsageActivityGridView({super.key, required this.grid});

  /// The grid to render.
  final UsageActivityGrid grid;

  /// Side length of one day cell.
  static const double cellSize = 11;

  /// Gap between adjacent cells, both axes.
  static const double cellGap = 3;

  /// Height reserved under the grid for the month labels.
  static const double monthLabelHeight = 18;

  /// The full pitch of one column (and of one row).
  static const double columnPitch = cellSize + cellGap;

  @override
  State<UsageActivityGridView> createState() => _UsageActivityGridViewState();
}

class _UsageActivityGridViewState extends State<UsageActivityGridView> {
  UsageActivityCell? _hovered;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final grid = widget.grid;

    if (grid.weeks.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.chartColumn,
        message: l10n.obsUsageNoActivity,
      );
    }

    final width =
        grid.weeks.length * UsageActivityGridView.columnPitch -
        UsageActivityGridView.cellGap;
    const gridHeight =
        7 * UsageActivityGridView.columnPitch - UsageActivityGridView.cellGap;
    final hovered = _hovered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The readout is reserved above the grid so the layout never reflows
        // as the pointer moves between cells.
        SizedBox(
          height: 18,
          child: hovered == null
              ? null
              : Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.obsUsageCellReadout(
                      DateFormat.MMMd(locale).format(hovered.day),
                      fmtTokens(hovered.value),
                    ),
                    style: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: _semanticSummary(l10n, locale, grid),
          excludeSemantics: true,
          child: CcScrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Anchored to the end so the most recent weeks are the ones on
              // screen when the year overflows the panel.
              reverse: true,
              child: MouseRegion(
                onHover: (event) => _updateHover(event.localPosition),
                onExit: (_) => _clearHover(),
                child: SizedBox(
                  width: width,
                  height: gridHeight + UsageActivityGridView.monthLabelHeight,
                  child: CustomPaint(
                    painter: _ActivityGridPainter(
                      grid: grid,
                      emptyColor: t.bgQuaternary,
                      peakColor: t.bgBrandSolid,
                      labelStyle: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                        fontSize: 10,
                      ),
                      monthLabel: (month) =>
                          DateFormat.MMM(locale).format(month),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Resolves the cell under [position] arithmetically, so a pointer move
  /// costs a couple of divisions rather than a hit-test walk over the year.
  void _updateHover(Offset position) {
    final column = position.dx ~/ UsageActivityGridView.columnPitch;
    final row = position.dy ~/ UsageActivityGridView.columnPitch;
    if (column < 0 ||
        column >= widget.grid.weeks.length ||
        row < 0 ||
        row >= 7) {
      _clearHover();
      return;
    }
    final cell = widget.grid.weeks[column][row];
    if (cell != _hovered) {
      setState(() => _hovered = cell);
    }
  }

  void _clearHover() {
    if (_hovered != null) {
      setState(() => _hovered = null);
    }
  }

  /// A one-line spoken summary — the window covered, how many days were
  /// active and the busiest figure — rather than 371 unreadable cell values.
  String _semanticSummary(
    AppLocalizations l10n,
    String locale,
    UsageActivityGrid grid,
  ) {
    final cells = [
      for (final week in grid.weeks) ...week.whereType<UsageActivityCell>(),
    ];
    if (cells.isEmpty) {
      return l10n.obsUsageNoActivity;
    }
    final format = DateFormat.yMMMd(locale);
    return l10n.obsUsageActivitySummary(
      format.format(cells.first.day),
      format.format(cells.last.day),
      cells.where((c) => c.value > 0).length,
      fmtTokens(grid.maxValue),
    );
  }
}

/// Paints the day cells and the month labels beneath them.
class _ActivityGridPainter extends CustomPainter {
  _ActivityGridPainter({
    required this.grid,
    required this.emptyColor,
    required this.peakColor,
    required this.labelStyle,
    required this.monthLabel,
  });

  final UsageActivityGrid grid;
  final Color emptyColor;
  final Color peakColor;
  final TextStyle labelStyle;
  final String Function(DateTime monthStart) monthLabel;

  /// Level 1..4 as a mix toward [peakColor]. Level 0 stays [emptyColor], so an
  /// untouched day reads as a placeholder rather than as a faint value.
  static const List<double> _levelMix = [0, 0.28, 0.5, 0.75, 1];

  @override
  void paint(Canvas canvas, Size size) {
    const cell = UsageActivityGridView.cellSize;
    const pitch = UsageActivityGridView.columnPitch;
    final paint = Paint()..style = PaintingStyle.fill;

    // Square cells: AppRadii is 0 across the scale by design — "the contrast
    // between soft warm color and hard architectural geometry is deliberate".
    for (var column = 0; column < grid.weeks.length; column++) {
      for (var row = 0; row < 7; row++) {
        final entry = grid.weeks[column][row];
        if (entry == null) {
          continue;
        }
        paint.color =
            Color.lerp(emptyColor, peakColor, _levelMix[entry.level]) ??
            emptyColor;
        canvas.drawRect(
          Rect.fromLTWH(column * pitch, row * pitch, cell, cell),
          paint,
        );
      }
    }

    const gridBottom = 7 * pitch;
    for (final label in grid.monthLabels) {
      final painter = TextPainter(
        text: TextSpan(text: monthLabel(label.monthStart), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = label.column * pitch;
      // Drop a label that would run off the right edge rather than clipping it
      // mid-word.
      if (x + painter.width > size.width) {
        continue;
      }
      painter.paint(canvas, Offset(x, gridBottom + AppSpacing.xs));
    }
  }

  @override
  bool shouldRepaint(_ActivityGridPainter oldDelegate) =>
      oldDelegate.grid != grid ||
      oldDelegate.emptyColor != emptyColor ||
      oldDelegate.peakColor != peakColor ||
      oldDelegate.labelStyle != labelStyle;
}
