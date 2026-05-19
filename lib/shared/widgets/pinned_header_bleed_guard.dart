import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// How far above its own box the guard overdraws, in logical pixels. One
/// logical pixel is at least one device pixel at every ratio we ship on, so it
/// always reaches past a boundary that fell mid-pixel.
const double _kOverdraw = 1;

/// How far the guard reaches back DOWN under the header. It has to overlap,
/// not merely abut: antialiased coverages multiply rather than partition, so a
/// guard that stopped exactly at the header's top edge would cover a quarter
/// of the offending pixel while the header covered three quarters OF THE WHOLE
/// PIXEL — leaving the two overlapping and a fraction of the content still
/// showing. Reaching [_kOverdraw] past the edge makes the guard opaque across
/// the whole row, and the header then paints over it. The overlap is entirely
/// behind the header's own opaque box, so nothing of it is ever visible.
const double _kUnderlap = 1;

/// Wraps the box of a PINNED sliver header so that no fraction of a device
/// pixel of the content scrolling beneath it can show above its top edge.
///
/// A pinned header is positioned in LOGICAL pixels and nothing guarantees that
/// position lands on a device pixel boundary — one fractional height anywhere
/// above the scroll view offsets every descendant by a fraction of a pixel.
/// The viewport's clip is [Clip.hardEdge], so it snaps to whole device pixels,
/// while the header's own background is antialiased and does not: the topmost
/// device pixel row is then admitted by the clip and only partly covered by the
/// header. What shows through the remainder is the row scrolling underneath —
/// a dashed line of glyph tips riding above the header's top border.
///
/// The guard paints a strip of the page canvas across that boundary, outside
/// the header's own box. Where the header is pinned to the top of the viewport
/// the overdraw is clipped away and only ever fills the offending partial
/// pixel; anywhere else in the list the header is preceded by canvas anyway
/// (the gap between cards), so it paints canvas over canvas and is invisible.
class PinnedHeaderBleedGuard extends StatelessWidget {
  /// Creates a [PinnedHeaderBleedGuard] around [child], the header's own box.
  const PinnedHeaderBleedGuard({super.key, required this.child});

  /// The pinned header's box. It sizes the guard.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      // Passthrough, not the default loose: the header's box must see the same
      // constraints it saw before it was wrapped. A persistent header lays its
      // child out with a tight cross-axis width and a LOOSE main axis, and a
      // loose stack would hand the box `0..width` instead — collapsing it onto
      // its content and leaving the card's frame short of the viewport.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -_kOverdraw,
          left: 0,
          right: 0,
          height: _kOverdraw + _kUnderlap,
          child: ColoredBox(color: tokens.canvas),
        ),
        child,
      ],
    );
  }
}
