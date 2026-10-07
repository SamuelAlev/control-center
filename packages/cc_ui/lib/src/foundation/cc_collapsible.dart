import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/primitives/focus_modality.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The body of an accordion/disclosure: reveals [child] by growing its height
/// from the top edge when [expanded] turns true, and shrinks it away when it
/// turns false.
///
/// Expanding runs on [duration] ([CcMotion.moderate] by default) and
/// collapsing on its paired exit token ([CcMotion.exitFor]), both on
/// [CcMotion.standard]. The child stays mounted and visible while it
/// collapses, so the content slides under the clip instead of vanishing and
/// leaving an empty gap, and it is dropped once fully collapsed (unless
/// [maintainState]).
///
/// A toggle driven by the keyboard (Enter/Space on a header, arrow keys in a
/// tree, a shortcut — see [FocusModality.lastInputWasKeyboard]) snaps without
/// animating. Reduced motion snaps the size too, keeping only a short
/// [CcMotion.fade] on reveal so the change still reports.
///
/// While collapsing, the child is excluded from focus and semantics. Once
/// expanded, the height follows the child's own size directly, so content
/// that grows or shrinks inside an open section never re-animates.
class CcCollapsible extends StatefulWidget {
  /// Creates a [CcCollapsible].
  const CcCollapsible({
    super.key,
    required this.expanded,
    required this.child,
    this.duration = CcMotion.moderate,
    this.maintainState = false,
  });

  /// Whether [child] is shown.
  final bool expanded;

  /// The collapsible content.
  final Widget child;

  /// Expand duration; the collapse runs on [CcMotion.exitFor] of this.
  final Duration duration;

  /// Keep [child] mounted (offstage, tickers paused) while collapsed, so its
  /// state survives a collapse.
  final bool maintainState;

  @override
  State<CcCollapsible> createState() => _CcCollapsibleState();
}

class _CcCollapsibleState extends State<CcCollapsible>
    with TickerProviderStateMixin {
  late final AnimationController _size = AnimationController(
    vsync: this,
    value: widget.expanded ? 1 : 0,
    duration: widget.duration,
    reverseDuration: CcMotion.exitFor(widget.duration),
  );
  late final Animation<double> _sizeCurve = CurvedAnimation(
    parent: _size,
    curve: CcMotion.standard,
  );

  // Only runs under reduced motion; otherwise it rests at 1.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
    duration: CcMotion.fade,
  );

  @override
  void initState() {
    super.initState();
    // Register the tracker's global handlers before the first toggle, so the
    // first key press of a session is already seen (see FocusRing).
    // ignore: unnecessary_statements
    FocusModality.instance;
    _size.addStatusListener(_onSizeStatus);
  }

  @override
  void didUpdateWidget(CcCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _size
        ..duration = widget.duration
        ..reverseDuration = CcMotion.exitFor(widget.duration);
    }
    if (oldWidget.expanded != widget.expanded) {
      _run();
    }
  }

  void _run() {
    final target = widget.expanded ? 1.0 : 0.0;
    if (FocusModality.instance.lastInputWasKeyboard) {
      _size.value = target;
      _fade.value = 1;
      return;
    }
    if (CcMotion.reduced(context)) {
      _size.value = target;
      if (widget.expanded) {
        _fade.forward(from: 0);
      }
      return;
    }
    if (widget.expanded) {
      _size.forward();
    } else {
      _size.reverse();
    }
  }

  // The collapsed child is dropped (or taken offstage) once dismissed.
  void _onSizeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _size.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One stable tree for every phase, so toggling never remounts the child
    // (a maintained child keeps its state across the closed/animating edge).
    return Visibility(
      visible: widget.expanded || !_size.isDismissed,
      maintainState: widget.maintainState,
      child: AnimatedBuilder(
        animation: _sizeCurve,
        builder: (context, child) =>
            _Reveal(factor: _sizeCurve.value, child: child),
        child: ExcludeFocus(
          excluding: !widget.expanded,
          child: ExcludeSemantics(
            excluding: !widget.expanded,
            child: FadeTransition(opacity: _fade, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Shows the top [factor] of its child's height, clipped. Unlike
/// [SizeTransition] (an [Align], which loosens constraints) the incoming
/// width constraints pass through untouched, so a body in a stretched
/// [Column] or a sliver keeps its full width while it animates.
class _Reveal extends SingleChildRenderObjectWidget {
  const _Reveal({required this.factor, super.child});

  final double factor;

  @override
  _RenderReveal createRenderObject(BuildContext context) =>
      _RenderReveal(factor);

  @override
  void updateRenderObject(BuildContext context, _RenderReveal renderObject) {
    renderObject.factor = factor;
  }
}

class _RenderReveal extends RenderProxyBox {
  _RenderReveal(double factor) : _factor = factor.clamp(0, 1);

  double _factor;
  set factor(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _factor) {
      return;
    }
    _factor = clamped;
    markNeedsLayout();
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  bool get _clipped => _factor < 1;

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      constraints.copyWith(minHeight: 0);

  Size _sizeFor(BoxConstraints constraints, Size child) =>
      constraints.constrain(Size(child.width, child.height * _factor));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) {
      return constraints.smallest;
    }
    return _sizeFor(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) * _factor;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    if (!_clipped) {
      _clip.layer = null;
      super.paint(context, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
      oldLayer: _clip.layer,
    );
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _clipped ? Offset.zero & size : null;

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
