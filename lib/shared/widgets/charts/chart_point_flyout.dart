part of 'chart_hover.dart';

/// Hairline + series dots + travelling flyout card for [ChartHoverHost].
///
/// Ignores pointers so it cannot steal hover from the plot — a canvas tooltip
/// that the cursor can overlap is what made the built-in flyout flicker.
///
/// RTL carve-out: the overlay is laid out in the same physical coordinates
/// as fl_chart's plot (left/bottom gutters).
class ChartPointFlyout extends StatefulWidget {
  /// Creates a [ChartPointFlyout].
  const ChartPointFlyout({
    super.key,
    required this.geometry,
    required this.plotPadding,
    required this.child,
  });

  /// Hovered column, or `null` to hide.
  final ChartHoverGeometry? geometry;

  /// Plot inset, used to draw the hairline only inside the plot.
  final EdgeInsets plotPadding;

  /// Flyout body. Kept on screen during the hide fade so the card does not
  /// snap to empty.
  final Widget? child;

  @override
  State<ChartPointFlyout> createState() => _ChartPointFlyoutState();
}

class _ChartPointFlyoutState extends State<ChartPointFlyout>
    with SingleTickerProviderStateMixin {
  static const _dotRadius = 4.0;

  late final AnimationController _travel;
  late final CurvedAnimation _curve;
  ChartHoverGeometry? _from;
  ChartHoverGeometry? _to;
  Widget? _body;

  @override
  void initState() {
    super.initState();
    _travel = AnimationController(vsync: this, value: 1);
    _curve = CurvedAnimation(parent: _travel, curve: CcMotion.standard);
    _to = widget.geometry;
    _body = widget.child;
  }

  @override
  void didUpdateWidget(ChartPointFlyout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != null) {
      _body = widget.child;
    }
    final next = widget.geometry;
    if (next == null) {
      return;
    }
    final current = _displayed;
    if (current == null || current == next) {
      _from = next;
      _to = next;
      _travel.value = 1;
      return;
    }
    _from = current;
    _to = next;
    _travel
      ..duration = CcMotion.resolveTravel(context, CcMotion.moderate)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _travel.dispose();
    super.dispose();
  }

  ChartHoverGeometry? get _displayed {
    final to = _to;
    if (to == null) {
      return null;
    }
    final from = _from;
    if (from == null ||
        _curve.value >= 1 ||
        from.dots.length != to.dots.length) {
      return to;
    }
    return ChartHoverGeometry.lerp(from, to, _curve.value);
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.geometry != null && _body != null;
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fade = CcMotion.resolveFade(
      context,
      visible ? CcMotion.fast : CcMotion.fastExit,
    );

    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final geometry = _displayed;
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: fade,
              curve: CcMotion.standard,
              child: geometry == null || _body == null
                  ? const SizedBox.shrink()
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: geometry.x - 0.5,
                          top: widget.plotPadding.top,
                          bottom: widget.plotPadding.bottom,
                          width: 1,
                          child: ColoredBox(color: tokens.borderSecondary),
                        ),
                        for (final dot in geometry.dots)
                          Positioned(
                            left: geometry.x - _dotRadius,
                            top: dot.y - _dotRadius,
                            width: _dotRadius * 2,
                            height: _dotRadius * 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: dot.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tokens.bgPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        CustomSingleChildLayout(
                          delegate: _FlyoutPlacement(
                            anchor: geometry.topAnchor,
                            gap: AppSpacing.sm,
                          ),
                          child: ChartPointFlyoutCard(child: _body!),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Light card chrome matching the rest of the observability plots.
class ChartPointFlyoutCard extends StatelessWidget {
  /// Creates a [ChartPointFlyoutCard].
  const ChartPointFlyoutCard({super.key, required this.child});

  /// Flyout body.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderPrimary),
        boxShadow: CcElevation.raised,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: DefaultTextStyle(
          style: CcTypography.caption.copyWith(color: tokens.textPrimary),
          child: child,
        ),
      ),
    );
  }
}

class _FlyoutPlacement extends SingleChildLayoutDelegate {
  _FlyoutPlacement({required this.anchor, required this.gap});

  final Offset anchor;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.dx - childSize.width / 2;
    var y = anchor.dy - childSize.height - gap;
    if (y < 0) {
      y = anchor.dy + gap;
    }
    final maxX = size.width - childSize.width;
    final maxY = size.height - childSize.height;
    x = maxX <= 0 ? 0 : x.clamp(0.0, maxX);
    y = maxY <= 0 ? 0 : y.clamp(0.0, maxY);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_FlyoutPlacement old) =>
      old.anchor != anchor || old.gap != gap;
}
