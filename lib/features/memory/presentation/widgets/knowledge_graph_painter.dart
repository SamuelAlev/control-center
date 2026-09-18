import 'dart:math' show max, min;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_data.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

/// A single node placed on the canvas. Backed by a [ValueNotifier<Offset>] so
/// dragging it rebuilds only this widget (and repaints the edge layer) rather
/// than the whole graph.
class GraphNode extends StatelessWidget {
  const GraphNode({
    required this.position,
    required this.size,
    required this.onMoved,
    required this.child,
    super.key,
  });

  final ValueNotifier<Offset> position;
  final Size size;

  /// Called on every drag update so the host can stop re-flowing this node.
  final VoidCallback onMoved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, pos, child) {
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: size.width,
          height: size.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A trackpad two-finger scroll is a request to move the VIEW, not
            // this card. A pan recogniser accepts pan-zoom events as readily as
            // pointer drags and, being the inner one, wins the arena — so a
            // scroll that happened to start over a node dragged the node
            // instead of panning, amplified by 1/scale (four screen pixels per
            // finger pixel at the zoom floor). Excluding the trackpad kind
            // leaves the gesture to the viewer; a click-drag on a laptop
            // trackpad arrives as a mouse pointer, so dragging still works.
            supportedDevices: const {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.unknown,
            },
            // `delta` arrives in this widget's local (content) coordinates,
            // already corrected for the viewer's zoom, so it applies directly.
            onPanUpdate: (details) {
              position.value += details.delta;
              onMoved();
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The visual role of an edge, which determines its color, thickness and the
/// node anchors it connects.
enum EdgeRole {
  /// A topic down to one of the facts stacked under it.
  topicFact,

  /// A policy back to a fact it was derived from.
  policyFact,
}

/// One node inside a cluster hull, held by its live position notifier.
class HullMember {
  const HullMember(this.position, this.size);

  final ValueNotifier<Offset> position;
  final Size size;
}

/// The live bounding box of one domain's cards.
class ClusterHull {
  const ClusterHull(this.members);

  final List<HullMember> members;

  /// The box enclosing every member at its CURRENT position, so dragging a
  /// card carries its hull along instead of leaving it behind.
  Rect bounds() {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;
    for (final member in members) {
      final at = member.position.value;
      left = min(left, at.dx);
      top = min(top, at.dy);
      right = max(right, at.dx + member.size.width);
      bottom = max(bottom, at.dy + member.size.height);
    }
    return Rect.fromLTRB(left, top, right, bottom).inflate(hullPadding);
  }
}

/// An edge between two nodes. Holds references to the endpoints' live position
/// notifiers so the painter always reads their current positions.
class GraphEdge {
  const GraphEdge({
    required this.src,
    required this.srcSize,
    required this.dest,
    required this.destSize,
    required this.role,
  });

  final ValueNotifier<Offset> src;
  final Size srcSize;
  final ValueNotifier<Offset> dest;
  final Size destSize;
  final EdgeRole role;
}

/// Paints each cluster's hull and then every edge as a smooth curve between
/// node anchors. Repaints whenever any node position notifier fires (passed as
/// `repaint`), which is what keeps both live under a drag.
class EdgePainter extends CustomPainter {
  EdgePainter({
    required this.edges,
    required this.hulls,
    required Listenable repaint,
    required this.edgeColor,
    required this.factEdgeColor,
    required this.hullBorderColor,
    required this.hullFillColor,
  }) : super(repaint: repaint);

  final List<GraphEdge> edges;
  final List<ClusterHull> hulls;
  final Color edgeColor;
  final Color factEdgeColor;
  final Color hullBorderColor;
  final Color hullFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hullFill = Paint()..color = hullFillColor;
    final hullStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = hullBorderColor
      ..isAntiAlias = true;
    for (final hull in hulls) {
      final bounds = hull.bounds();
      if (bounds.isEmpty) {
        continue;
      }
      canvas.drawRect(bounds, hullFill);
      canvas.drawRect(bounds, hullStroke);
    }

    for (final edge in edges) {
      final style = _styleFor(edge.role);
      final srcPos = edge.src.value;
      final destPos = edge.dest.value;

      final from = Offset(
        srcPos.dx + edge.srcSize.width * ((style.start.x + 1) / 2),
        srcPos.dy + edge.srcSize.height * ((style.start.y + 1) / 2),
      );
      final to = Offset(
        destPos.dx + edge.destSize.width * ((style.end.x + 1) / 2),
        destPos.dy + edge.destSize.height * ((style.end.y + 1) / 2),
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.thickness
        ..color = style.color
        ..isAntiAlias = true;

      canvas.drawPath(_curvePath(from, to, style.start, style.end), paint);
    }
  }

  ({Color color, double thickness, Alignment start, Alignment end}) _styleFor(
    EdgeRole role,
  ) {
    switch (role) {
      case EdgeRole.topicFact:
        return (
          color: edgeColor,
          thickness: 1.2,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case EdgeRole.policyFact:
        return (
          color: factEdgeColor,
          thickness: 1.2,
          start: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
    }
  }

  /// Smooth curve between [from] and [to], easing out along the anchor
  /// directions. Mirrors the curve geometry of the previous flow-chart edges.
  Path _curvePath(Offset from, Offset to, Alignment start, Alignment end) {
    final distance = (to - from).distance / 3;

    var dx = 0.0;
    var dy = 0.0;
    if (start.x > 0) {
      dx = distance;
    } else if (start.x < 0) {
      dx = -distance;
    }
    if (start.y > 0) {
      dy = distance;
    } else if (start.y < 0) {
      dy = -distance;
    }
    final p1 = Offset(from.dx + dx, from.dy + dy);

    dx = 0;
    dy = 0;
    if (end.x > 0) {
      dx = distance;
    } else if (end.x < 0) {
      dx = -distance;
    }
    if (end.y > 0) {
      dy = distance;
    } else if (end.y < 0) {
      dy = -distance;
    }
    final p3 = end == Alignment.center ? to : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(p1.dx + (p3.dx - p1.dx) / 2, p1.dy + (p3.dy - p1.dy) / 2);

    return Path()
      ..moveTo(from.dx, from.dy)
      ..conicTo(p1.dx, p1.dy, p2.dx, p2.dy, 1)
      ..conicTo(p3.dx, p3.dy, to.dx, to.dy, 1);
  }

  @override
  bool shouldRepaint(EdgePainter old) =>
      !identical(old.edges, edges) ||
      !identical(old.hulls, hulls) ||
      old.edgeColor != edgeColor ||
      old.factEdgeColor != factEdgeColor ||
      old.hullBorderColor != hullBorderColor ||
      old.hullFillColor != hullFillColor;
}

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: CcTypography.caption.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
