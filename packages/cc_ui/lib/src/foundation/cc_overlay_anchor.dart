import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Opens/closes an overlay anchored by [CcOverlayAnchor].
class CcOverlayController extends ChangeNotifier {
  bool _open = false;

  /// Whether the overlay is currently shown.
  bool get isOpen => _open;

  /// Shows the overlay.
  void show() {
    if (!_open) {
      _open = true;
      notifyListeners();
    }
  }

  /// Hides the overlay.
  void hide() {
    if (_open) {
      _open = false;
      notifyListeners();
    }
  }

  /// Toggles the overlay.
  void toggle() => _open ? hide() : show();
}

/// Builds anchored-overlay content. [targetSize] is the laid-out size of the
/// anchor target (useful for width-matching a dropdown to its trigger).
typedef CcOverlayContentBuilder =
    Widget Function(BuildContext context, Size? targetSize);

/// Anchors a floating overlay (dropdown, popover, menu, autocomplete list) to a
/// [target] widget.
///
/// The shared overlay primitive for cc_ui — built on [OverlayPortal] and a
/// viewport-aware [CustomSingleChildLayout], with outside-tap and Escape
/// dismissal. Components drive it through a [CcOverlayController].
///
/// Positioning is collision-aware: the follower is anchored relative to the
/// target ([targetAnchor]/[followerAnchor] + [offset]), then **flipped** to the
/// opposite side when the preferred side lacks room and **clamped** so it always
/// stays fully inside the host [Overlay] (minus [kCcOverlayMargin]). Its size is
/// also capped to the overlay, so an over-tall panel can scroll instead of
/// spilling off-screen or under the app chrome. This is what stops a flyout from
/// being clipped beneath the top bar / sidebar when it opens near an edge.
class CcOverlayAnchor extends StatefulWidget {
  /// Creates a [CcOverlayAnchor].
  const CcOverlayAnchor({
    super.key,
    required this.controller,
    required this.target,
    required this.overlayBuilder,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 4),
    this.matchTargetWidth = false,
    this.barrierDismissible = true,
    this.barrierTargetHole = false,
    this.interceptPointer = false,
    this.onFlip,
    this.onCaretGeometry,
  });

  /// Controls open/close state.
  final CcOverlayController controller;

  /// The anchor widget (e.g. a trigger button or field).
  final Widget target;

  /// Builds the floating content.
  final CcOverlayContentBuilder overlayBuilder;

  /// Point on the target the follower aligns to.
  final Alignment targetAnchor;

  /// Point on the follower aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the follower.
  final Offset offset;

  /// Constrain the follower to the target's width (dropdown-style).
  final bool matchTargetWidth;

  /// Whether tapping outside the overlay closes it.
  final bool barrierDismissible;

  /// Punch a hole in the dismiss barrier over the [target]'s rect so taps on
  /// the field reach the field while the overlay is open. Filterable inputs
  /// (a multi-select whose open field takes typed text and a clear-filter ✕)
  /// need this; plain dropdowns leave it off so tapping the trigger closes.
  final bool barrierTargetHole;

  /// Whether to shield the overlay (panel + barrier) with a [PointerInterceptor]
  /// so its taps land even when it floats over a web platform view — an
  /// `<iframe>` / embedded webview swallows pointer events the instant the
  /// cursor enters it, so an un-shielded flyout over one isn't clickable.
  /// Interactive flyouts (menu, select, popover, autocomplete) set this; the
  /// passive, click-through tooltip leaves it off. No-op on non-web platforms,
  /// where the interceptor is a plain passthrough.
  final bool interceptPointer;

  /// Reports (after layout) whether the follower was flipped to the opposite
  /// vertical side of the preferred one because the preferred side lacked room.
  /// A caret-bearing follower (the tooltip) listens so its caret can point back
  /// at the trigger after a flip. Invoked via a post-frame callback, so it is
  /// safe to drive a [ValueNotifier]/`setState` from it.
  final ValueChanged<bool>? onFlip;

  /// Reports (after layout) the geometry a caret-bearing follower needs to point
  /// precisely at its trigger even after the follower was shifted to stay
  /// on-screen: the trigger's centre expressed in the follower's own coordinate
  /// space and the follower's laid-out size. The tooltip uses this so its caret
  /// tracks the trigger's centre when the panel is clamped near a viewport edge
  /// (a fixed start/center/end caret would otherwise drift off the trigger).
  /// Invoked via a post-frame callback, so it is safe to drive a
  /// [ValueNotifier]/`setState` from it.
  final void Function(Offset triggerCenter, Size followerSize)? onCaretGeometry;

  @override
  State<CcOverlayAnchor> createState() => _CcOverlayAnchorState();
}

/// Breathing room kept between a flyout and the edge of its host overlay.
const double kCcOverlayMargin = 8;

class _CcOverlayAnchorState extends State<CcOverlayAnchor> {
  // Handle on the target's render box so the overlay can read the target's
  // position/size relative to the host overlay at layout time.
  final GlobalKey _targetKey = GlobalKey();
  final OverlayPortalController _portal = OverlayPortalController();

  // Bounds the post-frame retries used when the target geometry isn't laid out
  // yet on the frame the portal first shows — so a never-laid-out target can't
  // spin a per-frame rebuild loop. Reset whenever the overlay closes.
  int _geometryRetries = 0;
  static const int _maxGeometryRetries = 5;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(CcOverlayAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final shouldShow = widget.controller.isOpen;
    if (shouldShow && !_portal.isShowing) {
      _geometryRetries = 0;
      _portal.show();
    } else if (!shouldShow && _portal.isShowing) {
      _portal.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: KeyedSubtree(key: _targetKey, child: widget.target),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    // Resolve the target's rect in the host overlay's coordinate space so the
    // layout delegate can anchor, flip and clamp against the visible viewport.
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final targetBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? targetRect;
    Size? targetSize;
    if (overlayBox != null &&
        targetBox != null &&
        overlayBox.attached &&
        targetBox.attached &&
        targetBox.hasSize) {
      targetSize = targetBox.size;
      final topLeft = targetBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
      targetRect = topLeft & targetSize;
      _geometryRetries = 0;
    } else if (_geometryRetries < _maxGeometryRetries) {
      // Geometry isn't available on the very first frame the portal shows
      // (the target may not be laid out yet). Re-run once it is — capped so a
      // never-laid-out target can't spin a per-frame rebuild loop.
      _geometryRetries++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _portal.isShowing) {
          setState(() {});
        }
      });
    }

    Widget content = widget.overlayBuilder(context, targetSize);
    if (widget.matchTargetWidth && targetSize != null) {
      content = SizedBox(width: targetSize.width, child: content);
    }
    // Escape closes the overlay when focus is within it.
    content = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              widget.controller.hide();
              return null;
            },
          ),
        },
        child: content,
      ),
    );

    // Shield the panel so its own taps reach Flutter over a web platform view.
    // Sized to the panel (it wraps [content] before positioning), so off the
    // panel the click still falls through to the barrier below. No-op off-web.
    if (widget.interceptPointer) {
      content = PointerInterceptor(child: content);
    }

    final Widget positioned = targetRect == null
        // No geometry yet — place by the follower anchor for one frame.
        ? Align(alignment: widget.followerAnchor, child: content)
        : CustomSingleChildLayout(
            delegate: _AnchoredOverlayLayout(
              targetRect: targetRect,
              targetAnchor: widget.targetAnchor,
              followerAnchor: widget.followerAnchor,
              offset: widget.offset,
              margin: kCcOverlayMargin,
              onFlip: widget.onFlip,
              onCaretGeometry: widget.onCaretGeometry,
            ),
            child: content,
          );

    if (!widget.barrierDismissible) {
      return positioned;
    }
    // The full-screen dismiss barrier also needs the interceptor so an
    // outside-tap over the platform view still closes the overlay.
    Widget barrier = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.controller.hide,
    );
    if (widget.barrierTargetHole && targetRect != null) {
      // Taps landing on the target fall through the barrier to the field.
      barrier = _HitTestHole(hole: targetRect, child: barrier);
    }
    if (widget.interceptPointer) {
      barrier = PointerInterceptor(child: barrier);
    }
    return Stack(
      children: [
        Positioned.fill(child: barrier),
        positioned,
      ],
    );
  }
}

/// Excludes [hole] from hit-testing so pointer events inside the rect fall
/// through to whatever sits beneath (the anchor target), while the rest of
/// the child still hit-tests normally. Used to give the dismiss barrier a
/// target-shaped hole.
class _HitTestHole extends SingleChildRenderObjectWidget {
  const _HitTestHole({required this.hole, required super.child});

  final Rect hole;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTestHole(hole);
}

class _RenderHitTestHole extends RenderProxyBox {
  _RenderHitTestHole(this.hole);

  Rect hole;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hole.contains(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

/// Positions an anchored overlay child relative to [targetRect], flipping to the
/// opposite side when the preferred side lacks room and clamping so the child is
/// always fully inside the host overlay (minus [margin]). The child is also
/// size-capped to the overlay so over-tall content scrolls rather than overflows.
class _AnchoredOverlayLayout extends SingleChildLayoutDelegate {  _AnchoredOverlayLayout({
    required this.targetRect,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.margin,
    this.onFlip,
    this.onCaretGeometry,
  });

  final Rect targetRect;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final double margin;
  final ValueChanged<bool>? onFlip;
  final void Function(Offset triggerCenter, Size followerSize)? onCaretGeometry;

  // Maps an Alignment axis value (-1..1) to a 0..1 fraction of an extent.
  static double _fraction(double a) => (a + 1) / 2;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Cap the child to the viewport (minus margins) so a tall/wide panel that
    // scrolls internally never spills off-screen or under the app chrome.
    final maxW = (constraints.maxWidth - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    final maxH = (constraints.maxHeight - margin * 2).clamp(
      0.0,
      double.infinity,
    );
    return BoxConstraints.loose(Size(maxW, maxH));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Horizontal: anchor, then shift to keep the child on-screen.
    final anchorX =
        targetRect.left + targetRect.width * _fraction(targetAnchor.x);
    var x = anchorX - childSize.width * _fraction(followerAnchor.x) + offset.dx;
    final maxX = size.width - childSize.width - margin;
    x = x.clamp(margin, maxX < margin ? margin : maxX);

    // Vertical: prefer the requested side; flip when it doesn't fit but the
    // mirror side does; otherwise keep whichever shows more of the child.
    double placeY(double tAy, double fAy, double offDy) {
      final anchorY = targetRect.top + targetRect.height * _fraction(tAy);
      return anchorY - childSize.height * _fraction(fAy) + offDy;
    }

    final naturalY = placeY(targetAnchor.y, followerAnchor.y, offset.dy);
    final flippedY = placeY(-targetAnchor.y, -followerAnchor.y, -offset.dy);

    bool fits(double y) =>
        y >= margin && y + childSize.height <= size.height - margin;
    double visible(double y) {
      final top = y.clamp(margin, size.height - margin);
      final bottom = (y + childSize.height).clamp(margin, size.height - margin);
      return bottom - top;
    }

    double y;
    bool didFlip;
    if (fits(naturalY)) {
      y = naturalY;
      didFlip = false;
    } else if (fits(flippedY)) {
      y = flippedY;
      didFlip = true;
    } else {
      final keepNatural = visible(naturalY) >= visible(flippedY);
      y = keepNatural ? naturalY : flippedY;
      didFlip = !keepNatural;
    }
    final maxY = size.height - childSize.height - margin;
    y = y.clamp(margin, maxY < margin ? margin : maxY);

    // A flip only means anything on the vertical axis; when the natural and
    // flipped positions coincide (a purely horizontal placement) there is no
    // real flip to report. Report after the frame so a listener can rebuild.
    final flipped = didFlip && naturalY != flippedY;
    final report = onFlip;
    if (report != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => report(flipped));
    }

    final result = Offset(x, y);

    // Report where the trigger's centre lands inside the (possibly clamped)
    // follower so a caret can point straight back at it. Post-frame, so the
    // listener can rebuild safely; identical values are a no-op for a
    // [ValueNotifier], so this never spins a relayout loop.
    final caretReport = onCaretGeometry;
    if (caretReport != null) {
      final triggerCenter = targetRect.center - result;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => caretReport(triggerCenter, childSize),
      );
    }

    return result;
  }

  @override
  bool shouldRelayout(_AnchoredOverlayLayout oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      targetAnchor != oldDelegate.targetAnchor ||
      followerAnchor != oldDelegate.followerAnchor ||
      offset != oldDelegate.offset ||
      margin != oldDelegate.margin;
}
