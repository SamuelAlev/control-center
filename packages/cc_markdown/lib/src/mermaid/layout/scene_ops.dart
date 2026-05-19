/// Scene assembly helpers: bounds, translation and the final normalize step
/// every layout ends with.
///
/// Layouts emit primitives in whatever coordinate space is convenient (edge
/// loops and labels routinely stick out past the node grid, sometimes into
/// negative space). [finalizeScene] measures what was actually drawn, shifts it
/// so nothing is clipped and reports the canvas size — so no layout has to
/// predict its own extents.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:flutter/widgets.dart';

/// The bounding box a primitive paints into (stroke widths and arrowheads are
/// covered by the canvas padding, not measured here).
Rect primitiveBounds(CcMermaidPrimitive primitive) {
  return switch (primitive) {
    CcMermaidShapePrim(:final rect) => rect,
    CcMermaidTextPrim(:final rect) => rect,
    CcMermaidArcPrim(:final rect) => rect,
    CcMermaidActorPrim(:final rect) => rect,
    CcMermaidPathPrim(:final points) => _pointBounds(points),
  };
}

Rect _pointBounds(List<Offset> points) {
  if (points.isEmpty) {
    return Rect.zero;
  }
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final point in points) {
    minX = math.min(minX, point.dx);
    minY = math.min(minY, point.dy);
    maxX = math.max(maxX, point.dx);
    maxY = math.max(maxY, point.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// A copy of [primitive] moved by [offset].
CcMermaidPrimitive translatePrimitive(
  CcMermaidPrimitive primitive,
  Offset offset,
) {
  return switch (primitive) {
    CcMermaidShapePrim(
      :final rect,
      :final shape,
      :final role,
      :final dashed,
      :final filled,
      :final stroked,
      :final seriesIndex,
      :final strokeWidth,
    ) =>
      CcMermaidShapePrim(
        rect: rect.shift(offset),
        shape: shape,
        role: role,
        dashed: dashed,
        filled: filled,
        stroked: stroked,
        seriesIndex: seriesIndex,
        strokeWidth: strokeWidth,
      ),
    CcMermaidTextPrim(
      :final text,
      :final rect,
      :final role,
      :final align,
      :final muted,
      :final seriesIndex,
    ) =>
      CcMermaidTextPrim(
        text: text,
        rect: rect.shift(offset),
        role: role,
        align: align,
        muted: muted,
        seriesIndex: seriesIndex,
      ),
    CcMermaidPathPrim(
      :final points,
      :final stroke,
      :final role,
      :final startMarker,
      :final endMarker,
      :final cornerRadius,
    ) =>
      CcMermaidPathPrim(
        points: [for (final point in points) point + offset],
        stroke: stroke,
        role: role,
        startMarker: startMarker,
        endMarker: endMarker,
        cornerRadius: cornerRadius,
      ),
    CcMermaidArcPrim(
      :final rect,
      :final startAngle,
      :final sweepAngle,
      :final seriesIndex,
    ) =>
      CcMermaidArcPrim(
        rect: rect.shift(offset),
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        seriesIndex: seriesIndex,
      ),
    CcMermaidActorPrim(:final rect) => CcMermaidActorPrim(rect.shift(offset)),
  };
}

/// Normalizes [primitives] into a scene: shifts them so the drawn content
/// starts at [padding]'s top-left and reports the padded canvas size.
CcMermaidScene finalizeScene(
  List<CcMermaidPrimitive> primitives, {
  required EdgeInsets padding,
  List<CcMermaidHitTarget> hitTargets = const [],
}) {
  if (primitives.isEmpty) {
    return CcMermaidScene.empty;
  }
  var bounds = primitiveBounds(primitives.first);
  for (final primitive in primitives.skip(1)) {
    bounds = bounds.expandToInclude(primitiveBounds(primitive));
  }
  final shift = Offset(padding.left - bounds.left, padding.top - bounds.top);
  return CcMermaidScene(
    size: Size(
      bounds.width + padding.horizontal,
      bounds.height + padding.vertical,
    ),
    primitives: [
      for (final primitive in primitives) translatePrimitive(primitive, shift),
    ],
    hitTargets: [
      for (final target in hitTargets)
        CcMermaidHitTarget(
          rect: target.rect.shift(shift),
          nodeId: target.nodeId,
          href: target.href,
          tooltip: target.tooltip,
        ),
    ],
  );
}

/// Prepends a centered diagram title above [primitives], returning the new
/// list. A blank title, or an empty body, is a no-op.
List<CcMermaidPrimitive> prependSceneTitle(
  List<CcMermaidPrimitive> primitives,
  String? title,
  CcMermaidTextRuler ruler, {
  double gap = 12,
}) {
  if (title == null || title.trim().isEmpty || primitives.isEmpty) {
    return primitives;
  }
  var bounds = primitiveBounds(primitives.first);
  for (final primitive in primitives.skip(1)) {
    bounds = bounds.expandToInclude(primitiveBounds(primitive));
  }
  final size = ruler.measure(title, CcMermaidTextRole.title);
  return [
    CcMermaidTextPrim(
      text: title,
      rect: Rect.fromLTWH(
        bounds.left,
        bounds.top - size.height - gap,
        math.max(bounds.width, size.width),
        size.height,
      ),
      role: CcMermaidTextRole.title,
    ),
    ...primitives,
  ];
}

/// Lays out [lines] of text for [role], soft-wrapping any line wider than
/// [maxWidth] on word boundaries (mermaid itself expects `<br>`, but a single
/// runaway label would otherwise stretch the whole diagram).
List<String> wrapMermaidLines(
  List<String> lines,
  CcMermaidTextRole role,
  CcMermaidTextRuler ruler, {
  required double maxWidth,
}) {
  final out = <String>[];
  for (final line in lines) {
    if (ruler.measure(line, role).width <= maxWidth || !line.contains(' ')) {
      out.add(line);
      continue;
    }
    final words = line.split(RegExp(r'\s+'));
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (current.isNotEmpty &&
          ruler.measure(candidate, role).width > maxWidth) {
        out.add(current);
        current = word;
        continue;
      }
      current = candidate;
    }
    if (current.isNotEmpty) {
      out.add(current);
    }
  }
  return out;
}

/// The size a stack of [lines] occupies in [role], with [lineSpacing] leading.
Size measureMermaidLines(
  List<String> lines,
  CcMermaidTextRole role,
  CcMermaidTextRuler ruler, {
  required double lineSpacing,
}) {
  if (lines.isEmpty) {
    return Size.zero;
  }
  var width = 0.0;
  var height = 0.0;
  for (var i = 0; i < lines.length; i++) {
    final size = ruler.measure(lines[i], role);
    width = math.max(width, size.width);
    height += size.height;
    if (i > 0) {
      height += lineSpacing;
    }
  }
  return Size(width, height);
}

/// Emits one text primitive per line, stacked and centered inside [box].
List<CcMermaidPrimitive> stackTextLines(
  List<String> lines,
  CcMermaidTextRole role,
  CcMermaidTextRuler ruler, {
  required Rect box,
  required double lineSpacing,
  CcMermaidTextAlign align = CcMermaidTextAlign.center,
  bool muted = false,
}) {
  if (lines.isEmpty) {
    return const [];
  }
  final total = measureMermaidLines(
    lines,
    role,
    ruler,
    lineSpacing: lineSpacing,
  );
  var y = box.center.dy - total.height / 2;
  final out = <CcMermaidPrimitive>[];
  for (final line in lines) {
    final size = ruler.measure(line, role);
    out.add(
      CcMermaidTextPrim(
        text: line,
        rect: Rect.fromLTWH(box.left, y, box.width, size.height),
        role: role,
        align: align,
        muted: muted,
      ),
    );
    y += size.height + lineSpacing;
  }
  return out;
}
