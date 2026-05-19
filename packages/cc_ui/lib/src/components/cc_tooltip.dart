import 'dart:async';

import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Which side of the trigger a [CcTooltip] opens on. The caret always points
/// back at the trigger from the opposite edge of the panel.
enum CcTooltipPlacement {
  /// Above the trigger (caret on the panel's bottom edge, pointing down).
  top,

  /// Below the trigger (caret on the panel's top edge, pointing up) — default.
  bottom,

  /// Left of the trigger (caret on the panel's right edge, pointing right).
  left,

  /// Right of the trigger (caret on the panel's left edge, pointing left).
  right,
}

/// The direction a tooltip caret points (resolved from the follower anchor).
enum _CaretDirection { up, down, left, right }

/// A flat, ink-dark tooltip that appears after a short hover dwell — or on
/// keyboard focus — carrying a caret that ties it back to its trigger.
///
/// Wraps [child] in a [MouseRegion] and a focus tracker; on hover-enter (after
/// [showDelay]) or when a focusable descendant gains focus, a small dark panel
/// with [message] is shown, anchored to the [placement] side of the child with
/// a caret pointing back at it. It is purely descriptive: the panel receives no
/// focus, holds no interactive content and is dismissed by moving the pointer
/// away, moving focus away, or pressing Escape while the trigger is focused.
/// Motion is suppressed under reduced-motion.
///
/// Supplemental only — never put essential task information or interactive
/// elements (buttons, links) in a tooltip; use visible helper text or a
/// disclosure/popover for those.
class CcTooltip extends StatefulWidget {
  /// Creates a [CcTooltip].
  const CcTooltip({
    super.key,
    required this.child,
    this.message,
    this.tip,
    this.alignment,
    this.showDelay = const Duration(milliseconds: 500),
    this.placement = CcTooltipPlacement.bottom,
    this.targetAnchor,
    this.followerAnchor,
    this.offset,
    this.maxWidth = 280,
  }) : assert(
         message != null || tip != null,
         'CcTooltip needs a message or a tip',
       );

  /// The widget the tooltip describes.
  final Widget child;

  /// The tooltip text (used when [tip] is null). Keep it brief and use
  /// sentence-style capitalization.
  final String? message;

  /// Optional rich (but still **non-interactive**) tooltip content, rendered
  /// inside the dark panel chrome instead of [message]. Provide exactly one of
  /// [message] or [tip].
  final Widget? tip;

  /// Alignment of the message text within the panel.
  final AlignmentGeometry? alignment;

  /// Hover dwell before the tooltip appears.
  final Duration showDelay;

  /// Which side of the trigger the tooltip opens on (and thus which edge the
  /// caret sits on). Ignored when [targetAnchor]/[followerAnchor] are supplied.
  final CcTooltipPlacement placement;

  /// Explicit anchor on the target the panel aligns to. When null it is derived
  /// from [placement]. Supplying it (with [followerAnchor]) overrides
  /// [placement] and still drives the caret direction/alignment.
  final Alignment? targetAnchor;

  /// Explicit anchor on the panel aligned to [targetAnchor]. When null it is
  /// derived from [placement].
  final Alignment? followerAnchor;

  /// Extra offset applied to the panel. When null a small placement-appropriate
  /// gap is used so the caret tip sits just off the trigger.
  final Offset? offset;

  /// Maximum width of the tooltip panel before the text wraps.
  final double maxWidth;

  @override
  State<CcTooltip> createState() => _CcTooltipState();
}

class _CcTooltipState extends State<CcTooltip> {
  final CcOverlayController _controller = CcOverlayController();
  // Whether the overlay was flipped to the opposite side for lack of room —
  // drives the caret so it always points back at the trigger.
  final ValueNotifier<bool> _flipped = ValueNotifier(false);
  // The trigger's centre in the panel's own coordinate space plus the panel's
  // size, reported after layout. Lets the caret track the trigger even when the
  // panel is shifted to stay on-screen near a viewport edge.
  final ValueNotifier<({Offset trigger, Size panel})?> _caret = ValueNotifier(
    null,
  );
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _flipped.dispose();
    _caret.dispose();
    super.dispose();
  }

  // Hover reveals after a short dwell so a passing cursor doesn't flash the
  // tooltip.
  void _onEnter() {
    _timer?.cancel();
    _timer = Timer(widget.showDelay, _show);
  }

  // Keyboard focus is deliberate, so the tooltip shows immediately (no dwell) —
  // matching the hover-*or*-focus reveal contract.
  void _onFocus() {
    _timer?.cancel();
    _show();
  }

  void _onExit() {
    _timer?.cancel();
    _timer = null;
    _controller.hide();
  }

  void _show() {
    if (!mounted) {
      return;
    }
    // Reset the flip assumption and caret geometry on open; the layout
    // re-reports both immediately.
    _flipped.value = false;
    _caret.value = null;
    _controller.show();
  }

  // Resolves the (targetAnchor, followerAnchor, offset) for the chosen
  // placement, unless the caller supplied explicit anchors.
  ({Alignment target, Alignment follower, Offset offset}) get _anchors {
    final target = widget.targetAnchor;
    final follower = widget.followerAnchor;
    if (target != null && follower != null) {
      return (
        target: target,
        follower: follower,
        offset: widget.offset ?? Offset.zero,
      );
    }
    const gap = AppSpacing.xs;
    return switch (widget.placement) {
      CcTooltipPlacement.bottom => (
        target: Alignment.bottomCenter,
        follower: Alignment.topCenter,
        offset: widget.offset ?? const Offset(0, gap),
      ),
      CcTooltipPlacement.top => (
        target: Alignment.topCenter,
        follower: Alignment.bottomCenter,
        offset: widget.offset ?? const Offset(0, -gap),
      ),
      CcTooltipPlacement.right => (
        target: Alignment.centerRight,
        follower: Alignment.centerLeft,
        offset: widget.offset ?? const Offset(gap, 0),
      ),
      CcTooltipPlacement.left => (
        target: Alignment.centerLeft,
        follower: Alignment.centerRight,
        offset: widget.offset ?? const Offset(-gap, 0),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final anchors = _anchors;
    // Show on hover (mouse) AND on keyboard focus: a Tab-reachable child must
    // reveal its tooltip without a mouse (a tooltip shows on hover *or* focus).
    // `canRequestFocus: false` keeps this wrapper out of the tab order while
    // still tracking focus within its subtree; losing focus hides it. Escape
    // dismisses the tooltip while the trigger is focused and is only
    // intercepted while the tooltip is open so it otherwise propagates.
    return Focus(
      canRequestFocus: false,
      onFocusChange: (hasFocus) => hasFocus ? _onFocus() : _onExit(),
      onKeyEvent: (node, event) {
        if (_controller.isOpen &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _onExit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: CcOverlayAnchor(
          controller: _controller,
          targetAnchor: anchors.target,
          followerAnchor: anchors.follower,
          offset: anchors.offset,
          barrierDismissible: false,
          onFlip: (didFlip) {
            if (mounted) _flipped.value = didFlip;
          },
          onCaretGeometry: (trigger, panel) {
            if (mounted) _caret.value = (trigger: trigger, panel: panel);
          },
          // Expose the message to assistive tech as a tooltip hint (parity with
          // Material's Tooltip) so an icon-only trigger keeps an accessible name
          // even though the panel itself is never read.
          target: widget.message != null
              ? Semantics(tooltip: widget.message, child: widget.child)
              : widget.child,
          overlayBuilder: (context, targetSize) => _CcTooltipPanel(
            message: widget.message,
            tip: widget.tip,
            alignment: widget.alignment,
            maxWidth: widget.maxWidth,
            caret: _caretFor(anchors.follower),
            caretCross: _caretCrossFor(anchors.follower),
            flipped: _flipped,
            geometry: _caret,
          ),
        ),
      ),
    );
  }
}

// The caret sits on the panel edge facing the trigger — i.e. opposite the
// follower anchor's dominant axis.
_CaretDirection _caretFor(Alignment follower) {
  if (follower.y <= -1) return _CaretDirection.up; // panel below → caret up
  if (follower.y >= 1) return _CaretDirection.down; // panel above → caret down
  if (follower.x <= -1) return _CaretDirection.left; // panel right → caret left
  if (follower.x >= 1) return _CaretDirection.right; // panel left → caret right
  return _CaretDirection.up;
}

// The cross-axis alignment of the caret along the panel edge, taken from the
// perpendicular component of the follower anchor (start / center / end).
CrossAxisAlignment _caretCrossFor(Alignment follower) {
  final perp = (follower.y <= -1 || follower.y >= 1) ? follower.x : follower.y;
  if (perp < 0) return CrossAxisAlignment.start;
  if (perp > 0) return CrossAxisAlignment.end;
  return CrossAxisAlignment.center;
}

/// The dark tooltip panel + caret — fades itself in on mount so it animates each
/// time the overlay reopens (the [CcOverlayAnchor] rebuilds it fresh on show).
class _CcTooltipPanel extends StatefulWidget {
  const _CcTooltipPanel({
    required this.message,
    required this.tip,
    required this.alignment,
    required this.maxWidth,
    required this.caret,
    required this.caretCross,
    required this.flipped,
    required this.geometry,
  });

  final String? message;
  final Widget? tip;
  final AlignmentGeometry? alignment;
  final double maxWidth;
  final _CaretDirection caret;
  final CrossAxisAlignment caretCross;

  /// Whether the overlay was flipped to the opposite side (caret must invert).
  final ValueListenable<bool> flipped;

  /// The trigger's centre in the panel's coordinate space and the panel's size,
  /// reported after layout. Null until the first layout lands — the caret then
  /// falls back to [caretCross]. Once present, the caret is positioned to point
  /// exactly at the trigger even when the panel was clamped near an edge.
  final ValueListenable<({Offset trigger, Size panel})?> geometry;

  @override
  State<_CcTooltipPanel> createState() => _CcTooltipPanelState();
}

class _CcTooltipPanelState extends State<_CcTooltipPanel> {
  bool _opaque = false;

  // Caret geometry: [_caretSpan] along the edge, [_caretDepth] pointing out.
  static const double _caretSpan = 10;
  static const double _caretDepth = 5;

  // Inset the caret from the corner for start/end alignment so it never jams
  // into the panel's corner; centered carets need no inset.
  static const double _caretInset = AppSpacing.md;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opaque = true);
      }
    });
  }

  bool get _isVertical =>
      widget.caret == _CaretDirection.up ||
      widget.caret == _CaretDirection.down;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final duration = CcMotion.resolve(context, CcMotion.normal);

    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // A dedicated overlay ink that stays dark in *both* themes (ink-black
          // in light, a raised dark grey in dark) so the white tooltip text
          // never lands on a near-white panel.
          color: t.bgOverlay,
          borderRadius: AppRadii.brSm,
          boxShadow: CcElevation.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: widget.tip != null
              ? DefaultTextStyle(
                  style: CcTypography.caption.copyWith(color: t.textWhite),
                  child: widget.tip!,
                )
              : Text(
                  widget.message!,
                  textAlign: TextAlign.start,
                  style: CcTypography.caption.copyWith(color: t.textWhite),
                ),
        ),
      ),
    );

    // The caret direction depends on whether the overlay flipped sides and its
    // cross-axis position depends on where the trigger landed inside the
    // (possibly clamped) panel — both only known after layout, so rebuild
    // against [widget.flipped] and [widget.geometry].
    final reactivePanel = ValueListenableBuilder<bool>(
      valueListenable: widget.flipped,
      builder: (context, flipped, _) {
        final direction = flipped ? _invert(widget.caret) : widget.caret;
        final caret = CustomPaint(
          size: _isVertical
              ? const Size(_caretSpan, _caretDepth)
              : const Size(_caretDepth, _caretSpan),
          painter: _CaretPainter(color: t.bgOverlay, direction: direction),
        );
        return ValueListenableBuilder<({Offset trigger, Size panel})?>(
          valueListenable: widget.geometry,
          builder: (context, geometry, _) => geometry == null
              ? _fallbackPanel(caret, direction, body)
              : _precisePanel(caret, direction, body, geometry),
        );
      },
    );

    final aligned = widget.alignment == null
        ? reactivePanel
        : Align(alignment: widget.alignment!, child: reactivePanel);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _opaque ? 1 : 0,
        duration: duration,
        curve: CcMotion.standard,
        child: aligned,
      ),
    );
  }

  // Coarse placement used until the layout reports the trigger's exact position:
  // the caret sits at [caretCross] (start / center / end) along the panel edge,
  // stacked before or after the body via a Column/Row.
  Widget _fallbackPanel(Widget caret, _CaretDirection direction, Widget body) {
    // Give a start/end caret a little breathing room from the corner.
    final Widget insetCaret = widget.caretCross == CrossAxisAlignment.center
        ? caret
        : Padding(
            padding: _isVertical
                ? EdgeInsets.only(
                    left: widget.caretCross == CrossAxisAlignment.start
                        ? _caretInset
                        : 0,
                    right: widget.caretCross == CrossAxisAlignment.end
                        ? _caretInset
                        : 0,
                  )
                : EdgeInsets.only(
                    top: widget.caretCross == CrossAxisAlignment.start
                        ? _caretInset
                        : 0,
                    bottom: widget.caretCross == CrossAxisAlignment.end
                        ? _caretInset
                        : 0,
                  ),
            child: caret,
          );

    // Caret leads when it points up/left (sits before the body), trails when it
    // points down/right.
    final caretLeads =
        direction == _CaretDirection.up || direction == _CaretDirection.left;
    final children = caretLeads ? [insetCaret, body] : [body, insetCaret];
    return _isVertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: widget.caretCross,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: widget.caretCross,
            children: children,
          );
  }

  // Precise placement: reserve the caret's depth on the trigger-facing edge (so
  // the panel footprint is identical to the fallback and never re-anchors), then
  // pin the caret along that edge at the trigger's centre, clamped so it never
  // rides past the rounded corners. This is what keeps the caret on the trigger
  // when the panel is shifted to stay on-screen near a viewport edge.
  Widget _precisePanel(
    Widget caret,
    _CaretDirection direction,
    Widget body,
    ({Offset trigger, Size panel}) geometry,
  ) {
    // The caret centre must stay within [lo, hi] so the triangle never rides
    // past the panel's corners. The bound is the panel's own corner radius
    // (square by design-system rule, so ~zero) plus half the caret — a fixed
    // inset would exceed a one-line panel's half-height, inverting the window
    // and pinning the caret to the panel's far edge instead of the trigger.
    // The caret centre must stay within [lo, hi] so the triangle never rides
    // past the panel's corners. The bound is the panel's own corner radius
    // (square by design-system rule, so ~zero) plus half the caret — a fixed
    // inset would exceed a one-line panel's half-height, inverting the window
    // and pinning the caret to the panel's far edge instead of the trigger.
    double clampCentre(double target, double extent) {
      const inset = AppRadii.sm + _caretSpan / 2;
      final hi = extent - inset;
      if (hi < inset) return extent / 2;
      return target.clamp(inset, hi);
    }

    if (_isVertical) {
      final caretUp = direction == _CaretDirection.up;
      final cx = clampCentre(geometry.trigger.dx, geometry.panel.width);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: caretUp ? _caretDepth : 0,
              bottom: caretUp ? 0 : _caretDepth,
            ),
            child: body,
          ),
          Positioned(
            top: caretUp ? 0 : null,
            bottom: caretUp ? null : 0,
            left: cx - _caretSpan / 2,
            child: caret,
          ),
        ],
      );
    }

    final caretLeft = direction == _CaretDirection.left;
    final cy = clampCentre(geometry.trigger.dy, geometry.panel.height);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: caretLeft ? _caretDepth : 0,
            right: caretLeft ? 0 : _caretDepth,
          ),
          child: body,
        ),
        Positioned(
          left: caretLeft ? 0 : null,
          right: caretLeft ? null : 0,
          top: cy - _caretSpan / 2,
          child: caret,
        ),
      ],
    );
  }
}

/// Inverts a caret direction across the axis a flip mirrors on.
_CaretDirection _invert(_CaretDirection d) => switch (d) {
  _CaretDirection.up => _CaretDirection.down,
  _CaretDirection.down => _CaretDirection.up,
  _CaretDirection.left => _CaretDirection.right,
  _CaretDirection.right => _CaretDirection.left,
};

/// Paints the small solid triangle caret pointing toward the trigger.
class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.color, required this.direction});

  final Color color;
  final _CaretDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path();
    switch (direction) {
      case _CaretDirection.up:
        path
          ..moveTo(0, h)
          ..lineTo(w / 2, 0)
          ..lineTo(w, h);
      case _CaretDirection.down:
        path
          ..moveTo(0, 0)
          ..lineTo(w / 2, h)
          ..lineTo(w, 0);
      case _CaretDirection.left:
        path
          ..moveTo(w, 0)
          ..lineTo(0, h / 2)
          ..lineTo(w, h);
      case _CaretDirection.right:
        path
          ..moveTo(0, 0)
          ..lineTo(w, h / 2)
          ..lineTo(0, h);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.direction != direction;
}
