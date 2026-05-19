import 'package:cc_ui/src/primitives/focus_modality.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// Draws a `:focus-visible`-style ring around [child] when [focusNode] gains
/// focus **via the keyboard**. Clicking into the field with the mouse focuses
/// it without the ring (see [FocusModality]).
///
/// The ring is painted as an overlay on top of the child — never as part of
/// the child's own box — so it never changes the child's size. Toggling focus
/// therefore can't shift the surrounding layout the way a widening [Border]
/// or `InputDecoration.focusedBorder` would (the CSS
/// content-box-vs-border-box problem). At [offset] zero the ring overpaints
/// the child's outer edge; a positive [offset] moves it OUTSIDE the child
/// with a gap, CSS `outline-offset` style.
class FocusRing extends StatefulWidget {
  /// Creates a [FocusRing].
  const FocusRing({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.width = 2,
    this.offset = 0,
    this.color,
    this.enabled = true,
  });

  /// The node whose keyboard focus arms the ring.
  final FocusNode focusNode;

  /// The wrapped field. Its own size is preserved exactly.
  final Widget child;

  /// Corner radius of the ring — match the child's own radius.
  final BorderRadius borderRadius;

  /// Stroke width of the ring.
  final double width;

  /// Gap between the child's bounds and the ring, in logical pixels. Zero
  /// (the default) paints the ring ON the child's outer edge; a positive
  /// value paints it fully OUTSIDE the child with that much clear space
  /// between them, CSS `outline-offset` style. The layout is unchanged
  /// either way — the ring is an overlay, so callers need `offset + width`
  /// of unclipped room around the child (a scroll viewport clips at its
  /// edges).
  final double offset;

  /// Ring color; defaults to the design system `focusRing` token.
  final Color? color;

  /// Set false to suppress the ring entirely (e.g. while the field is disabled).
  final bool enabled;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Constructing the tracker registers its global key/pointer handlers;
    // touch it eagerly so the FIRST key press of a session arms the modality
    // — the ring samples it at the focus-gain edge, which can otherwise land
    // before anything has subscribed.
    // ignore: unnecessary_statements
    FocusModality.instance;
    widget.focusNode.addListener(_onFocusChange);
    _visible = _shouldShow();
  }

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _onFocusChange();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  // Sampled only on the focus-gain edge, so a node focused by mouse stays
  // ringless even if the user then types — mirroring `:focus-visible`, which
  // locks its verdict at the moment focus moves.
  bool _shouldShow() =>
      widget.focusNode.hasFocus && FocusModality.instance.isKeyboard;

  void _onFocusChange() {
    final next = _shouldShow();
    if (next != _visible && mounted) {
      setState(() => _visible = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final color = widget.color ?? tokens.focusRing;
    // Both modes are a Positioned.fill overlay, so the ring never affects (or
    // depends on) layout. At offset 0 the ring is a border that overpaints the
    // child's own edge; with a gap it is a painter that strokes OUTSIDE its
    // own bounds — the Stack must therefore never clip.
    final Widget ring;
    if (widget.offset == 0) {
      ring = IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(color: color, width: widget.width),
          ),
        ),
      );
    } else {
      ring = IgnorePointer(
        child: CustomPaint(
          foregroundPainter: RingPainter(
            color: color,
            width: widget.width,
            gap: widget.offset,
            borderRadius: widget.borderRadius,
          ),
        ),
      );
    }
    return Stack(
      // passthrough forwards our constraints to the child unchanged, so wrapping
      // a field in a FocusRing lays it out identically to the bare child.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_visible && widget.enabled) Positioned.fill(child: ring),
      ],
    );
  }
}

/// Strokes the focus ring `gap` clear of the given size's edges, painting
/// outside the painter's own bounds (the ancestor Stack does not clip).
class RingPainter extends CustomPainter {
  /// Creates a ring stroked `gap` clear of a child with [borderRadius].
  RingPainter({
    required this.color,
    required this.width,
    required this.gap,
    required this.borderRadius,
  });

  /// Ring stroke color.
  final Color color;

  /// Stroke width of the ring.
  final double width;

  /// Clear space between the child's edge and the ring's inner edge.
  final double gap;

  /// Corner radius of the CHILD — the ring stays concentric by growing each
  /// corner by the same distance, so a square child keeps a square ring.
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // A centered stroke `gap` clear of the child's edge: the centerline sits
    // at gap + width/2 outside, so the stroke's outer edge lands at
    // gap + width and its inner edge leaves exactly `gap` of clear space.
    final grow = gap + width / 2;
    final centerline = (Offset.zero & size).inflate(grow);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        centerline,
        topLeft: Radius.circular(borderRadius.topLeft.x + grow),
        topRight: Radius.circular(borderRadius.topRight.x + grow),
        bottomLeft: Radius.circular(borderRadius.bottomLeft.x + grow),
        bottomRight: Radius.circular(borderRadius.bottomRight.x + grow),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.gap != gap ||
      oldDelegate.borderRadius != borderRadius;
}
