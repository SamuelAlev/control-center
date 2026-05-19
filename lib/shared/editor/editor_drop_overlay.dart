import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:flutter/widgets.dart';

/// Fraction of the pane (per edge) within which a drop splits rather than moves.
const double _edgeBand = 0.25;

/// Resolves where a tab dropped at [local] within a pane of [size] should land.
///
/// The pane is divided into four edge bands ([_edgeBand] deep) and a center. A
/// drop nearest an edge (and within its band) splits toward that edge; anywhere
/// else (including the middle and corners outside every band) is a move into
/// the pane ([DropEdge.center]). Corners resolve to whichever edge is closest.
DropEdge computeDropEdge(Offset local, Size size) {
  if (size.width <= 0 || size.height <= 0) {
    return DropEdge.center;
  }
  final fx = (local.dx / size.width).clamp(0.0, 1.0);
  final fy = (local.dy / size.height).clamp(0.0, 1.0);
  final dLeft = fx;
  final dRight = 1 - fx;
  final dTop = fy;
  final dBottom = 1 - fy;
  final nearest = [dLeft, dRight, dTop, dBottom].reduce(math.min);
  if (nearest > _edgeBand) {
    return DropEdge.center;
  }
  if (nearest == dLeft) {
    return DropEdge.left;
  }
  if (nearest == dRight) {
    return DropEdge.right;
  }
  if (nearest == dTop) {
    return DropEdge.top;
  }
  return DropEdge.bottom;
}

/// A translucent preview of the region a dragged tab will occupy on drop.
///
/// Shows the half (or full pane, for a center move) that the resolved [edge]
/// targets, fading/sliding between states. Renders nothing when [edge] is null.
/// Always non-interactive — it sits above the pane body purely as feedback.
class EditorDropOverlay extends StatelessWidget {
  /// Creates an [EditorDropOverlay].
  const EditorDropOverlay({super.key, required this.edge});

  /// The resolved drop target, or null when no drag is hovering this pane.
  final DropEdge? edge;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final duration = CcMotion.resolve(context, CcMotion.fast);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final rect = _regionFor(edge, w, h);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: CcMotion.standard,
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: CcMotion.standard,
                  opacity: edge == null ? 0 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.accentSoft,
                      border: Border.all(color: t.accent, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Rect _regionFor(DropEdge? edge, double w, double h) {
    switch (edge) {
      case null:
      case DropEdge.center:
        return Rect.fromLTWH(0, 0, w, h);
      case DropEdge.left:
        return Rect.fromLTWH(0, 0, w / 2, h);
      case DropEdge.right:
        return Rect.fromLTWH(w / 2, 0, w / 2, h);
      case DropEdge.top:
        return Rect.fromLTWH(0, 0, w, h / 2);
      case DropEdge.bottom:
        return Rect.fromLTWH(0, h / 2, w, h / 2);
    }
  }
}
