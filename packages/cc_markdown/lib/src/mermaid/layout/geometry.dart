/// Geometry helpers shared by the layout passes: node sizing per shape and
/// clipping an edge's endpoint to the outline it touches (so an arrow stops at
/// the box, not at its center).
library;

import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:cc_markdown/src/mermaid/model.dart';

/// Where the segment from [outside] toward the center of [rect] first meets the
/// [shape]'s outline.
///
/// Rectangular families clip on the box, round families on the inscribed
/// ellipse and rhombus families on the diamond — so an arrow into a decision
/// node lands on the facet, not in the corner gap.
Offset clipToShape(Rect rect, CcMermaidNodeShape shape, Offset outside) {
  final center = rect.center;
  final dx = outside.dx - center.dx;
  final dy = outside.dy - center.dy;
  if (dx == 0 && dy == 0) {
    return center;
  }
  return switch (shape) {
    CcMermaidNodeShape.circle ||
    CcMermaidNodeShape.doubleCircle ||
    CcMermaidNodeShape.startPoint ||
    CcMermaidNodeShape.endPoint => _clipEllipse(rect, dx, dy),
    CcMermaidNodeShape.diamond ||
    CcMermaidNodeShape.choice => _clipDiamond(rect, dx, dy),
    _ => _clipRect(rect, dx, dy),
  };
}

Offset _clipRect(Rect rect, double dx, double dy) {
  final center = rect.center;
  final halfW = rect.width / 2;
  final halfH = rect.height / 2;
  // Scale the direction until it touches the nearer of the two box walls.
  final scaleX = dx == 0 ? double.infinity : halfW / dx.abs();
  final scaleY = dy == 0 ? double.infinity : halfH / dy.abs();
  final scale = math.min(scaleX, scaleY);
  return Offset(center.dx + dx * scale, center.dy + dy * scale);
}

Offset _clipEllipse(Rect rect, double dx, double dy) {
  final center = rect.center;
  final a = rect.width / 2;
  final b = rect.height / 2;
  if (a <= 0 || b <= 0) {
    return center;
  }
  final denominator = math.sqrt((dx * dx) / (a * a) + (dy * dy) / (b * b));
  if (denominator == 0) {
    return center;
  }
  return Offset(center.dx + dx / denominator, center.dy + dy / denominator);
}

Offset _clipDiamond(Rect rect, double dx, double dy) {
  final center = rect.center;
  final a = rect.width / 2;
  final b = rect.height / 2;
  if (a <= 0 || b <= 0) {
    return center;
  }
  // |x|/a + |y|/b = 1 along the ray.
  final denominator = dx.abs() / a + dy.abs() / b;
  if (denominator == 0) {
    return center;
  }
  return Offset(center.dx + dx / denominator, center.dy + dy / denominator);
}

/// Whether [shape] needs extra room because its outline cuts into the label box
/// (diamonds, circles, hexagons, trapezoids).
({double widthFactor, double heightFactor, double minWidth}) shapeInflation(
  CcMermaidNodeShape shape,
) {
  return switch (shape) {
    CcMermaidNodeShape.diamond => (
      widthFactor: 1.45,
      heightFactor: 1.7,
      minWidth: 56,
    ),
    CcMermaidNodeShape.hexagon => (
      widthFactor: 1.3,
      heightFactor: 1.1,
      minWidth: 56,
    ),
    CcMermaidNodeShape.circle => (
      widthFactor: 1.35,
      heightFactor: 1.55,
      minWidth: 48,
    ),
    CcMermaidNodeShape.doubleCircle => (
      widthFactor: 1.5,
      heightFactor: 1.7,
      minWidth: 56,
    ),
    CcMermaidNodeShape.trapezoid || CcMermaidNodeShape.trapezoidAlt => (
      widthFactor: 1.45,
      heightFactor: 1,
      minWidth: 64,
    ),
    CcMermaidNodeShape.parallelogram || CcMermaidNodeShape.parallelogramAlt => (
      widthFactor: 1.3,
      heightFactor: 1,
      minWidth: 64,
    ),
    CcMermaidNodeShape.cylinder => (
      widthFactor: 1.05,
      heightFactor: 1.35,
      minWidth: 56,
    ),
    CcMermaidNodeShape.subroutine => (
      widthFactor: 1.15,
      heightFactor: 1,
      minWidth: 56,
    ),
    CcMermaidNodeShape.asymmetric => (
      widthFactor: 1.2,
      heightFactor: 1,
      minWidth: 56,
    ),
    CcMermaidNodeShape.stadium => (
      widthFactor: 1.12,
      heightFactor: 1,
      minWidth: 56,
    ),
    _ => (widthFactor: 1, heightFactor: 1, minWidth: 40),
  };
}

/// The bounding box of [points], or [Rect.zero] when empty.
Rect boundsOf(Iterable<Offset> points) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  var any = false;
  for (final point in points) {
    any = true;
    minX = math.min(minX, point.dx);
    minY = math.min(minY, point.dy);
    maxX = math.max(maxX, point.dx);
    maxY = math.max(maxY, point.dy);
  }
  if (!any) {
    return Rect.zero;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Drops points that repeat the previous one (a zero-length segment has no
/// direction, so an arrowhead built from it would point nowhere).
List<Offset> dedupePoints(List<Offset> points) {
  final out = <Offset>[];
  for (final point in points) {
    if (out.isEmpty || (point - out.last).distance > 0.01) {
      out.add(point);
    }
  }
  if (out.length == 1 && points.length > 1) {
    out.add(points.last);
  }
  return out;
}

/// A [Size] with its axes swapped — the trick that lets one top-down layout
/// serve `LR`/`RL` graphs (swap in, swap the coordinates back out).
Size swapAxes(Size size) => Size(size.height, size.width);
