import 'dart:math' show max, min;

import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_data.dart';
import 'package:flutter/widgets.dart';

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
  /// Creates a hull member from its live [position] and [size].
  const HullMember(this.position, this.size);

  /// Live canvas position of the card.
  final ValueNotifier<Offset> position;

  /// Layout size of the card.
  final Size size;
}

/// The live bounding box of one domain's cards.
class ClusterHull {
  /// Creates a hull around [members].
  const ClusterHull(this.members);

  /// Cards that belong to this cluster.
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
  /// Creates an edge between [src] and [dest].
  const GraphEdge({
    required this.src,
    required this.srcSize,
    required this.dest,
    required this.destSize,
    required this.role,
  });

  /// Live position of the source card.
  final ValueNotifier<Offset> src;

  /// Size of the source card, used to pick the anchor.
  final Size srcSize;

  /// Live position of the destination card.
  final ValueNotifier<Offset> dest;

  /// Size of the destination card, used to pick the anchor.
  final Size destSize;

  /// Visual role of this edge.
  final EdgeRole role;
}

/// Paints each cluster's hull and then every edge as a smooth curve between
/// node anchors. Repaints whenever any node position notifier fires (passed as
/// `repaint`), which is what keeps both live under a drag.
class EdgePainter extends CustomPainter {
  /// Creates an edge painter that redraws when [repaint] notifies.
  EdgePainter({
    required this.edges,
    required this.hulls,
    required Listenable repaint,
    required this.edgeColor,
    required this.factEdgeColor,
    required this.hullBorderColor,
    required this.hullFillColor,
  }) : super(repaint: repaint);

  /// Edges to paint.
  final List<GraphEdge> edges;

  /// Cluster hulls to paint behind the edges.
  final List<ClusterHull> hulls;

  /// Color for topic→fact edges.
  final Color edgeColor;

  /// Color for policy→fact edges.
  final Color factEdgeColor;

  /// Stroke color of each cluster hull.
  final Color hullBorderColor;

  /// Fill color of each cluster hull.
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
