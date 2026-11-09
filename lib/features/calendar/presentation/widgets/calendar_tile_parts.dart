import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:kalender/kalender.dart' as k;

/// The tile body, with a pointer-driven background. Stateful so each tile tracks
/// its own hover without rebuilding the whole calendar. The fill cross-fades
/// between [fill] and [hoverFill] (instantly when the platform requests reduced
/// motion).
class CalendarHoverFillBox extends StatefulWidget {
  /// Creates a [CalendarHoverFillBox].
  const CalendarHoverFillBox({
    super.key,
    required this.fill,
    required this.hoverFill,
    required this.border,
    required this.child,
  });

  /// The resting fill.
  final Color fill;

  /// The fill under the pointer.
  final Color hoverFill;

  /// An optional outline.
  final BoxBorder? border;

  /// The tile content.
  final Widget child;

  @override
  State<CalendarHoverFillBox> createState() => _CalendarHoverFillBoxState();
}

class _CalendarHoverFillBoxState extends State<CalendarHoverFillBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? widget.hoverFill : widget.fill,
          borderRadius: AppRadii.brSm,
          border: widget.border,
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle outline, inset by half the stroke so it is
/// not clipped at the edges. Used for unanswered invitations, which have no
/// fill of their own.
class CalendarDashedRRectPainter extends CustomPainter {
  /// Creates a [CalendarDashedRRectPainter].
  const CalendarDashedRRectPainter({required this.color, required this.radius});

  /// The dash color.
  final Color color;

  /// The corner radius.
  final double radius;

  static const double _strokeWidth = 1;
  static const double _dashLength = 4;
  static const double _gapLength = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    const inset = _strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - _strokeWidth,
            size.height - _strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(CalendarDashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Month-cell packing that sorts by start time instead of duration.
///
/// kalender's default [k.MultiDayLayoutStrategy.byDuration] puts the longest
/// events first, which reads as a random order for a stack of same-length
/// meetings.
class StartSortedMultiDayLayoutStrategy extends k.MultiDayLayoutStrategy {
  /// Creates a [StartSortedMultiDayLayoutStrategy].
  const StartSortedMultiDayLayoutStrategy();

  @override
  k.MultiDayLayoutFrame generateFrame({
    required k.FloatingDateTimeRange visibleRange,
    required List<k.KalenderEvent> events,
    required TextDirection textDirection,
    required k.Location? location,
    required k.MultiDayLayoutFrameCache? cache,
  }) {
    return k.defaultMultiDayFrameGenerator(
      visibleRange: visibleRange,
      events: events,
      textDirection: textDirection,
      location: location,
      cache: cache,
      eventComparator: (a, b) => a.start.compareTo(b.start),
    );
  }

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => (StartSortedMultiDayLayoutStrategy).hashCode;
}

/// A band that takes [reservedHeight] from the layout and paints — and stays tappable — at
/// whatever height its child turns out to be.
/// This is what makes the all-day strip hover over the timed grid instead of pushing it
/// down.
class CalendarFloatingBand extends SingleChildRenderObjectWidget {
  /// Creates a [CalendarFloatingBand].
  const CalendarFloatingBand({
    super.key,
    required this.reservedHeight,
    required super.child,
  });

  /// The height the band takes from the layout.
  final double reservedHeight;

  @override
  RenderCalendarFloatingBand createRenderObject(BuildContext context) {
    return RenderCalendarFloatingBand(reservedHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCalendarFloatingBand renderObject,
  ) {
    renderObject.reservedHeight = reservedHeight;
  }
}

/// The render object behind [CalendarFloatingBand].
class RenderCalendarFloatingBand extends RenderProxyBox {
  /// Creates a [RenderCalendarFloatingBand].
  RenderCalendarFloatingBand(this._reservedHeight);

  double _reservedHeight;

  /// The height the band takes from the layout.
  double get reservedHeight => _reservedHeight;
  set reservedHeight(double value) {
    if (value == _reservedHeight) {
      return;
    }
    _reservedHeight = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _reservedHeight));
      return;
    }
    // Height-unbounded, so the child settles at its own height rather than
    // being squeezed into the band's.
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    size = Size(child.size.width, _reservedHeight);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !(Offset.zero & child.size).contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  /// Claims every point the band paints on, so a press on an empty part of it
  /// stops there instead of falling through to the grid behind.
  @override
  bool hitTestSelf(Offset position) => true;
}

/// A [height]-tall band whose child is laid out at its natural height and
/// clipped, rather than squeezed into the band.
///
/// The all-day strip is measured by kalender in two passes per frame — once
/// unbounded, once against the height it settled on — and its page view reports
/// a placeholder height before it has measured a page, then tweens between
/// heights afterwards. So for a handful of frames the content is taller than
/// the band it is going into. Clamped, that is a RenderFlex overflow (and a
/// visibly squashed row); clipped, it is empty space below a top-aligned strip
/// that nobody can see missing.
class CalendarClippedBand extends StatelessWidget {
  /// Creates a [CalendarClippedBand].
  const CalendarClippedBand({
    super.key,
    required this.height,
    required this.alignment,
    required this.child,
  });

  /// The band's height.
  final double height;

  /// Where the clipped child sits in the band.
  final Alignment alignment;

  /// The band's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
