/// The scene painter: draws a laid-out [CcMermaidScene] onto a canvas.
///
/// It owns exactly two responsibilities — tracing each shape's outline and
/// resolving each primitive's ROLE to a color from the stylesheet. No geometry
/// decisions happen here (that is layout's job), which is what keeps a theme
/// flip a repaint instead of a relayout.
///
/// Tracing is not free, and paint runs far more often than layout: a rebuild, a
/// zoom, a scroll or a recolor repaints the SAME scene. So the tracing itself is
/// retained per scene, in scene space, by [_RetainedSceneGeometry] — a path or a
/// dash decomposition is built once and stroked by every paint that follows.
/// Colors are never retained: they are resolved from the current stylesheet on
/// every paint, which is what makes a recolor correct rather than merely cheap.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/render/text_ruler.dart';
import 'package:flutter/widgets.dart';

/// Paints a [CcMermaidScene], scaled by [scale] about the origin.
///
/// The scale is applied to the CANVAS rather than baked into the geometry: what
/// is retained is a `Path`, in scene units, and the canvas transform multiplies
/// it at stroke time. Zooming therefore re-rasterizes vectors — it never
/// magnifies a flattened copy of the diagram.
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
    final primitives = scene.primitives;
    if (primitives.isNotEmpty) {
      // Retained per scene, fetched once per paint: every primitive below reads
      // its path from here instead of tracing a new one.
      final geometry = _geometryFor(scene);
      for (var i = 0; i < primitives.length; i++) {
        switch (primitives[i]) {
          case final CcMermaidShapePrim shape:
            _paintShape(canvas, geometry, i, shape);
          case final CcMermaidTextPrim text:
            _paintText(canvas, text);
          case final CcMermaidPathPrim path:
            _paintPath(canvas, geometry, i, path);
          case final CcMermaidArcPrim arc:
            _paintArc(canvas, arc);
          case final CcMermaidActorPrim actor:
            _paintActor(canvas, actor);
        }
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

  void _paintShape(
    Canvas canvas,
    _RetainedSceneGeometry geometry,
    int index,
    CcMermaidShapePrim shape,
  ) {
    if (shape.shape == CcMermaidNodeShape.endPoint) {
      _paintTerminal(canvas, shape.rect);
      return;
    }
    // Traced once per radius: the outline is a function of the shape's box and
    // [style.cornerRadius], both of which are the scene's own — a recolor, a
    // rescale and a rebuilt widget all find the path already here.
    final path = geometry.outlineAt(
      index,
      shape.rect,
      shape.shape,
      style.cornerRadius,
    );
    if (shape.filled) {
      canvas.drawPath(path, Paint()..color = _fillColor(shape));
    }
    if (shape.stroked) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.strokeWidth ?? style.edgeStrokeWidth
        ..color = _strokeColor(shape.role);
      if (shape.dashed) {
        _drawDashed(
          canvas,
          geometry.dashesAt(index, path, _dashOn, _dashOff),
          paint,
        );
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

  void _paintPath(
    Canvas canvas,
    _RetainedSceneGeometry geometry,
    int index,
    CcMermaidPathPrim prim,
  ) {
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

    // Rounded once: the polyline is a function of the scene's own points and
    // corner radius, so an edge keeps its path across every later paint.
    final path = geometry.polylineAt(index, prim.points, prim.cornerRadius);
    if (prim.stroke == CcMermaidEdgeStroke.dotted) {
      _drawDashed(
        canvas,
        geometry.dashesAt(index, path, _dashOn, _dashOff),
        paint,
      );
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

  /// Dash on/off lengths, resolved from the stylesheet in ONE place.
  ///
  /// Both are part of a decomposition's identity: a style whose pattern changed
  /// gets fresh segments for the new pattern instead of the ones cut for the
  /// old one, which is what keeps a dash-pattern change visible immediately.
  double get _dashOn =>
      style.dashPattern.isEmpty ? 5.0 : style.dashPattern.first;

  double get _dashOff =>
      style.dashPattern.length > 1 ? style.dashPattern[1] : _dashOn;

  /// Strokes dash segments the geometry cache already cut.
  ///
  /// The decomposition — walking a path's metrics and extracting every on-run —
  /// is the expensive half and it is retained per path, so this is a plain loop
  /// of draws over segment paths that were built once.
  void _drawDashed(Canvas canvas, List<Path> segments, Paint paint) {
    for (final segment in segments) {
      canvas.drawPath(segment, paint);
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

// ── retained paint geometry ─────────────────────────────────────────────────

/// How many scenes keep their paint geometry. A screenful plus scrollback, in
/// line with the scene memo: an entry here holds paths, not rendered pictures,
/// so it is small — but a session's worth of diagrams still has no business
/// being retained.
const int _paintGeometryCapacity = 8;

/// Paint geometry retained per scene, in least-recently-painted order.
///
/// Keyed by scene IDENTITY: [CcMermaidScene] has no value equality, so an entry
/// describes its scene exactly as long as layout keeps handing back that same
/// instance — which is precisely the window in which the geometry is unchanged.
/// Layout is what decides that window (it re-lays out for anything that moves a
/// primitive or changes what text measures), so this cache never has to guess.
///
/// Bounded, so diagrams scrolled away are dropped rather than accumulated.
/// Nothing here is a raster: a retained path is stroked by the canvas at stroke
/// time, at whatever scale that canvas carries.
final Map<CcMermaidScene, _RetainedSceneGeometry> _paintGeometry =
    <CcMermaidScene, _RetainedSceneGeometry>{};

/// The geometry for [scene], building an entry on first paint.
_RetainedSceneGeometry _geometryFor(CcMermaidScene scene) {
  final cached = _paintGeometry.remove(scene);
  if (cached != null) {
    _paintGeometry[scene] = cached; // Most recently painted.
    return cached;
  }
  final geometry = _RetainedSceneGeometry(scene.primitives.length);
  _paintGeometry[scene] = geometry;
  while (_paintGeometry.length > _paintGeometryCapacity) {
    // `Map` preserves insertion order, so the first key is the oldest paint.
    _paintGeometry.remove(_paintGeometry.keys.first);
  }
  return geometry;
}

/// How many path geometries — shape outlines and rounded polylines — the
/// painter has traced for [scene] since it was last laid out.
///
/// Exposed for tests. Reuse is INVISIBLE in rendered output by design (a reused
/// path strokes the same pixels as a fresh one), so the honest assertion that a
/// second paint, a rebuilt painter or a zoom skips the tracing is that this
/// number stops moving. Zero for a scene that has not been painted, or that has
/// aged out of the cache.
@visibleForTesting
int mermaidPaintPathBuilds(CcMermaidScene scene) =>
    _paintGeometry[scene]?.pathBuilds ?? 0;

/// How many dash decompositions the painter has run for [scene].
///
/// The expensive half of a dotted edge is walking its metrics and extracting
/// every on-run; this reports how many times that has actually been done.
@visibleForTesting
int mermaidPaintDashBuilds(CcMermaidScene scene) =>
    _paintGeometry[scene]?.dashBuilds ?? 0;

/// Drops every retained paint geometry.
///
/// Entries are keyed by scene identity and bounded, so this exists for tests
/// that want each case to start cold — and for a host that knows the scene
/// objects it hands the painter are about to be replaced wholesale and wants the
/// memory back now rather than on the next eviction.
@visibleForTesting
void clearMermaidPaintGeometryCache() => _paintGeometry.clear();

/// Scene-space paint geometry for one [CcMermaidScene], built on first use.
///
/// Entries are index-aligned with [CcMermaidScene.primitives] and are only ever
/// read for the scene they were built from, so an entry never has to keep a
/// copy of the geometry it was cut from. The inputs that do NOT live in the
/// scene are the ones recorded here:
///
///  * `style.cornerRadius`, which the shape outlines are traced with — layout
///    already re-runs when it changes, and this keeps a reused scene honest if
///    it ever stops doing so;
///  * the dash pattern, which decorates a stroke rather than moving anything —
///    a paint-only change, so the same scene is reused and the decomposition
///    has to notice the new on/off lengths by itself.
///
/// Nothing else about the stylesheet is consulted: stroke widths and arrow
/// sizes are applied to a `Paint` at draw time and are never cached, so they
/// need no invalidation here.
class _RetainedSceneGeometry {
  _RetainedSceneGeometry(int count)
    : _outlines = List<Path?>.filled(count, null),
      _polylines = List<Path?>.filled(count, null),
      _dashes = List<_DashDecomposition?>.filled(count, null);

  final List<Path?> _outlines;
  final List<Path?> _polylines;
  final List<_DashDecomposition?> _dashes;

  /// The corner radius [_outlines] were traced with; NaN until the first one.
  double _outlineRadius = double.nan;

  int _pathBuilds = 0;
  int _dashBuilds = 0;

  /// How many shapes and polylines have been traced for the scene.
  int get pathBuilds => _pathBuilds;

  /// How many paths have been decomposed into dashes for the scene.
  int get dashBuilds => _dashBuilds;

  /// The outline of the shape at [index], traced once per corner radius.
  Path outlineAt(
    int index,
    Rect rect,
    CcMermaidNodeShape shape,
    double radius,
  ) {
    if (_outlineRadius != radius) {
      // Every shape with corners is a different outline at a different radius,
      // so the ones already traced describe a shape nobody asked for.
      _outlineRadius = radius;
      _outlines.fillRange(0, _outlines.length, null);
    }
    final cached = _outlines[index];
    if (cached != null) {
      return cached;
    }
    _pathBuilds++;
    return _outlines[index] = shapeOutline(rect, shape, radius);
  }

  /// The rounded polyline through [points] at [index], built once.
  Path polylineAt(int index, List<Offset> points, double radius) {
    final cached = _polylines[index];
    if (cached != null) {
      return cached;
    }
    _pathBuilds++;
    return _polylines[index] = roundedPolyline(points, radius);
  }

  /// The dash segments of [path] at [index], cut once per on/off pair.
  List<Path> dashesAt(int index, Path path, double on, double off) {
    final cached = _dashes[index];
    if (cached != null &&
        identical(cached.path, path) &&
        cached.on == on &&
        cached.off == off) {
      return cached.segments;
    }
    _dashBuilds++;
    final segments = _dashSegments(path, on, off);
    _dashes[index] = _DashDecomposition(
      path: path,
      on: on,
      off: off,
      segments: segments,
    );
    return segments;
  }
}

/// One path's dash segments, with the pattern that cut them.
class _DashDecomposition {
  const _DashDecomposition({
    required this.path,
    required this.on,
    required this.off,
    required this.segments,
  });

  final Path path;

  /// Dash length, in scene units.
  final double on;

  /// Gap length, in scene units.
  final double off;

  /// The drawable segments, in path order.
  final List<Path> segments;
}

/// Cuts [path] into dash segments of [on] followed by [off], per contour.
///
/// The segments are kept as separate paths, and stroked as separate paths, so a
/// dashed line paints exactly what it always has: same runs, same order, same
/// round caps where they overlap at a corner — caching changes how often this
/// walk happens, never what it produces.
List<Path> _dashSegments(Path path, double on, double off) {
  final segments = <Path>[];
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + on, metric.length);
      segments.add(metric.extractPath(distance, next));
      distance = next + off;
    }
  }
  return segments;
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
