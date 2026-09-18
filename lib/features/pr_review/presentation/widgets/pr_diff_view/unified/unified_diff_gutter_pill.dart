import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Visual and interactive extent of the gutter add-comment affordance.
const double kGutterAddPillSize = 20;

/// The circular "+" affordance painted in the gutter rail on row hover. Tapping
/// starts a single-line comment; dragging vertically selects a row range. The
/// cursor reads as an open hand (grab) on hover and a closed hand (grabbing)
/// while a range drag is in progress.
class GutterAddPill extends StatelessWidget {
  const GutterAddPill({
    super.key,
    required this.dragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final bool dragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    // a11y: fill with the accessible solid brand token (not `textPrimary`,
    // which flips to near-white in dark mode and rendered the white "+" glyph
    // invisible — 1.0:1). `bgBrandSolid` carries white in both themes (>=5:1)
    // and reads as an on-brand "add comment" affordance against either gutter.
    final primary = tokens.bgBrandSolid;
    return MouseRegion(
      cursor: dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onVerticalDragStart: (_) => onDragStart(),
        onVerticalDragUpdate: (d) => onDragUpdate(d.globalPosition.dy),
        onVerticalDragEnd: (_) => onDragEnd(),
        child: Container(
          width: kGutterAddPillSize,
          height: kGutterAddPillSize,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(6),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(AppIcons.plus, size: 14, color: tokens.textWhite),
        ),
      ),
    );
  }
}

/// Clips to a fixed rect expressed in the clipped widget's own coordinate
/// space — here the diff column's visible area in root-overlay (= screen)
/// coordinates, so overlay affordances cut at the same edges as the sliver's
/// text.
class FixedRectClipper extends CustomClipper<Rect> {
  const FixedRectClipper(this.rect);

  /// The visible area to clip to.
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(FixedRectClipper oldClipper) => oldClipper.rect != rect;
}
