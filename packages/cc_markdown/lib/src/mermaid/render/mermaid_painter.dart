/// The scene painter: draws a laid-out [CcMermaidScene] onto a canvas.
///
/// It owns exactly two responsibilities — tracing each shape's outline and
/// resolving each primitive's ROLE to a color from the stylesheet. No geometry
/// decisions happen here (that is layout's job), which is what keeps a theme
/// flip a repaint instead of a relayout.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/render/text_ruler.dart';
import 'package:flutter/widgets.dart';

/// Paints a [CcMermaidScene], scaled by [scale] about the origin.
class CcMermaidScenePainter extends CustomPainter {
  /// Creates a [CcMermaidScenePainter].
  CcMermaidScenePainter({
    required this.scene,
    required this.style,
    required this.ruler,
    this.scale = 1,
  });

  /// The laid-out diagram.
  final CcMermaidScene scene;

  /// The stylesheet colors and metrics come from.
  final CcMermaidStyle style;

  /// The ruler that measured the scene (reused so glyphs match the layout).
  final CcMermaidTextPainterRuler ruler;

  /// Uniform scale applied to the whole scene.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (scale != 1) {
      canvas.scale(scale);
    }
    final background = style.background;
    if (background != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, scene.size.width, scene.size.height),
        Paint()..color = background,
      );
    }
    for (final primitive in scene.primitives) {
      switch (primitive) {
        case final CcMermaidShapePrim shape:
          _paintShape(canvas, shape);
        case final CcMermaidTextPrim text:
          _paintText(canvas, text);
        case final CcMermaidPathPrim path:
          _paintPath(canvas, path);
        case final CcMermaidArcPrim arc:
          _paintArc(canvas, arc);
        case final CcMermaidActorPrim actor:
          _paintActor(canvas, actor);
      }
    }
    canvas.restore();
  }

  // ── colors ────────────────────────────────────────────────────────────────

  Color _fillColor(CcMermaidShapePrim shape) => switch (shape.role) {
    CcMermaidPaintRole.node => style.nodeFill,
    CcMermaidPaintRole.accent => style.accent,
    CcMermaidPaintRole.cluster => style.clusterFill,
    CcMermaidPaintRole.note => style.noteFill,
    CcMermaidPaintRole.edgeLabel => style.edgeLabelFill,
    CcMermaidPaintRole.activation => style.activationFill,
    CcMermaidPaintRole.frame => style.frameFill,
    CcMermaidPaintRole.series => style.seriesColor(shape.seriesIndex ?? 0),
    CcMermaidPaintRole.edge || CcMermaidPaintRole.divider => style.edgeColor,
  };

  Color _strokeColor(CcMermaidPaintRole role) => switch (role) {
    CcMermaidPaintRole.node => style.nodeBorder,
    CcMermaidPaintRole.accent => style.accent,
    CcMermaidPaintRole.cluster => style.clusterBorder,
    CcMermaidPaintRole.note => style.noteBorder,
    CcMermaidPaintRole.activation => style.accent,
    CcMermaidPaintRole.frame => style.frameBorder,
    CcMermaidPaintRole.divider => style.dividerColor,
    CcMermaidPaintRole.series => style.nodeBorder,
    CcMermaidPaintRole.edge || CcMermaidPaintRole.edgeLabel => style.edgeColor,
  };

  // ── shapes ────────────────────────────────────────────────────────────────

  void _paintShape(Canvas canvas, CcMermaidShapePrim shape) {
    if (shape.shape == CcMermaidNodeShape.endPoint) {
      _paintTerminal(canvas, shape.rect);
      return;
    }
    final path = shapeOutline(shape.rect, shape.shape, style.cornerRadius);
    if (shape.filled) {
      canvas.drawPath(path, Paint()..color = _fillColor(shape));
    }
    if (shape.stroked) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.strokeWidth ?? style.edgeStrokeWidth
        ..color = _strokeColor(shape.role);
      if (shape.dashed) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
    _paintShapeDetails(canvas, shape);
  }

  /// Inner strokes that make a shape READ as its kind: the subroutine's side
  /// walls, the cylinder's rim, the double circle's inner ring, the note's fold.
  void _paintShapeDetails(Canvas canvas, CcMermaidShapePrim shape) {
    final rect = shape.rect;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.edgeStrokeWidth
      ..color = _strokeColor(shape.role);
    switch (shape.shape) {
      case CcMermaidNodeShape.subroutine:
        canvas.drawLine(
          Offset(rect.left + 8, rect.top),
          Offset(rect.left + 8, rect.bottom),
          paint,
        );
        canvas.drawLine(
          Offset(rect.right - 8, rect.top),
          Offset(rect.right - 8, rect.bottom),
          paint,
        );
      case CcMermaidNodeShape.cylinder:
        final rimHeight = math.min(rect.height * 0.28, 14);
        canvas.drawArc(
          Rect.fromLTWH(rect.left, rect.top, rect.width, rimHeight * 2),
          0,
          math.pi,
          false,
          paint,
        );
      case CcMermaidNodeShape.doubleCircle:
        canvas.drawOval(rect.deflate(4), paint);
      case CcMermaidNodeShape.note:
        final fold = math.min(12.0, rect.width / 4);
        canvas.drawLine(
          Offset(rect.right - fold, rect.top),
          Offset(rect.right - fold, rect.top + fold),
          paint,
        );
        canvas.drawLine(
          Offset(rect.right - fold, rect.top + fold),
          Offset(rect.right, rect.top + fold),
          paint,
        );
      default:
        return;
    }
  }

  /// A state-diagram terminal: filled dot inside a ring.
  void _paintTerminal(Canvas canvas, Rect rect) {
    canvas.drawOval(
      rect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.edgeStrokeWidth
        ..color = style.accent,
    );
    canvas.drawOval(
      rect.deflate(rect.width / 4),
      Paint()..color = style.accent,
    );
  }

  // ── text ──────────────────────────────────────────────────────────────────

  void _paintText(Canvas canvas, CcMermaidTextPrim text) {
    final color = text.seriesIndex != null
        ? style.seriesColor(text.seriesIndex!)
        : (text.muted
              ? style.mutedTextColor
              : (ruler.styleFor(text.role).color ?? style.mutedTextColor));
    ruler.paint(
      canvas,
      text.text,
      text.role,
      text.rect,
      color: color,
      align: text.align,
    );
  }

  // ── paths ─────────────────────────────────────────────────────────────────

  void _paintPath(Canvas canvas, CcMermaidPathPrim prim) {
    if (prim.points.length < 2) {
      return;
    }
    final isThick = prim.stroke == CcMermaidEdgeStroke.thick;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = prim.role == CcMermaidPaintRole.divider
          ? style.edgeStrokeWidth * 0.8
          : (isThick ? style.thickStrokeWidth : style.edgeStrokeWidth)
      ..color = _strokeColor(prim.role);

    final path = roundedPolyline(prim.points, prim.cornerRadius);
    if (prim.stroke == CcMermaidEdgeStroke.dotted) {
      _drawDashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    _paintMarker(
      canvas,
      prim.startMarker,
      at: prim.points.first,
      toward: prim.points[1],
      paint: paint,
    );
    _paintMarker(
      canvas,
      prim.endMarker,
      at: prim.points.last,
      toward: prim.points[prim.points.length - 2],
      paint: paint,
    );
  }

  /// Draws one end decoration. [toward] is the neighboring point, so the marker
  /// aligns with the line's actual direction at that end.
  void _paintMarker(
    Canvas canvas,
    CcMermaidEdgeMarker marker, {
    required Offset at,
    required Offset toward,
    required Paint paint,
  }) {
    if (marker == CcMermaidEdgeMarker.none) {
      return;
    }
    final direction = at - toward;
    final length = direction.distance;
    if (length == 0) {
      return;
    }
    // Unit vector pointing INTO the endpoint, plus its normal.
    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = paint.color;
    final fill = Paint()..color = paint.color;
    final hollow = Paint()..color = style.nodeFill;

    Offset back(double distance) => at - unit * distance;

    switch (marker) {
      case CcMermaidEdgeMarker.none:
        return;
      case CcMermaidEdgeMarker.arrow:
        final base = back(style.arrowLength);
        canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..lineTo(
              base.dx + normal.dx * style.arrowWidth / 2,
              base.dy + normal.dy * style.arrowWidth / 2,
            )
            ..lineTo(
              base.dx - normal.dx * style.arrowWidth / 2,
              base.dy - normal.dy * style.arrowWidth / 2,
            )
            ..close(),
          fill,
        );
      case CcMermaidEdgeMarker.openArrow:
        final base = back(style.arrowLength);
        canvas.drawLine(at, base + normal * (style.arrowWidth / 2), stroke);
        canvas.drawLine(at, base - normal * (style.arrowWidth / 2), stroke);
      case CcMermaidEdgeMarker.cross:
        final base = back(style.arrowLength);
        final half = style.arrowWidth / 2;
        canvas.drawLine(base + normal * half, at - normal * half, stroke);
        canvas.drawLine(base - normal * half, at + normal * half, stroke);
      case CcMermaidEdgeMarker.circle:
        final center = back(style.arrowWidth / 2);
        canvas.drawCircle(center, style.arrowWidth / 2, hollow);
        canvas.drawCircle(center, style.arrowWidth / 2, stroke);
      case CcMermaidEdgeMarker.triangleHollow:
        final base = back(style.arrowLength + 2);
        final path = Path()
          ..moveTo(at.dx, at.dy)
          ..lineTo(
            base.dx + normal.dx * (style.arrowWidth / 2 + 1),
            base.dy + normal.dy * (style.arrowWidth / 2 + 1),
          )
          ..lineTo(
            base.dx - normal.dx * (style.arrowWidth / 2 + 1),
            base.dy - normal.dy * (style.arrowWidth / 2 + 1),
          )
          ..close();
        canvas.drawPath(path, hollow);
        canvas.drawPath(path, stroke);
      case CcMermaidEdgeMarker.diamondFilled:
      case CcMermaidEdgeMarker.diamondHollow:
        final tipToBase = style.arrowLength + 6;
        final middle = back(tipToBase / 2);
        final base = back(tipToBase);
        final half = style.arrowWidth / 2;
        final path = Path()
          ..moveTo(at.dx, at.dy)
          ..lineTo(middle.dx + normal.dx * half, middle.dy + normal.dy * half)
          ..lineTo(base.dx, base.dy)
          ..lineTo(middle.dx - normal.dx * half, middle.dy - normal.dy * half)
          ..close();
        canvas.drawPath(
          path,
          marker == CcMermaidEdgeMarker.diamondFilled ? fill : hollow,
        );
        canvas.drawPath(path, stroke);
      case CcMermaidEdgeMarker.erOne:
        _paintErTick(canvas, at, unit, normal, stroke, distance: 7);
        _paintErTick(canvas, at, unit, normal, stroke, distance: 13);
      case CcMermaidEdgeMarker.erZeroOrOne:
        _paintErTick(canvas, at, unit, normal, stroke, distance: 14);
        final center = back(7);
        canvas.drawCircle(center, 4.5, hollow);
        canvas.drawCircle(center, 4.5, stroke);
      case CcMermaidEdgeMarker.erOneOrMany:
        _paintErCrowFoot(canvas, at, unit, normal, stroke, offset: 0);
        _paintErTick(canvas, at, unit, normal, stroke, distance: 14);
      case CcMermaidEdgeMarker.erZeroOrMany:
        _paintErCrowFoot(canvas, at, unit, normal, stroke, offset: 0);
        final center = back(16);
        canvas.drawCircle(center, 4.5, hollow);
        canvas.drawCircle(center, 4.5, stroke);
    }
  }

  /// A crow's-foot cardinality tick: a bar across the line.
  void _paintErTick(
    Canvas canvas,
    Offset at,
    Offset unit,
    Offset normal,
    Paint stroke, {
    required double distance,
  }) {
    final point = at - unit * distance;
    canvas.drawLine(point + normal * 5, point - normal * 5, stroke);
  }

  /// The three-line "many" fan.
  void _paintErCrowFoot(
    Canvas canvas,
    Offset at,
    Offset unit,
    Offset normal,
    Paint stroke, {
    required double offset,
  }) {
    final tip = at - unit * offset;
    final base = tip - unit * 11;
    canvas.drawLine(tip, base + normal * 6, stroke);
    canvas.drawLine(tip, base - normal * 6, stroke);
    canvas.drawLine(tip, base, stroke);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    final on = style.dashPattern.isEmpty ? 5.0 : style.dashPattern.first;
    final off = style.dashPattern.length > 1 ? style.dashPattern[1] : on;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + on, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + off;
      }
    }
  }

  // ── charts ────────────────────────────────────────────────────────────────

  void _paintArc(Canvas canvas, CcMermaidArcPrim arc) {
    canvas.drawArc(
      arc.rect,
      arc.startAngle,
      arc.sweepAngle,
      true,
      Paint()..color = style.seriesColor(arc.seriesIndex),
    );
    // A hairline separator keeps adjacent slices readable when two palette
    // colors sit close in luminance.
    canvas.drawArc(
      arc.rect,
      arc.startAngle,
      arc.sweepAngle,
      true,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = style.background ?? style.nodeFill,
    );
  }

  void _paintActor(Canvas canvas, CcMermaidActorPrim actor) {
    final rect = actor.rect;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.edgeStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = style.accent;
    final headRadius = rect.width * 0.3;
    final headCenter = Offset(rect.center.dx, rect.top + headRadius);
    canvas.drawCircle(headCenter, headRadius, paint);
    final shoulders = headCenter.dy + headRadius + 2;
    canvas.drawLine(
      Offset(rect.center.dx, shoulders),
      Offset(rect.center.dx, rect.bottom - 6),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, shoulders + 3),
      Offset(rect.right, shoulders + 3),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.bottom - 6),
      Offset(rect.left + 2, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.bottom - 6),
      Offset(rect.right - 2, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(CcMermaidScenePainter old) =>
      old.scene != scene || old.style != style || old.scale != scale;
}

/// Traces the outline of [shape] inside [rect].
///
/// Exposed for tests: a shape is a geometric claim ("a diamond has four
/// vertices on the box's edge midpoints") that is worth asserting directly.
Path shapeOutline(Rect rect, CcMermaidNodeShape shape, double cornerRadius) {
  switch (shape) {
    case CcMermaidNodeShape.roundRect:
    case CcMermaidNodeShape.note:
      return Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      );
    case CcMermaidNodeShape.stadium:
      return Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      );
    case CcMermaidNodeShape.circle:
    case CcMermaidNodeShape.doubleCircle:
    case CcMermaidNodeShape.startPoint:
    case CcMermaidNodeShape.endPoint:
      return Path()..addOval(rect);
    case CcMermaidNodeShape.diamond:
    case CcMermaidNodeShape.choice:
      return Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
    case CcMermaidNodeShape.hexagon:
      final inset = math.min(rect.width * 0.16, 18.0);
      return Path()
        ..moveTo(rect.left + inset, rect.top)
        ..lineTo(rect.right - inset, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.right - inset, rect.bottom)
        ..lineTo(rect.left + inset, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
    case CcMermaidNodeShape.parallelogram:
      final skew = math.min(rect.width * 0.18, 20.0);
      return Path()
        ..moveTo(rect.left + skew, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - skew, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
    case CcMermaidNodeShape.parallelogramAlt:
      final skew = math.min(rect.width * 0.18, 20.0);
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right - skew, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left + skew, rect.bottom)
        ..close();
    case CcMermaidNodeShape.trapezoid:
      final skew = math.min(rect.width * 0.18, 22.0);
      return Path()
        ..moveTo(rect.left + skew, rect.top)
        ..lineTo(rect.right - skew, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
    case CcMermaidNodeShape.trapezoidAlt:
      final skew = math.min(rect.width * 0.18, 22.0);
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - skew, rect.bottom)
        ..lineTo(rect.left + skew, rect.bottom)
        ..close();
    case CcMermaidNodeShape.asymmetric:
      final notch = math.min(rect.width * 0.16, 16.0);
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + notch, rect.center.dy)
        ..close();
    case CcMermaidNodeShape.cylinder:
      final rim = math.min(rect.height * 0.18, 10.0);
      return Path()
        ..moveTo(rect.left, rect.top + rim)
        ..arcToPoint(
          Offset(rect.right, rect.top + rim),
          radius: Radius.elliptical(rect.width / 2, rim),
          clockwise: true,
        )
        ..lineTo(rect.right, rect.bottom - rim)
        ..arcToPoint(
          Offset(rect.left, rect.bottom - rim),
          radius: Radius.elliptical(rect.width / 2, rim),
          clockwise: true,
        )
        ..close();
    // The rect family stays SQUARE on purpose: `[text]` vs `(text)` is a
    // meaning distinction in mermaid and the design system's zero-radius rule
    // means a rectangle here must read as a rectangle. Rounding belongs only to
    // the shapes whose roundness IS the semantics (round-rect, stadium, note).
    case CcMermaidNodeShape.bar:
    case CcMermaidNodeShape.rect:
    case CcMermaidNodeShape.subroutine:
    case CcMermaidNodeShape.compartments:
      return Path()..addRect(rect);
  }
}

/// Builds a polyline path through [points] with [radius]-rounded interior
/// corners, so an edge that bends around a box reads as one flowing line.
Path roundedPolyline(List<Offset> points, double radius) {
  final path = Path();
  if (points.isEmpty) {
    return path;
  }
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 2 || radius <= 0) {
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }
  for (var i = 1; i < points.length - 1; i++) {
    final previous = points[i - 1];
    final current = points[i];
    final next = points[i + 1];
    final inLength = (current - previous).distance;
    final outLength = (next - current).distance;
    if (inLength == 0 || outLength == 0) {
      continue;
    }
    final r = math.min(radius, math.min(inLength, outLength) / 2);
    final entry = current - (current - previous) / inLength * r;
    final exit = current + (next - current) / outLength * r;
    path.lineTo(entry.dx, entry.dy);
    path.quadraticBezierTo(current.dx, current.dy, exit.dx, exit.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  return path;
}

/// Rasterizes [scene] to a picture — used by hosts that want to hand a diagram
/// to an image pipeline (share sheet, export) rather than a widget tree.
ui.Picture recordMermaidScene({
  required CcMermaidScene scene,
  required CcMermaidStyle style,
  required CcMermaidTextPainterRuler ruler,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  CcMermaidScenePainter(
    scene: scene,
    style: style,
    ruler: ruler,
  ).paint(canvas, scene.size);
  return recorder.endRecording();
}
