import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
typedef CcOverlayContentBuilder = Widget Function(
  BuildContext context,
  Size? targetSize,
);

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
    final targetBox = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? targetRect;
    Size? targetSize;
    if (overlayBox != null &&
        targetBox != null &&
        overlayBox.attached &&
        targetBox.attached &&
        targetBox.hasSize) {
      targetSize = targetBox.size;
      final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
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
            ),
            child: content,
          );

    if (!widget.barrierDismissible) {
      return positioned;
    }
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.controller.hide,
          ),
        ),
        positioned,
      ],
    );
  }
}

/// Positions an anchored overlay child relative to [targetRect], flipping to the
/// opposite side when the preferred side lacks room and clamping so the child is
/// always fully inside the host overlay (minus [margin]). The child is also
/// size-capped to the overlay so over-tall content scrolls rather than overflows.
class _AnchoredOverlayLayout extends SingleChildLayoutDelegate {
  _AnchoredOverlayLayout({
    required this.targetRect,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.margin,
  });

  final Rect targetRect;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final double margin;

  // Maps an Alignment axis value (-1..1) to a 0..1 fraction of an extent.
  static double _fraction(double a) => (a + 1) / 2;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Cap the child to the viewport (minus margins) so a tall/wide panel that
    // scrolls internally never spills off-screen or under the app chrome.
    final maxW = (constraints.maxWidth - margin * 2).clamp(0.0, double.infinity);
    final maxH = (constraints.maxHeight - margin * 2).clamp(0.0, double.infinity);
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
    if (fits(naturalY)) {
      y = naturalY;
    } else if (fits(flippedY)) {
      y = flippedY;
    } else {
      y = visible(naturalY) >= visible(flippedY) ? naturalY : flippedY;
    }
    final maxY = size.height - childSize.height - margin;
    y = y.clamp(margin, maxY < margin ? margin : maxY);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AnchoredOverlayLayout oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      targetAnchor != oldDelegate.targetAnchor ||
      followerAnchor != oldDelegate.followerAnchor ||
      offset != oldDelegate.offset ||
      margin != oldDelegate.margin;
}
