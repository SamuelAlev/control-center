import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Per-day activity breakdown used to drive a heatmap cell's color and
/// hover tooltip.
class ActivityCell {
  /// Creates an [ActivityCell].
  const ActivityCell({
    this.runsCompleted = 0,
    this.runsErrored = 0,
    this.prsCreated = 0,
    this.prsMerged = 0,
    this.reviewsCompleted = 0,
    this.blockingComments = 0,
  });

  /// Agent runs that completed successfully on this day.
  final int runsCompleted;

  /// Agent runs that errored on this day.
  final int runsErrored;

  /// PRs created on this day.
  final int prsCreated;

  /// PRs merged on this day.
  final int prsMerged;

  /// Reviews completed on this day.
  final int reviewsCompleted;

  /// Blocking review comments left on this day.
  final int blockingComments;

  /// Total events that drive the heat level (runs + PRs + reviews).
  int get total =>
      runsCompleted +
      runsErrored +
      prsCreated +
      prsMerged +
      reviewsCompleted;

  /// Whether the cell has any recorded activity.
  bool get isEmpty => total == 0;
}

/// Signature for a function that produces the tooltip text for a given cell.
/// Return `null` to suppress the tooltip on that cell.
typedef ActivityTooltipBuilder = String? Function(
  DateTime date,
  ActivityCell cell,
);

/// GitHub-style activity heatmap — discrete 5-level palette, rendered as a
/// calendar grid of cells (rows = days of week, cols = weeks). Hovering a
/// cell shows a floating tooltip anchored to that cell.
class ActivityHeatmap extends StatefulWidget {
  /// Creates a new [ActivityHeatmap].
  const ActivityHeatmap({
    super.key,
    required this.data,
    this.weeks = 26,
    this.cellSize = 11,
    this.cellGap = 3,
    this.cellRadius = 2,
    this.showLabels = true,
    this.showLegend = true,
    this.enableCellTooltips = true,
    this.thresholds = const [1, 3, 6, 10],
    this.palette,
    this.tooltipBuilder,
  });

  /// Per-day activity keyed by day (use midnight DateTime as key).
  final Map<DateTime, ActivityCell> data;

  /// Number of weeks to render (most recent first → rightmost column).
  final int weeks;

  /// Side length of each day cell in logical pixels.
  final double cellSize;

  /// Gap between cells.
  final double cellGap;

  /// Corner radius applied to each cell.
  final double cellRadius;

  /// Whether to render weekday and month labels.
  final bool showLabels;

  /// Whether to render the Less/More legend strip below the grid.
  final bool showLegend;

  /// Whether to wire per-cell mouse-hover detection and show a floating
  /// tooltip. Set to `false` to disable hover behavior entirely.
  final bool enableCellTooltips;

  /// Lower bounds (inclusive) for level 1..4. Default mimics GitHub's
  /// approximate distribution (1+, 3+, 6+, 10+).
  final List<int> thresholds;

  /// Optional 5-color palette: [level0, level1, level2, level3, level4].
  /// When null, a theme-aware GitHub-green palette is used.
  final List<Color>? palette;

  /// Optional override that produces the tooltip text per cell. When null,
  /// the default builder (showing all populated [ActivityCell] fields) is
  /// used — suitable for the analytics dashboard. Pass a custom builder for
  /// smaller surfaces (e.g. a profile card) that only care about a subset
  /// of the data.
  final ActivityTooltipBuilder? tooltipBuilder;

  /// Default tooltip used when no [tooltipBuilder] is provided.
  static String defaultTooltip(DateTime date, ActivityCell c) {
    final dateLine = _formatDate(date);
    if (c.isEmpty) {
      return '$dateLine • No activity';
    }
    final parts = <String>['$dateLine  ·  ${c.total} events'];
    void add(String label, int n) {
      if (n > 0) {
        parts.add('$n $label');
      }
    }

    add(c.runsCompleted == 1 ? 'run' : 'runs', c.runsCompleted);
    add(c.runsErrored == 1 ? 'errored run' : 'errored runs', c.runsErrored);
    add(c.prsCreated == 1 ? 'PR created' : 'PRs created', c.prsCreated);
    add(c.prsMerged == 1 ? 'PR merged' : 'PRs merged', c.prsMerged);
    add(c.reviewsCompleted == 1 ? 'review' : 'reviews', c.reviewsCompleted);
    if (c.blockingComments > 0) {
      parts.add(
        '${c.blockingComments} blocking '
        '${c.blockingComments == 1 ? 'comment' : 'comments'}',
      );
    }
    return parts.join(' • ');
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime d) =>
      '${_monthNames[d.month - 1]} ${d.day}';

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  static const double _labelColumnWidth = 24;
  static const double _labelGap = 6;
  static const double _monthLabelHeight = 14;

  ({int w, int d, String message})? _hoveredValue;
  final ValueNotifier<({int w, int d, String message})?> _hovered =
      ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hovered.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enter(int w, int d, String message) {
    if (_hoveredValue?.w == w && _hoveredValue?.d == d) {
      return;
    }
    _hoveredValue = (w: w, d: d, message: message);
    _hovered.value = _hoveredValue;
  }

  void _exit(int w, int d) {
    if (_hoveredValue?.w != w || _hoveredValue?.d != d) {
      return;
    }
    _hoveredValue = null;
    _hovered.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = widget.palette ?? _defaultPalette(isDark);
    final mutedText = theme.colorScheme.onSurfaceVariant;
    final cellStroke =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final builder = widget.tooltipBuilder ?? ActivityHeatmap.defaultTooltip;

    final today = DateTime.now();
    final endDay = DateTime(today.year, today.month, today.day);
    final daysToSun = (DateTime.sunday - endDay.weekday) % 7;
    final lastCellDate = endDay.add(Duration(days: daysToSun));
    final totalCells = widget.weeks * 7;
    final firstCellDate =
        lastCellDate.subtract(Duration(days: totalCells - 1));

    final columns = <Widget>[
      for (var w = 0; w < widget.weeks; w++)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: widget.cellGap,
          children: [
            for (var d = 0; d < 7; d++)
              _buildCell(
                w: w,
                d: d,
                firstCellDate: firstCellDate,
                endDay: endDay,
                colors: colors,
                cellStroke: cellStroke,
                builder: builder,
              ),
          ],
        ),
    ];

    final gridCore = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: widget.cellGap,
      children: columns,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabels) ...[
          _MonthLabels(
            firstCellDate: firstCellDate,
            weeks: widget.weeks,
            cellSize: widget.cellSize,
            cellGap: widget.cellGap,
            color: mutedText,
          ),
          SizedBox(height: widget.cellGap),
        ],
        gridCore,
        if (widget.showLegend) ...[
          SizedBox(height: widget.cellGap * 3),
          _Legend(
            colors: colors,
            color: mutedText,
            cellSize: widget.cellSize,
            cellRadius: widget.cellRadius,
            cellStroke: cellStroke,
          ),
        ],
      ],
    );

    final content = widget.showLabels
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _labelColumnWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _monthLabelHeight + widget.cellGap,
                    right: _labelGap,
                  ),
                  child: _WeekdayLabels(
                    cellSize: widget.cellSize,
                    cellGap: widget.cellGap,
                    color: mutedText,
                  ),
                ),
              ),
              body,
            ],
          )
        : body;

    final scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: content,
    );

    if (!widget.enableCellTooltips) {
      return scroll;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        scroll,
        ListenableBuilder(
          listenable: Listenable.merge([_hovered, _scrollController]),
          builder: (context, _) {
            final h = _hovered.value;
            if (h == null) {
              return const SizedBox.shrink();
            }
            return _buildTooltipOverlay(h, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildTooltipOverlay(
      ({int w, int d, String message}) h, bool isDark) {
    final cellExtent = widget.cellSize + widget.cellGap;
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final labelXOffset = widget.showLabels ? _labelColumnWidth + _labelGap : 0;
    final monthYOffset =
        widget.showLabels ? _monthLabelHeight + widget.cellGap : 0;
    final cellLeft = labelXOffset + h.w * cellExtent - scrollOffset;
    final cellTop = monthYOffset + h.d * cellExtent;

    final showBelow = h.d <= 2;
    final anchorTop = showBelow
        ? cellTop + widget.cellSize + 6
        : (cellTop - 6).toDouble();
    final yTranslate = showBelow ? 0.0 : -1.0;

    return Positioned(
      left: cellLeft + widget.cellSize / 2,
      top: anchorTop,
      child: FractionalTranslation(
        translation: Offset(-0.5, yTranslate),
        child: IgnorePointer(child: _FloatingTooltip(message: h.message, isDark: isDark)),
      ),
    );
  }

  Widget _buildCell({
    required int w,
    required int d,
    required DateTime firstCellDate,
    required DateTime endDay,
    required List<Color> colors,
    required Color cellStroke,
    required ActivityTooltipBuilder builder,
  }) {
    final date = firstCellDate.add(Duration(days: w * 7 + d));
    final isFuture = date.isAfter(endDay);
    final key = DateTime(date.year, date.month, date.day);
    final cell = widget.data[key] ?? const ActivityCell();
    final level = isFuture ? 0 : _levelFor(cell.total);
    final paint = _HeatCell(
      size: widget.cellSize,
      radius: widget.cellRadius,
      color: isFuture ? Colors.transparent : colors[level],
      stroke: isFuture ? Colors.transparent : cellStroke,
    );
    if (!widget.enableCellTooltips || isFuture) {
      return paint;
    }
    final message = builder(date, cell);
    if (message == null) {
      return paint;
    }
    return MouseRegion(
      onEnter: (_) => _enter(w, d, message),
      onExit: (_) => _exit(w, d),
      child: paint,
    );
  }

  int _levelFor(int count) {
    if (count <= 0) {
      return 0;
    }
    var level = 1;
    for (var i = 0; i < widget.thresholds.length; i++) {
      if (count >= widget.thresholds[i]) {
        level = i + 1;
      }
    }
    return level.clamp(0, 4);
  }

  static List<Color> _defaultPalette(bool isDark) {
    if (isDark) {
      return const [
        Color(0xFF161B22),
        Color(0xFF0E4429),
        Color(0xFF006D32),
        Color(0xFF26A641),
        Color(0xFF39D353),
      ];
    }
    return const [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
  }
}

class _FloatingTooltip extends StatelessWidget {
  const _FloatingTooltip({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(6),
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 11,
            height: 1.4,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.size,
    required this.radius,
    required this.color,
    required this.stroke,
  });

  final double size;
  final double radius;
  final Color color;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    final hasStroke = stroke.a > 0 && color != Colors.transparent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: hasStroke ? Border.all(color: stroke, width: 0.5) : null,
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({
    required this.cellSize,
    required this.cellGap,
    required this.color,
  });

  final double cellSize;
  final double cellGap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labels = {
      0: DateFormat.E().format(DateTime(2024, 1, 1)),
      2: DateFormat.E().format(DateTime(2024, 1, 3)),
      4: DateFormat.E().format(DateTime(2024, 1, 5)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: cellGap,
      children: [
        for (var i = 0; i < 7; i++)
          SizedBox(
            height: cellSize,
            child: labels.containsKey(i)
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      labels[i]!,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.firstCellDate,
    required this.weeks,
    required this.cellSize,
    required this.cellGap,
    required this.color,
  });

  final DateTime firstCellDate;
  final int weeks;
  final double cellSize;
  final double cellGap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      12,
      (i) => DateFormat.MMM().format(DateTime(2024, i + 1, 1)),
    );
    final extent = cellSize + cellGap;
    final stripWidth = weeks * extent - cellGap;

    final positioned = <Widget>[];
    var lastMonth = -1;
    for (var w = 0; w < weeks; w++) {
      final colDate = firstCellDate.add(Duration(days: w * 7));
      final showLabel = colDate.month != lastMonth && colDate.day <= 7;
      if (!showLabel) {
        continue;
      }
      positioned.add(
        Positioned(
          left: w * extent,
          top: 0,
          child: Text(
            months[colDate.month - 1],
            style: TextStyle(
              fontSize: 10,
              height: 1,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
      lastMonth = colDate.month;
    }

    return SizedBox(
      width: stripWidth,
      height: 14,
      child: Stack(clipBehavior: Clip.none, children: positioned),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.colors,
    required this.color,
    required this.cellSize,
    required this.cellRadius,
    required this.cellStroke,
  });

  final List<Color> colors;
  final Color color;
  final double cellSize;
  final double cellRadius;
  final Color cellStroke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          l10n.lessLabel,
          style: TextStyle(
            fontSize: 10,
            height: 1,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (final c in colors)
          Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(cellRadius),
              border: Border.all(color: cellStroke, width: 0.5),
            ),
          ),
        Text(
          l10n.moreLabel,
          style: TextStyle(
            fontSize: 10,
            height: 1,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
